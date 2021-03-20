
# TODO: add kwarg handling for filtering by initial_time and len
function _read_realized_results(
    result_values::Dict{Symbol, DataFrames.DataFrame},
    names::Union{Nothing, Vector{Symbol}},
)
    existing_names = collect(keys(result_values))
    names = isnothing(names) ? existing_names : names
    PSI._validate_names(existing_names, names)
    return filter(p -> (p.first ∈ names), result_values)
end

function _read_results(
    result_values::Dict{Symbol, DataFrames.DataFrame},
    names::Union{Nothing, Vector{Symbol}},
    initial_time::Dates.DateTime,
)
    realized_results = _read_realized_results(result_values, names)
    results = PSI.FieldResultsByTime()
    for (name, df) in realized_results
        results[name] = PSI.ResultsByTime(initial_time => df)
    end
    return results
end

function PSI.read_realized_variables(
    res::PSI.ProblemResults;
    names::Union{Vector{Symbol}, Nothing} = nothing,
    kwargs...,
)
    variable_values = PSI.get_variables(res)
    return _read_realized_results(variable_values, names)
end

function PSI.read_realized_parameters(
    res::PSI.ProblemResults;
    names::Union{Vector{Symbol}, Nothing} = nothing,
    kwargs...,
)
    parameter_values = IS.get_parameters(res)
    return _read_realized_results(parameter_values, names)
end

function PSI.read_realized_duals(
    res::PSI.ProblemResults;
    names::Union{Vector{Symbol}, Nothing} = nothing,
    kwargs...,
)
    dual_values = get_duals(res)
    return _read_realized_results(dual_values, names)
end

function PSI.read_variables(
    res::PSI.ProblemResults;
    names::Union{Vector{Symbol}, Nothing} = nothing,
    kwargs...,
)
    result_values = PSI.get_variables(res)
    return _read_results(result_values, names, first(PSI.get_timestamps(res)))
end

function PSI.read_parameters(
    res::PSI.ProblemResults;
    names::Union{Vector{Symbol}, Nothing} = nothing,
    kwargs...,
)
    result_values = IS.get_parameters(res)
    return _read_results(result_values, names, first(PSI.get_timestamps(res)))
end

function read_duals(
    res::PSI.ProblemResults;
    names::Union{Vector{Symbol}, Nothing} = nothing,
    kwargs...,
)
    result_values = PSI.get_duals(res)
    return _read_results(result_values, names, first(PSI.get_timestamps(res)))
end

PSI.get_realized_timestamps(res::PSI.ProblemResults; kwargs...) = PSI.get_timestamps(res)
