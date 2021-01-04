struct PlotList # TODO: Is PlotList needed?
    plots::Dict
end
function PlotList()
    PlotList(Dict())
end

Base.show(io::IO, mm::MIME"text/html", p::PlotList) =
    show(io, mm, "$(Plots.backend()) with $(length(p.plots)) plots, named $(keys(p.plots))")
Base.show(io::IO, mm::MIME"text/plain", p::PlotList) =
    show(io, mm, "$(Plots.backend()) with $(length(p.plots)) plots, named $(keys(p.plots))")

# the fundamental struct for plotting
struct PGData
    data::Dict{Symbol, DataFrames.DataFrame}
    time::StepRange{Dates.DateTime}
end

#### Generation Names ####
function get_generation_variable_names(
    results::IS.Results;
    names::Union{Nothing, Vector{Symbol}} = nothing,
)
    existing_names = PSI.get_existing_variables(results)
    names = isnothing(names) ? existing_names : [n for n in names if n ∈ existing_names]
    filter_names = Vector{Symbol}()
    for name in names
        name_string = string(name)
        if any(startswith.(name_string, SUPPORTEDVARPREFIX))
            if any(endswith.(name_string, SUPPORTEDGENPARAMS))
                push!(filter_names, name)
            end
        elseif any(name .== SLACKVARS)
            push!(filter_names, name)
        end
    end
    return filter_names
end

function get_generation_parameter_names(
    results::IS.Results;
    names::Union{Nothing, Vector{Symbol}} = nothing,
)
    existing_names = PSI.get_existing_parameters(results)
    names = isnothing(names) ? existing_names : [n for n in names if n ∈ existing_names]
    filter_names = Vector{Symbol}()
    for name in names
        name_string = string(name)
        if any(startswith.(name_string, SUPPORTEDPARAMPREFIX))
            if any(endswith.(name_string, SUPPORTEDGENPARAMS))
                push!(filter_names, name)
            end
        end
    end
    return filter_names
end

#### Load Names ####
function get_load_variable_names(
    results::IS.Results;
    names::Union{Nothing, Vector{Symbol}} = nothing,
)
    existing_names = PSI.get_existing_variables(results)
    names = isnothing(names) ? existing_names : [n for n in names if n ∈ existing_names]
    filter_names = Vector{Symbol}()
    for name in names
        name_string = string(name)
        if any(startswith.(name_string, SUPPORTEDVARPREFIX))
            if any(endswith.(name_string, SUPPORTEDLOADPARAMS))
                push!(filter_names, name)
            end
        end
    end
    return filter_names
end

function get_load_parameter_names(
    results::IS.Results;
    names::Union{Nothing, Vector{Symbol}} = nothing,
)
    existing_names = PSI.get_existing_parameters(results)
    names = isnothing(names) ? existing_names : [n for n in names if n ∈ existing_names]
    filter_names = Vector{Symbol}()
    for name in names
        name_string = string(name)
        if any(startswith.(name_string, SUPPORTEDPARAMPREFIX))
            if any(endswith.(name_string, SUPPORTEDLOADPARAMS))
                push!(filter_names, name)
            end
        end
    end
    return filter_names
end

#### Service Names ####
function get_service_variable_names(
    results::IS.Results;
    names::Union{Nothing, Vector{Symbol}} = nothing,
)
    existing_names = PSI.get_existing_variables(results)
    names = isnothing(names) ? existing_names : [n for n in names if n ∈ existing_names]
    filter_names = Vector{Symbol}()
    for name in names
        name_string = string(name)
        if any(endswith.(name_string, SUPPORTEDSERVICEPARAMS))
            push!(filter_names, name)
        end
    end
    return filter_names
end

function get_service_parameter_names(
    results::IS.Results;
    names::Union{Nothing, Vector{Symbol}} = nothing,
)
    existing_names = PSI.get_existing_parameters(results)
    names = isnothing(names) ? existing_names : [n for n in names if n ∈ existing_names]
    filter_names = Vector{Symbol}()
    for name in names
        name_string = string(name)
        if any(endswith.(name_string, SUPPORTEDSERVICEPARAMS))
            push!(filter_names, name)
        end
    end
    return filter_names
end

#### get data ###

function _get_matching_param(var_name)
    return Symbol(replace(string(var_name), SUPPORTEDVARPREFIX => SUPPORTEDPARAMPREFIX))
end

function _get_matching_var(param_name)
    return Symbol(replace(string(param_name), SUPPORTEDPARAMPREFIX => SUPPORTEDVARPREFIX))
end

function add_fixed_parameters!(
    variables::Dict{Symbol, DataFrames.DataFrame},
    parameters::Dict{Symbol, DataFrames.DataFrame},
)
    # fixed output should be added to plots when there exists a parameter of the form
    # :P__max_active_power__* but there is no corresponding :P__* variable
    for (param_name, param) in parameters
        var_name = _get_matching_var(param_name)
        if !haskey(variables, var_name)
            mult = any(endswith.(string(param_name), NEGATIVE_PARAMETERS)) ? -1.0 : 1.0
            variables[var_name] = param .* mult
        end
    end
end

function _curtailment_parameters(parameters::Vector{Symbol}, variables::Vector{Symbol})
    curtailment_parameters =
        Vector{NamedTuple{(:parameter, :variable), Tuple{Symbol, Symbol}}}()
    for var in variables
        var_param = Symbol(replace(string(var), SUPPORTEDVARPREFIX => SUPPORTEDPARAMPREFIX))
        if var_param in parameters
            push!(curtailment_parameters, (parameter = var_param, variable = var))
        end
    end
    return curtailment_parameters
end

function _filter_curtailment!(
    variable_values::Dict,
    parameter_values::Dict,
    curtailment_parameters::Vector{
        NamedTuple{(:parameter, :variable), Tuple{Symbol, Symbol}},
    },
)
    for curtailment in curtailment_parameters
        if !haskey(variable_values, curtailment.variable)
            variable_values[curtailment.variable] = parameter_values[curtailment.parameter]
        else
            curt =
                parameter_values[curtailment.parameter] .-
                variable_values[curtailment.variable]
            if haskey(variable_values, :Curtailment)
                variable_values[:Curtailment] = hcat(variable_values[:Curtailment], curt)
            else
                variable_values[:Curtailment] = curt
            end
        end
    end
end

function get_generation_data(results::PSI.StageResults; kwargs...)
    initial_time = get(kwargs, :initial_time, nothing)
    len = get(kwargs, :horizon, get(kwargs, :len, nothing))
    names = get(kwargs, :names, nothing)
    curtailment = get(kwargs, :curtailment, true)
    if curtailment && !isnothing(names)
        @warn "Cannot guarantee curtailment calculations with specified names"
    end

    var_names = get_generation_variable_names(results; names = names)
    param_names = get_generation_parameter_names(results; names = names)

    variables = PSI.read_realized_variables(
        results;
        names = var_names,
        initial_time = initial_time,
        len = len,
    )
    parameters = PSI.read_realized_parameters(
        results;
        names = param_names,
        initial_time = initial_time,
        len = len,
    )

    add_fixed_parameters!(variables, parameters)

    if curtailment
        curtailment_parameters = _curtailment_parameters(param_names, var_names)
        _filter_curtailment!(variables, parameters, curtailment_parameters)
    end

    timestamps =
        PSI.get_realized_timestamps(results; initial_time = initial_time, len = len)
    return PGData(variables, timestamps)
end

function get_load_data(results::PSI.StageResults; kwargs...)
    initial_time = get(kwargs, :initial_time, nothing)
    len = get(kwargs, :horizon, get(kwargs, :len, nothing))
    names = get(kwargs, :names, nothing)

    var_names = get_load_variable_names(results; names = names)
    param_names = get_load_parameter_names(results; names = names)

    variables = PSI.read_realized_variables(
        results;
        names = var_names,
        initial_time = initial_time,
        len = len,
    )
    parameters = PSI.read_realized_parameters(
        results;
        names = param_names,
        initial_time = initial_time,
        len = len,
    )

    add_fixed_parameters!(variables, parameters)

    timestamps =
        PSI.get_realized_timestamps(results; initial_time = initial_time, len = len)
    return PGData(variables, timestamps)
end

################################### INPUT DEMAND #################################

function _get_loads(system::PSY.System, bus::PSY.Bus)
    return [
        load for
        load in PSY.get_components(PSY.PowerLoad, system) if PSY.get_bus(load) == bus
    ]
end
function _get_loads(system::PSY.System, agg::T) where {T <: PSY.AggregationTopology}
    return PSY.get_components_in_aggregation_topology(PSY.PowerLoad, system, agg)
end
function _get_loads(system::PSY.System, load::PSY.PowerLoad)
    return [load]
end
function _get_loads(system::PSY.System, sys::PSY.System)
    return PSY.get_components(PSY.PowerLoad, system)
end

get_base_power(system::PSY.System) = PSY.get_base_power(system)
get_base_power(results::PSI.StageResults) = IS.get_base_power(results)

function get_load_data(
    system::PSY.System;
    aggregation::Union{
        Type{PSY.PowerLoad},
        Type{PSY.Bus},
        Type{PSY.System},
        Type{<:PSY.AggregationTopology},
    } = PSY.PowerLoad,
    kwargs...,
)
    aggregation_components =
        aggregation == PSY.System ? [system] : PSY.get_components(aggregation, system)
    if isempty(aggregation_components)
        throw(ArgumentError("System does not have type $aggregation."))
    end
    horizon = get(kwargs, :horizon, PSY.get_forecast_horizon(system))
    initial_time = get(kwargs, :initial_time, PSY.get_forecast_initial_timestamp(system))
    parameters = DataFrames.DataFrame()
    PSY.set_units_base_system!(system, "SYSTEM_BASE")
    for agg in aggregation_components
        loads = _get_loads(system, agg)
        length(loads) == 0 && continue
        colname = aggregation == PSY.System ? "System" : PSY.get_name(agg)
        load_values = []
        for load in loads
            f = PSY.get_time_series_values( # TODO: this isn't applying the scaling factors
                PSY.Deterministic,
                load,
                "max_active_power",
                start_time = initial_time,
                len = horizon,
            )
            push!(load_values, f)
        end
        load_values =
            length(loads) == 1 ? load_values[1] :
            dropdims(sum(Matrix(reduce(hcat, load_values)), dims = 2), dims = 2)
        parameters[:, Symbol(colname)] = load_values
    end
    time_range =
        range(initial_time, step = PSY.get_time_series_resolution(system), length = horizon)

    return PGData(
        Dict(:Load => parameters[!, setdiff(names(parameters), "timestamp")]),
        time_range,
    )
end

function get_service_data(results::PSI.StageResults; kwargs...)
    initial_time = get(kwargs, :initial_time, nothing)
    len = get(kwargs, :horizon, get(kwargs, :len, nothing))
    names = get(kwargs, :names, nothing)

    var_names = get_service_variable_names(results; names = names)

    variables = PSI.read_realized_variables(
        results;
        names = var_names,
        initial_time = initial_time,
        len = len,
    )
    timestamps =
        PSI.get_realized_timestamps(results; initial_time = initial_time, len = len)

    return PGData(variables, timestamps)
end

#### result combination and aggregation ####

"""
aggregates and combines data into single DataFrame

# Example

```julia
PG.combine_categories(gen_uc.data)
```

"""
function combine_categories(
    data::Union{Dict{Symbol, DataFrames.DataFrame}, Dict{String, DataFrames.DataFrame}};
    names::Union{Vector{String}, Vector{Symbol}, Nothing} = nothing,
    agg::Union{Function, Nothing} = nothing,
)
    agg = isnothing(agg) ? x -> sum(x, dims = 2) : agg
    names = isnothing(names) ? keys(data) : names
    data = hcat([agg(Matrix(data[k])) for k in names]...)
    return DataFrames.DataFrame(data, string.(collect(names)))
end

"""
Re-categorizes data according to an aggregation dictionary
* makes no guarantee of complete data collection *

# Example

```julia
aggregation = PG.make_fuel_dictionary(results_uc.system)
PG.categorize_data(gen_uc.data, aggregation)
```

"""
function categorize_data(
    data::Dict{Symbol, DataFrames.DataFrame},
    aggregation::Dict;
    curtailment = true,
)
    category_dataframes = Dict{String, DataFrames.DataFrame}()
    var_types = Dict(zip(last.(split.(string.(keys(data)), "_")), keys(data)))
    for (category, list) in aggregation
        category_df = DataFrames.DataFrame()
        for tuple in list
            if haskey(var_types, tuple[1])
                category_data = data[var_types[tuple[1]]]
                colname =
                    typeof(names(category_data)[1]) == String ? "$(tuple[2])" :
                    Symbol(tuple[2])
                DataFrames.insertcols!(
                    category_df,
                    (colname => category_data[:, colname]),
                    makeunique = true,
                )
            end
        end
        category_dataframes[string(category)] = category_df
    end
    if curtailment && haskey(data, :Curtailment)
        category_dataframes["Curtailment"] = data[:Curtailment]
    end
    return category_dataframes
end
