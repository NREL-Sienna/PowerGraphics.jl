order = ([
    "Nuclear",
    "Coal",
    "Hydro",
    "Gas_CC",
    "Gas_CT",
    "Storage",
    "Oil_ST",
    "Oil_CT",
    "Sync_Cond",
    "Wind",
    "Solar",
    "CSP",
    "curtailment",
])
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
        if isdefined(iterator.tech, :fuel)
            iterators_sorted[name] = vcat(
                iterators_sorted[name],
                (
                    NamedTuple{(:primemover, :fuel)},
                    ((iterator.tech.primemover), (iterator.tech.fuel)),
                ),
            )
        else
            iterators_sorted[name] = vcat(
                iterators_sorted[name],
                (NamedTuple{(:primemover, :fuel)}, (iterator.tech.primemover, nothing)),
            )
        end
    end
    return iterators_sorted
end

"""
    generators = make_fuel_dictionary(results::IS.Results, system::PSY.System)

This function makes a dictionary of fuel type and the generators associated.

# Arguments
- `c_sys5_re::PSY.System`: the system that is used to create the results
- `results::IS.Results`: results

# Key Words
- `categories::Dict{String, NamedTuple}`: if stacking by a different category is desired

# Example
results = solve_op_model!(OpModel)
generators = make_fuel_dictionary(results, c_sys5_re)

"""
function make_fuel_dictionary(res::IS.Results, sys::PSY.System; kwargs...)

    categories = Dict()
    categories["Solar"] = NamedTuple{(:primemover, :fuel)}, (PSY.PrimeMovers.PVe, nothing)
    categories["Wind"] = NamedTuple{(:primemover, :fuel)}, (PSY.PrimeMovers.WT, nothing)
    categories["Oil_CT"] = NamedTuple{(:primemover, :fuel)},
    (PSY.PrimeMovers.CT, PSY.ThermalFuels.DISTILLATE_FUEL_OIL)
    categories["Oil_ST"] = NamedTuple{(:primemover, :fuel)},
    (PSY.PrimeMovers.ST, PSY.ThermalFuels.DISTILLATE_FUEL_OIL)
    categories["Storage"] = NamedTuple{(:primemover, :fuel)}, (PSY.PrimeMovers.BA, nothing)
    categories["Gas_CT"] =
        NamedTuple{(:primemover, :fuel)}, (PSY.PrimeMovers.CT, PSY.ThermalFuels.NATURAL_GAS)
    categories["Gas_CC"] =
        NamedTuple{(:primemover, :fuel)}, (PSY.PrimeMovers.CC, PSY.ThermalFuels.NATURAL_GAS)
    categories["Hydro"] = NamedTuple{(:primemover, :fuel)}, (PSY.PrimeMovers.HY, nothing)
    categories["Coal"] =
        NamedTuple{(:primemover, :fuel)}, (PSY.PrimeMovers.ST, PSY.ThermalFuels.COAL)
    categories["Nuclear"] =
        NamedTuple{(:primemover, :fuel)}, (PSY.PrimeMovers.ST, PSY.ThermalFuels.NUCLEAR)
    categories = get(kwargs, :categories, categories)
    iterators = _get_iterator(sys, res)
    generators = Dict()

    for (category, fuel_type) in categories
        generators["$category"] = []
        for (name, fuels) in iterators
            for fuel in fuels
                if isnothing(fuel_type) || fuel == fuel_type
                    generators["$category"] = vcat(generators["$category"], name)
                end
            end
        end
        if isempty(generators["$category"])
            delete!(generators, "$category")
        end
    end
    return generators
end

function _aggregate_data(res::IS.Results, generators::Dict)
    All_var = DataFrames.DataFrame()
    var_names = collect(keys(IS.get_variables(res)))
    for i in 1:length(var_names)
        All_var = hcat(All_var, IS.get_variables(res)[var_names[i]], makeunique = true)
    end
    fuel_dataframes = Dict()

    for (k, v) in generators
        generator_df = DataFrames.DataFrame()
        for l in v
            colname = Symbol("$(l)")
            if colname in names(All_var)
                generator_df = hcat(generator_df, All_var[:, colname], makeunique = true)
            end
        end
        fuel_dataframes[k] = generator_df
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
generators = make_fuel_dictionary(res, system)
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
    time_range = IS.get_time_stamp(res)[!, :Range]
    labels = collect(keys(category_aggs))
    p_labels = collect(keys(res.parameter_values))
    new_labels = []

    for fuel in order
        for label in labels
            if label == fuel
                new_labels = vcat(new_labels, label)
            end
        end
    end
    variable = category_aggs[(new_labels[1])]
    if !isempty(p_labels)
        parameter = res.parameter_values[p_labels[1]]
        parameters = abs.(sum(Matrix(parameter), dims = 2))
        p_legend = [string.(p_labels[1])]
        for i in 2:length(p_labels)
            parameter = res.parameter_values[p_labels[i]]
            parameters = hcat(parameters, abs.(sum(Matrix(parameter), dims = 2)))
            p_legend = vcat(p_legend, string.(p_labels[i]))
        end
    else
        parameters = nothing
        p_legend = []
    end
    data_matrix = sum(Matrix(variable), dims = 2)
    legend = [string.(new_labels[1])]
    for i in 2:length(new_labels)
        variable = category_aggs[(new_labels[i])]
        legend = hcat(legend, string.(new_labels[i]))
        data_matrix = hcat(data_matrix, sum(Matrix(variable), dims = 2))
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
generators = make_fuel_dictionary(res, system)
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
    category_aggs = _aggregate_data(res, generators)
    time_range = IS.get_time_stamp(res)[!, :Range]
    labels = collect(keys(category_aggs))
    p_labels = collect(keys(res.parameter_values))
    new_labels = []
    for fuel in order
        for label in labels
            if label == fuel
                new_labels = vcat(new_labels, label)
            end
        end
    end
    variable = category_aggs[(new_labels[1])]
    data_matrix = sum(Matrix(variable), dims = 2)
    legend = [string.(new_labels)[1]]
    for i in 2:length(new_labels)
        variable = category_aggs[(new_labels[i])]
        data_matrix = hcat(data_matrix, sum(Matrix(variable), dims = 2))
        legend = hcat(legend, string.(new_labels)[i])
    end
    if !isempty(p_labels)
        parameter = res.parameter_values[p_labels[1]]
        parameters = sum(Matrix(parameter), dims = 2)
        p_legend = [string.(p_labels[1])]
        for i in 2:length(p_labels)
            parameter = res.parameter_values[p_labels[i]]
            parameters = hcat(parameters, sum(Matrix(parameter), dims = 2))
            p_legend = vcat(p_legend, string.(p_labels[i]))
        end
        p_bar_data = abs.(sum(parameters, dims = 1))
    else
        p_bar_data = nothing
        p_legend = []
    end
    bar_data = sum(data_matrix, dims = 1)
    return BarGeneration(time_range, bar_data, p_bar_data, legend, p_legend)
end
