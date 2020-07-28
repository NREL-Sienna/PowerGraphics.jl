order = CATEGORY_DEFAULT # TODO: move inside function

function _get_iterator(sys::PSY.System, results::IS.Results)
    iterators = []
    for (k, v) in IS.get_variables(results)
        if "$k"[1:2] == "P_"
            datatype = (split("$k", "P_")[2])
            if occursin("Thermal", datatype)
                iterators =
                    vcat(iterators, collect(PSY.get_components(PSY.ThermalGen, sys)))
            elseif occursin("Renewable", datatype)
                iterators =
                    vcat(iterators, collect(PSY.get_components(PSY.RenewableGen, sys)))
            elseif occursin("Hydro", datatype)
                iterators = vcat(iterators, collect(PSY.get_components(PSY.HydroGen, sys)))
            elseif occursin("Storage", datatype)
                iterators = vcat(iterators, collect(PSY.get_components(PSY.Storage, sys)))
            end
        end
    end
    iterators_sorted = Dict{Any, Any}()
    for iterator in iterators
        name = iterator.name
        iterators_sorted[name] = []
        if isdefined(iterator, :fuel)
            iterators_sorted[name] = vcat(
                iterators_sorted[name],
                (
                    NamedTuple{(:primemover, :fuel)},
                    ((iterator.primemover), (iterator.fuel)),
                ),
            )
        else
            iterators_sorted[name] = vcat(
                iterators_sorted[name],
                (NamedTuple{(:primemover, :fuel)}, (iterator.primemover, nothing)),
            )
        end
    end
    return iterators_sorted
end

"""Return a dict where keys are a tuple of input parameters (fuel, unit_type) and values are
generator types."""
function get_generator_mapping(filename = nothing)
    if isnothing(filename)
        filename = GENERATOR_MAPPING_FILE
    end
    genmap = open(filename) do file
        YAML.load(file)
    end

    mappings = Dict{NamedTuple, String}()
    for (gen_type, vals) in genmap
        for val in vals
            pm = isnothing(val["primemover"]) ? nothing :
                uppercase(string(val["primemover"]))
            key = (fuel = val["fuel"], primemover = pm)
            if haskey(mappings, key)
                error("duplicate generator mappings: $gen_type $(key.fuel) $(key.primemover)")
            end
            mappings[key] = gen_type
        end
    end

    return mappings
end

"""Return the generator category for this fuel and unit_type."""
function get_generator_category(fuel, primemover, mappings::Dict{NamedTuple, String})
    fuel = isnothing(fuel) ? nothing : uppercase(string(fuel))
    primemover = isnothing(primemover) ? nothing : uppercase(string(primemover))
    generator = nothing

    # Try to match the primemover if it's defined. If it's nothing then just match on fuel.
    for pm in (primemover, nothing), f in (fuel, nothing)
        key = (fuel = f, primemover = pm)
        if haskey(mappings, key)
            generator = mappings[key]
            break
        end
    end

    if isnothing(generator)
        @error "No mapping defined for generator fuel=$fuel primemover=$primemover"
    end

    return generator
end

"""
    generators = make_fuel_dictionary(system::PSY.System, mapping::Dict{NamedTuple, String})

This function makes a dictionary of fuel type and the generators associated.

# Arguments
- `c_sys5_re::PSY.System`: the system that is used to create the results
- `results::IS.Results`: results

# Key Words
- `categories::Dict{String, NamedTuple}`: if stacking by a different category is desired

# Example
results = solve_op_model!(OpModel)
generators = make_fuel_dictionary(c_sys5_re)

"""
function make_fuel_dictionary(sys::PSY.System, mapping::Dict{NamedTuple, String})
    generators = PSY.get_components(PSY.Generator, sys)
    gen_categories = Dict()
    for category in unique(values(mapping))
        gen_categories["$category"] = []
    end

    for gen in generators
        fuel = hasmethod(PSY.get_fuel, Tuple{typeof(gen)}) ? PSY.get_fuel(gen) : nothing
        category = get_generator_category(fuel, PSY.get_prime_mover(gen), mapping)
        push!(gen_categories["$category"], (string(typeof(gen)), (PSY.get_name(gen))))
    end
    [delete!(gen_categories, "$k") for (k, v) in gen_categories if isempty(v)]
    return gen_categories
end

function make_fuel_dictionary(sys::PSY.System; kwargs...)
    mapping = get_generator_mapping(get(kwargs, :generator_mapping_file, nothing))
    return make_fuel_dictionary(sys, mapping)
end

function _aggregate_data(res::IS.Results, generators::Dict)
    all_results = Dict()
    var_names = collect(keys(IS.get_variables(res)))
    fuel_dataframes = Dict()
    for var in var_names
        name_split = last(split(string(var), "_"))
        all_results[name_split] = IS.get_variables(res)[var]
    end
    for (fuel, list) in generators
        generator_df = DataFrames.DataFrame()
        for tuple in list
            if tuple[1] in keys(all_results)
                data = all_results[tuple[1]]
                colname =
                    typeof(names(data)[1]) == String ? "$(tuple[2])" : Symbol(tuple[2])
                generator_df = hcat(generator_df, data[:, colname], makeunique = true)
            end
        end
        fuel_dataframes[fuel] = generator_df
    end
    return fuel_dataframes
end

"""
    stack = get_stacked_aggregation_data(res::IS.Results, generators::Dict)

This function aggregates the data into a struct type StackedGeneration
so that the results can be plotted using the StackedGeneration recipe.

# Example
```julia
using Plots
gr()
generators = make_fuel_dictionary(system)
stack = get_stacked_aggregation_data(res, generators)
plot(stack)
```
*OR*
```julia
using Plots
gr()
fuel_plot(res, system)
```
"""
function get_stacked_aggregation_data(res::IS.Results, generators::Dict)
    # order at the top
    category_aggs = _aggregate_data(res, generators)
    if Symbol("Curtailment") in keys(IS.get_variables(res))
        category_aggs["Curtailment"] = IS.get_variables(res)[Symbol("Curtailment")]
    end
    time_range = IS.get_time_stamp(res)[!, :Range]
    labels = collect(keys(category_aggs))
    p_labels = collect(keys(res.parameter_values))
    new_labels = intersect(CATEGORY_DEFAULT, labels)
    unmatched = setdiff(labels, new_labels)
    !isempty(unmatched) &&
        throw(IS.DataFormatError("Unable to map colors to $unmatched, adjust $GENERATOR_MAPPING_FILE"))

    parameters = []
    p_legend = []
    for label in p_labels
        parameter = sum(Matrix(res.parameter_values[label]), dims = 2)
        push!(parameters, parameter)
        push!(p_legend, string(label))
    end
    parameters = isempty(parameters) ? nothing : reduce(hcat, parameters)
    legend = []
    agg_var = []
    for label in new_labels
        variable = category_aggs[label]
        if !isempty(variable)
            push!(legend, label)
            push!(agg_var, sum(Matrix(variable), dims = 2))
        end
    end

    # TODO: thee following is a hacky way to add the unserved energy slacks to plots
    if UNSERVEDENERGY_VARIABLE in keys(res.variable_values)
        push!(legend, "Unserved Energy")
        push!(agg_var, sum(Matrix(res.variable_values[UNSERVEDENERGY_VARIABLE]), dims = 2))
    end
    # TODO: thee following is a hacky way to add the over generation slacks to plots
    if OVERGENERATION_VARIABLE in keys(res.variable_values)
        push!(legend, "Over Generation")
        push!(agg_var, sum(Matrix(res.variable_values[OVERGENERATION_VARIABLE]), dims = 2))
    end
    legend = reduce(hcat, legend)
    data_matrix = reduce(hcat, agg_var)
    if isa(legend, String)
        legend = [legend]
    end
    return StackedGeneration(time_range, data_matrix, parameters, legend, p_legend)
end

"""
    bar = get_bar_aggregation_data(results::IS.Results, generators::Dict)

This function aggregates the data into a struct type StackedGeneration
so that the results can be plotted using the StackedGeneration recipe.

# Example
```julia
using Plots
gr()
generators = make_fuel_dictionary(system)
bar = get_bar_aggregation_data(res, generators)
plot(bar)
```
*OR*
```julia
using Plots
gr()
fuel_plot(res, system)
```
"""
function get_bar_aggregation_data(res::IS.Results, generators::Dict)
    stack_data = get_stacked_aggregation_data(res, generators)
    bar_data = sum(stack_data.data_matrix, dims = 1)
    p_bar_data =
        isnothing(stack_data.parameters) ? nothing : sum(stack_data.parameters, dims = 1)
    return BarGeneration(
        stack_data.time_range,
        bar_data,
        p_bar_data,
        stack_data.labels,
        stack_data.p_labels,
    )
end
