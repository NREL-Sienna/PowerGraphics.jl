
# the fundamental struct for plotting
struct PGData
    data::Dict{Symbol, DataFrames.DataFrame}
    time::Union{StepRange{Dates.DateTime}, Vector{Dates.DateTime}}
end

function PGData(
    data::Dict{PSI.OptimizationContainerKey, DataFrames.DataFrame},
    time::Union{StepRange{Dates.DateTime}, Vector{Dates.DateTime}},
)
    d = Dict(zip(Symbol.(PSI.encode_keys_as_strings(keys(data))), values(data)))

    rename_load!(d)
    return PGData(d, time)
end

function PGData(
    data::Dict{String, DataFrames.DataFrame},
    time::Union{StepRange{Dates.DateTime}, Vector{Dates.DateTime}},
)
    d = Dict(zip(Symbol.(keys(data))), values(data))

    rename_load!(d)
    return PGData(d, time)
end

function PGData(data::Dict{String, DataFrames.DataFrame})
    d = Dict(zip(Symbol.(keys(data)), no_datetime.(values(data))))
    return PGData(d, first(values(data)).DateTime)
end

# Rename Load variables: TODO: find a better way to do this
function rename_load!(load_values::Dict)
    for (k, v) in load_values
        if haskey(LOAD_RENAMING, k)
            @debug "renaming" k => LOAD_RENAMING[k]
            load_values[LOAD_RENAMING[k]] = v
            pop!(load_values, k)
        end
    end
end

#### Generation Names ####
function get_generation_variable_keys(
    results::IS.Results;
    variable_keys::Vector{T} = PSI.list_variable_keys(results),
) where {T <: PSI.OptimizationContainerKey}
    # TODO: add slacks
    filter_keys = Vector{PSI.OptimizationContainerKey}()
    for k in variable_keys
        if (
            PSI.get_component_type(k) <: PSY.Generator &&
            PSI.get_entry_type(k) == PSI.ActivePowerVariable
        ) || PSI.get_entry_type(k) ∈ keys(BALANCE_SLACKVARS)
            push!(filter_keys, k)
        end
    end

    return filter_keys
end

function get_storage_variable_keys(
    results::IS.Results;
    variable_keys::Vector{T} = PSI.list_variable_keys(results),
) where {T <: PSI.OptimizationContainerKey}
    filter_keys = Vector{PSI.OptimizationContainerKey}()
    for k in variable_keys
        if PSI.get_component_type(k) <: PSY.Storage &&
           PSI.get_entry_type(k) ∈ SUPPORTED_STORAGE_VARIABLES
            push!(filter_keys, k)
        end
    end
    return filter_keys
end

function get_generation_parameter_keys(
    results::IS.Results;
    parameter_keys::Vector{T} = PSI.list_parameter_keys(results),
) where {T <: PSI.OptimizationContainerKey}
    filter_keys = Vector{PSI.OptimizationContainerKey}()
    for k in parameter_keys
        if PSI.get_component_type(k) <: PSY.Generator &&
           PSI.get_entry_type(k) == PSI.ActivePowerTimeSeriesParameter
            push!(filter_keys, k)
        end
    end

    function get_generation_aux_variable_keys(
        results::IS.Results;
        aux_variable_keys::Vector{T} = PSI.list_aux_variable_keys(results),
    ) where {T <: PSI.OptimizationContainerKey}
        # TODO: add slacks
        filter_keys = Vector{PSI.OptimizationContainerKey}()
        for k in aux__variable_keys
            if PSI.get_component_type(k) <: PSY.Generator &&
               PSI.get_entry_type(k) == PSI.PowerOutput
                push!(filter_keys, k)
            end
        end

    return filter_keys
end

#### Load Names ####
function get_load_variable_keys(
    results::IS.Results;
    variable_keys::Vector{T} = PSI.list_variable_keys(results),
) where {T <: PSI.OptimizationContainerKey}
    filter_keys = Vector{PSI.OptimizationContainerKey}()
    for k in variable_keys
        if PSI.get_component_type(k) <: PSY.ElectricLoad &&
           PSI.get_entry_type(k) ∈ SUPPORTED_LOAD_VARIABLES
            push!(filter_keys, k)
        end
    end
    return filter_keys
end

function get_load_parameter_keys(
    results::IS.Results;
    parameter_keys::Vector{T} = PSI.list_parameter_keys(results),
) where {T <: PSI.OptimizationContainerKey}
    filter_keys = Vector{PSI.OptimizationContainerKey}()
    for k in parameter_keys
        if PSI.get_component_type(k) <: PSY.ElectricLoad &&
           PSI.get_entry_type(k) == PSI.ActivePowerTimeSeriesParameter
            push!(filter_keys, k)
        end
    end

    return filter_keys
end

#### Service Names ####
function get_service_variable_keys(
    results::IS.Results;
    variable_keys::Vector{T} = PSI.list_variable_keys(results),
) where {T <: PSI.OptimizationContainerKey}
    filter_keys = Vector{PSI.OptimizationContainerKey}()
    for k in variable_keys
        if PSI.get_component_type(k) <: PSY.Service &&
           PSI.get_entry_type(k) ∈ SUPPORTED_SERVICE_VARIABLES
            push!(filter_keys, k)
        end
    end
    return filter_keys
end

function get_service_parameter_names(
    results::IS.Results;
    parameter_keys::Vector{T} = PSI.list_parameter_keys(results),
) where {T <: PSI.OptimizationContainerKey}
    filter_keys = Vector{PSI.OptimizationContainerKey}()
    for k in parameter_keys
        if PSI.get_component_type(k) <: PSY.ElectricLoad &&
           PSI.get_entry_type(k) == PSI.RequirementTimeSeriesParameter
            push!(filter_keys, k)
        end
    end

    return filter_keys
end

no_datetime(df::DataFrames.DataFrame) = df[:, propertynames(df) .!== :DateTime]

function add_fixed_parameters!(
    variables::Dict{V, DataFrames.DataFrame},
    parameters::Dict{P, DataFrames.DataFrame},
) where {V <: PSI.OptimizationContainerKey, P <: PSI.OptimizationContainerKey}
    # fixed output should be added to plots when there exists a parameter of the form
    # :P__max_active_power__* but there is no corresponding :P__* variable
    for (param_key, param) in parameters
        PSI.get_component_type(param_key) ∈ PSI.get_component_type.(keys(variables)) &&
            continue
        if !haskey(variables, param_key)
            mult = PSI.get_component_type(param_key) ∈ NEGATIVE_PARAMETERS ? -1.0 : 1.0
            variables[param_key] = param
            variables[param_key][:, propertynames(param) .!== :DateTime] .*= mult
        end
    end
end

# finds the parameters corresponding to variables for curtailment calculations
function _curtailment_parameters(
    parameter_keys::Vector{PSI.OptimizationContainerKey},
    variable_keys::Vector{PSI.OptimizationContainerKey},
)
    curtailable_parameters = parameter_keys[findall(
        in(SUPPORTED_CURTAILMENT_PARAMETERS),
        PSI.get_entry_type.(parameter_keys),
    )]
    curtailable_variables = variable_keys[findall(
        in(SUPPORTED_CURTAILMENT_VARIABLES),
        PSI.get_entry_type.(variable_keys),
    )]

    curtailment_parameters = Vector{
        NamedTuple{
            (:parameter, :variable),
            Tuple{PSI.OptimizationContainerKey, PSI.OptimizationContainerKey},
        },
    }()
    for pk in curtailable_parameters
        for cv in curtailable_variables[PSI.get_component_type.(
            curtailable_variables,
        ) .== PSI.get_component_type(pk)]
            push!(curtailment_parameters, (parameter = pk, variable = cv))
        end
    end
    return unique(curtailment_parameters)
end

function _filter_curtailment!(
    variable_values::Dict,
    parameter_values::Dict,
    curtailment_parameters::Vector{
        NamedTuple{
            (:parameter, :variable),
            Tuple{PSI.OptimizationContainerKey, PSI.OptimizationContainerKey},
        },
    },
)
    for curtailment in curtailment_parameters
        curtailment_var_key = PSI.VariableKey(
            PSI.get_entry_type(curtailment.variable),
            PSI.get_component_type(curtailment.variable),
            "Curtailment",
        )

        curt =
            parameter_values[curtailment.parameter] .- variable_values[curtailment.variable]
        if haskey(variable_values, curtailment_var_key)
            variable_values[curtailment_var_key] =
                hcat(variable_values[curtailment_var_key], no_datetime(curt))
        else
            variable_values[curtailment_var_key] = curt
        end
    end
end

function get_generation_data(results::R; kwargs...) where {R <: IS.Results}
    initial_time = get(kwargs, :initial_time, get(kwargs, :start_time, nothing))
    len = get(kwargs, :horizon, get(kwargs, :len, nothing))
    variable_keys = get(kwargs, :variable_keys, PSI.list_variable_keys(results))
    parameter_keys = get(kwargs, :parameter_keys, PSI.list_parameter_keys(results))
    aux_variable_keys = get(kwargs, :aux_variable_keys, PSI.list_aux_variable_keys(results))
    curtailment = get(kwargs, :curtailment, true)
    storage = get(kwargs, :storage, true)

    if curtailment && (haskey(kwargs, :variable_keys) || haskey(kwargs, :parameter_keys))
        @warn "Cannot guarantee curtailment calculations with specified keys"
    end

    injection_keys = get_generation_variable_keys(results; variable_keys = variable_keys)
    if storage
        injection_keys = vcat(
            injection_keys,
            get_storage_variable_keys(results; variable_keys = variable_keys),
        )
    end

    parameter_keys = get_generation_parameter_keys(results; parameter_keys = parameter_keys)

    aux_variable_keys = get_generation_aux_variable_keys(results; aux_variable_keys = aux_variable_keys)

    variables = PSI.read_variables_with_keys(
        results,
        injection_keys;
        start_time = initial_time,
        len = len,
    )
    parameters = PSI.read_parameters_with_keys(
        results,
        parameter_keys;
        start_time = initial_time,
        len = len,
    )

    aux_variables = PSI.read_aux_variables_with_keys(
        results,
        aux_variable_keys;
        start_time = initial_time,
        len = len,
    )

    add_fixed_parameters!(variables, parameters, aux_variables)

    if curtailment
        curtailment_parameters = _curtailment_parameters(parameter_keys, injection_keys)
        _filter_curtailment!(variables, parameters, curtailment_parameters)
    end

    timestamps = PSI.get_realized_timestamps(results; start_time = initial_time, len = len)
    return PGData(variables, timestamps)
end

function get_load_data(results::R; kwargs...) where {R <: IS.Results}
    initial_time = get(kwargs, :initial_time, get(kwargs, :start_time, nothing))
    len = get(kwargs, :horizon, get(kwargs, :len, nothing))
    variable_keys = get(kwargs, :variable_keys, PSI.list_variable_keys(results))
    parameter_keys = get(kwargs, :parameter_keys, PSI.list_parameter_keys(results))

    variable_keys = get_load_variable_keys(results; variable_keys = variable_keys)
    parameter_keys = get_load_parameter_keys(results; parameter_keys = parameter_keys)

    variables = PSI.read_variables_with_keys(
        results,
        variable_keys;
        start_time = initial_time,
        len = len,
    )
    parameters = PSI.read_parameters_with_keys(
        results,
        parameter_keys;
        start_time = initial_time,
        len = len,
    )

    add_fixed_parameters!(variables, parameters)

    timestamps = PSI.get_realized_timestamps(results; start_time = initial_time, len = len)
    return PGData(variables, timestamps)
end

################################### INPUT DEMAND #################################

function _get_loads(system::PSY.System, bus::PSY.Bus)
    return [
        load for load in PSY.get_components(PSY.PowerLoad, system, PSY.get_available) if
        PSY.get_bus(load) == bus
    ]
end
function _get_loads(system::PSY.System, agg::T) where {T <: PSY.AggregationTopology}
    return PSY.get_components_in_aggregation_topology(PSY.PowerLoad, system, agg)
end
function _get_loads(system::PSY.System, load::PSY.PowerLoad)
    return [load]
end
function _get_loads(system::PSY.System, sys::PSY.System)
    return PSY.get_components(PSY.PowerLoad, system, PSY.get_available)
end

get_base_power(system::PSY.System) = PSY.get_base_power(system)
get_base_power(results::PSI.SimulationProblemResults) = IS.get_base_power(results)
get_base_power(results::PSI.ProblemResults) = results.base_power

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
    parameters = Dict{Symbol, DataFrames.DataFrame}()
    PSY.set_units_base_system!(system, "SYSTEM_BASE")
    for agg in aggregation_components
        loads = _get_loads(system, agg)
        length(loads) == 0 && continue
        colname = aggregation == PSY.System ? "System" : PSY.get_name(agg)
        load_values = DataFrames.DataFrame()
        for load in loads
            f = PSY.get_time_series_values( # TODO: this isn't applying the scaling factors
                PSY.Deterministic,
                load,
                "max_active_power",
                start_time = initial_time,
                len = horizon,
            )
            load_values[:, PSY.get_name(load)] = f
        end
        parameters[Symbol(colname)] = load_values
    end
    time_range =
        range(initial_time, step = PSY.get_time_series_resolution(system), length = horizon)

    return PGData(parameters, time_range)
end

function get_service_data(results::R; kwargs...) where {R <: IS.Results}
    initial_time = get(kwargs, :initial_time, get(kwargs, :start_time, nothing))
    len = get(kwargs, :horizon, get(kwargs, :len, nothing))
    variable_keys = get(kwargs, :variable_keys, PSI.list_variable_keys(results))
    #parameter_keys = get(kwargs, :parameter_keys, PSI.list_parameter_keys(results))

    variable_keys = get_service_variable_keys(results; variable_keys = variable_keys)

    variables = PSI.read_variables_with_keys(
        results,
        variable_keys;
        start_time = initial_time,
        len = len,
    )

    timestamps = PSI.get_realized_timestamps(results; start_time = initial_time, len = len)

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
    aggregate::Union{Function, Nothing} = nothing,
)
    aggregate = isnothing(aggregate) ? x -> sum(x, dims = 2) : aggregate
    names = isnothing(names) ? keys(data) : names
    values = []
    keep_names = []
    for k in names
        if !isempty(data[k])
            push!(values, aggregate(Matrix(no_datetime(data[k]))))
            push!(keep_names, k)
        end
    end
    data = hcat(values...)
    keep_names = string.(keep_names)
    isempty(data) && return DataFrames.DataFrame()
    return DataFrames.DataFrame(data, keep_names)
end

"""
Re-categorizes data according to an aggregation dictionary
* makes no guarantee of complete data collection *

# Example

```julia
aggregation = PG.make_fuel_dictionary(results_uc.system)
categorize_data(gen_uc.data, aggregation)
```

"""
function categorize_data(
    data::Dict{Symbol, DataFrames.DataFrame},
    aggregation::Dict;
    curtailment = true,
    slacks = true,
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
        if !isempty(category_df)
            category_dataframes[string(category)] = category_df
        end
    end
    if curtailment
        dfs = []
        for (key, val) in data
            if endswith(string(key), "Curtailment")
                push!(dfs, no_datetime(val))
            end
        end
        if !isempty(dfs)
            category_dataframes["Curtailment"] = hcat(dfs...)
        end
    end
    if slacks
        for (slack, slack_name) in BALANCE_SLACKVARS
            for id in findall(x -> occursin(string(slack), x), string.(keys(data)))
                slack_key = collect(keys(data))[id]
                category_dataframes[slack_name] = data[slack_key]
            end
        end
    end

    return category_dataframes
end
