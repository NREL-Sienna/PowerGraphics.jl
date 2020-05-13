function _filter_variables(results::IS.Results; kwargs...)
    filter_results = Dict()
    filter_parameters = Dict()
    reserves = get(kwargs, :reserves, false)
    if reserves
        for (key, var) in IS.get_variables(results)
            start = split("$key", "_")[1]
            if in(start, VARIABLE_TYPES)
                filter_results[key] = var
            end
        end
    else
        for (key, var) in results.parameter_values
            new_key = replace(replace("$key", "parameter_" => ""), "_" => "__")
            if startswith(new_key, "P")
                filter_results[Symbol(new_key)] = var
            end
        end
        for (key, var) in IS.get_variables(results)
            if startswith("$key", "P") | any(key .== [:γ⁻__P, :γ⁺__P])
                filter_results[key] = var
            end
        end
    end
    load = get(kwargs, :load, false)
    if load
        for (key, parameter) in results.parameter_values
            param = split("$key", "_")[end]
            if param == "PowerLoad"
                filter_parameters[Symbol(param)] = parameter
            end
        end
    end
    new_results = Results(
        IS.get_base_power(results),
        filter_results,
        IS.get_optimizer_log(results),
        IS.get_total_cost(results),
        IS.get_time_stamp(results),
        results.dual_values,
        filter_parameters,
    )
    return new_results
end

function _filter_parameters(results::IS.Results)
    filter_parameters = Dict()
    for (k, v) in results.parameter_values
        param = split("$k", "_")[end]
        filter_parameters[Symbol(param)] = v
    end
    new_results = Results(
        IS.get_base_power(results),
        IS.get_variables(results),
        IS.get_optimizer_log(results),
        IS.get_total_cost(results),
        IS.get_time_stamp(results),
        results.dual_values,
        filter_parameters,
    )
    return new_results
end

function fuel_plot(
    res::IS.Results,
    variables::Array,
    genterator_data::Union{Dict, PSY.System};
    kwargs...,
)
    res_var = Dict()
    for variable in variables
        res_var[variable] = IS.get_variables(res)[variable]
    end
    results = Results(
        IS.get_base_power(res),
        res_var,
        IS.get_optimizer_log(res),
        IS.get_total_cost(res),
        IS.get_time_stamp(res),
        res.dual_values,
        res.parameter_values,
    )
    plots = fuel_plot(results, genterator_data; kwargs...)
    return plots
end

function fuel_plot(
    results::Array,
    variables::Array,
    genterator_data::Union{Dict, PSY.System};
    kwargs...,
)
    new_results = []
    for res in results
        res_var = Dict()
        for variable in variables
            res_var[variable] = IS.get_variables(res)[variable]
        end
        results = Results(
            IS.get_base_power(res),
            res_var,
            IS.get_optimizer_log(res),
            IS.get_total_cost(res),
            IS.get_time_stamp(res),
            res.dual_values,
            res.parameter_values,
        )
        new_results = vcat(new_results, results)
    end
    plots = fuel_plot(new_results, genterator_data; kwargs...)
    return plots
end

"""
    fuel_plot(results, system)

This function makes a stack plot of the results by fuel type
and assigns each fuel type a specific color.

# Arguments

- `res::Results = results`: results to be plotted
- `system::PSY.System`: The power systems system

# Example

```julia
res = solve_op_problem!(OpProblem)
fuel_plot(res, sys)
```

# Accepted Key Words
- `display::Bool`: set to false to prevent the plots from displaying
- `reserves::Bool`: if reserves = true, the researves will be plotted with the active power
- `save::String = "file_path"`: set a file path to save the plots
- `seriescolor::Array`: Set different colors for the plots
- `title::String = "Title"`: Set a title for the plots
- `generator_mapping_file` = "file_path" : file path to yaml definig generator category by fuel and primemover
"""
function fuel_plot(res::Union{IS.Results, Array}, sys::PSY.System; kwargs...)
    ref = make_fuel_dictionary(sys; kwargs...)
    return fuel_plot(res, ref; kwargs...)
end

"""
    fuel_plot(results::IS.Results, generators)

This function makes a stack plot of the results by fuel type
and assigns each fuel type a specific color.

# Arguments

- `res::IS.Results = results`: results to be plotted
- `generators::Dict`: the dictionary of fuel type and an array
 of the generators per fuel type, or some other specified category order

# Example

```julia
res = solve_op_problem!(OpProblem)
generator_dict = make_fuel_dictionary(sys, mapping)
fuel_plot(res, generator_dict)
```

# Accepted Key Words
- `display::Bool`: set to false to prevent the plots from displaying
- `save::String = "file_path"`: set a file path to save the plots
- `seriescolor::Array`: Set different colors for the plots
- `reserves::Bool`: if reserves = true, the researves will be plotted with the active power
- `title::String = "Title"`: Set a title for the plots
"""

function fuel_plot(res::IS.Results, generator_dict::Dict; kwargs...)
    set_display = get(kwargs, :display, true)
    save_fig = get(kwargs, :save, nothing)
    res = _filter_variables(res; kwargs...)
    stack = get_stacked_aggregation_data(res, generator_dict)
    bar = get_bar_aggregation_data(res, generator_dict)
    backend = Plots.backend()
    default_colors = match_fuel_colors(stack, bar, backend, FUEL_DEFAULT)
    seriescolor = get(kwargs, :seriescolor, default_colors)
    ylabel = _make_ylabel(IS.get_base_power(res))
    title = get(kwargs, :title, "Fuel")
    if isnothing(backend)
        throw(IS.ConflictingInputsError("No backend detected. Type gr() to set a backend."))
    end
    return _fuel_plot_internal(
        stack,
        bar,
        seriescolor,
        backend,
        save_fig,
        set_display,
        title,
        ylabel;
        kwargs...,
    )
end

function fuel_plot(results::Array, generator_dict::Dict; kwargs...)
    set_display = get(kwargs, :display, true)
    save_fig = get(kwargs, :save, nothing)
    stack = StackedGeneration[]
    bar = BarGeneration[]
    for result in results
        new_res = _filter_variables(result; kwargs...)
        push!(stack, get_stacked_aggregation_data(new_res, generator_dict))
        push!(bar, get_bar_aggregation_data(new_res, generator_dict))
    end
    backend = Plots.backend()
    default_colors = match_fuel_colors(stack[1], bar[1], backend, FUEL_DEFAULT)
    seriescolor = get(kwargs, :seriescolor, default_colors)
    title = get(kwargs, :title, "Fuel")
    ylabel = _make_ylabel(IS.get_base_power(results[1]))
    if isnothing(backend)
        throw(IS.ConflictingInputsError("No backend detected. Type gr() to set a backend."))
    end
    return _fuel_plot_internal(
        stack,
        bar,
        seriescolor,
        backend,
        save_fig,
        set_display,
        title,
        ylabel;
        kwargs...,
    )
end

"""
   bar_plot(results::IS.Results)

This function plots a bar plot for the generators in each variable within
the results variables dictionary, and makes a bar plot for all of the variables.

# Arguments
- `res::IS.Results = results`: results to be plotted

# Example

```julia
results = solve_op_problem!(OpProblem)
bar_plot(results)
```

# Accepted Key Words
- `display::Bool`: set to false to prevent the plots from displaying
- `save::String = "file_path"`: set a file path to save the plots
- `seriescolor::Array`: Set different colors for the plots
- `reserves::Bool`: if reserves = true, the researves will be plotted with the active power
- `title::String = "Title"`: Set a title for the plots
"""

function bar_plot(res::IS.Results; kwargs...)
    backend = Plots.backend()
    set_display = get(kwargs, :display, true)
    save_fig = get(kwargs, :save, nothing)
    res = _filter_variables(res; kwargs...)
    if isnothing(backend)
        throw(IS.ConflictingInputsError("No backend detected. Type gr() to set a backend."))
    end
    return _bar_plot_internal(res, backend, save_fig, set_display; kwargs...)
end

"""
   bar_plot(results::Array{IS.Results})

This function plots a subplot for each result. Each subplot has a bar plot for the generators in each variable within
the results variables dictionary, and makes a bar plot for all of the variables per result object.

# Arguments
- `res::Array{IS.Results} = [results1; results2]`: results to be plotted

# Example

```julia
results1 = solve_op_problem!(OpProblem1)
results2 = solve_op_problem!(OpProblem2)
bar_plot([results1; results2])
```

# Accepted Key Words
- `display::Bool`: set to false to prevent the plots from displaying
- `save::String = "file_path"`: set a file path to save the plots
- `seriescolor::Array`: Set different colors for the plots
- `reserves::Bool`: if reserves = true, the researves will be plotted with the active power
- `title::String = "Title"`: Set a title for the plots
"""

function bar_plot(results::Array; kwargs...)
    backend = Plots.backend()
    set_display = get(kwargs, :display, true)
    save_fig = get(kwargs, :save, nothing)
    res = _filter_variables(results[1]; kwargs...)
    for i in 2:size(results, 1)
        filter = _filter_variables(results[i]; kwargs...)
        res = hcat(res, filter)
    end
    if isnothing(backend)
        throw(IS.ConflictingInputsError("No backend detected. Type gr() to set a backend."))
    end
    return _bar_plot_internal(res, backend, save_fig, set_display; kwargs...)
end

function bar_plot(res::IS.Results, variables::Array; kwargs...)
    res_var = Dict()
    for variable in variables
        res_var[variable] = IS.get_variables(res)[variable]
    end
    results = Results(
        IS.get_base_power(res),
        res_var,
        IS.get_optimizer_log(res),
        IS.get_total_cost(res),
        IS.get_time_stamp(res),
        res.dual_values,
        res.parameter_values,
    )
    return bar_plot(results; kwargs...)
end

function bar_plot(results::Array, variables::Array; kwargs...)
    new_results = []
    for res in results
        res_var = Dict()
        for variable in variables
            res_var[variable] = IS.get_variables(res)[variable]
        end
        results = Results(
            IS.get_base_power(res),
            res_var,
            IS.get_optimizer_log(res),
            IS.get_total_cost(res),
            IS.get_time_stamp(res),
            res.dual_values,
            res.parameter_values,
        )
        new_results = vcat(new_results, results)
    end
    return bar_plot(new_results; kwargs...)
end

"""
     stack_plot(results::IS.Results)

This function plots a stack plot for the generators in each variable within
the results variables dictionary, and makes a stack plot for all of the variables.

# Arguments
- `res::IS.Results = results`: results to be plotted

# Examples

```julia
results = solve_op_problem!(OpProblem)
stack_plot(results)
```

# Accepted Key Words
- `display::Bool`: set to false to prevent the plots from displaying
- `save::String = "file_path"`: set a file path to save the plots
- `seriescolor::Array`: Set different colors for the plots
- `reserves::Bool`: if reserves = true, the researves will be plotted with the active power
- `title::String = "Title"`: Set a title for the plots
"""

function stack_plot(res::IS.Results; kwargs...)
    set_display = get(kwargs, :set_display, true)
    backend = Plots.backend()
    save_fig = get(kwargs, :save, nothing)
    res = _filter_variables(res; kwargs...)
    if isnothing(backend)
        throw(IS.ConflictingInputsError("No backend detected. Type gr() to set a backend."))
    end
    return _stack_plot_internal(res, backend, save_fig, set_display; kwargs...)
end

"""
     stack_plot(results::Array{IS.Results})

This function plots a subplot for each result object. Each subplot stacks the generators in each variable within
results variables dictionary, and makes a stack plot for all of the variables per result object.

# Arguments
- `res::Array{IS.Results} = [results1, results2]`: results to be plotted

# Examples

```julia
results1 = solve_op_problem!(OpProblem1)
results2 = solve_op_problem!(OpProblem2)
stack_plot([results1; results2])
```

# Accepted Key Words
- `display::Bool`: set to false to prevent the plots from displaying
- `save::String = "file_path"`: set a file path to save the plots
- `seriescolor::Array`: Set different colors for the plots
- `reserves::Bool`: if reserves = true, the researves will be plotted with the active power
- `title::String = "Title"`: Set a title for the plots
"""

function stack_plot(results::Array{}; kwargs...)
    set_display = get(kwargs, :set_display, true)
    backend = Plots.backend()
    save_fig = get(kwargs, :save, nothing)
    new_results = _filter_variables(results[1]; kwargs...)
    for res in 2:length(results)
        filtered = _filter_variables(results[res]; kwargs...)
        new_results = hcat(new_results, filtered)
    end
    if isnothing(backend)
        throw(IS.ConflictingInputsError("No backend detected. Type gr() to set a backend."))
    end
    return _stack_plot_internal(new_results, backend, save_fig, set_display; kwargs...)
end

"""
     stack_plot(results::IS.Results, variables::Array)

This function plots a stack plot for the generators in each variable within
the results variables dictionary, and makes a stack plot for all of the variables in the array.

# Arguments
- `res::IS.Results = results`: results to be plotted
- `variables::Array`: list of variables to be plotted in the results

# Examples

```julia
results = solve_op_problem!(OpProblem)
variables = [:var1, :var2, :var3]
stack_plot(results, variables)
```

# Accepted Key Words
- `display::Bool`: set to false to prevent the plots from displaying
- `save::String = "file_path"`: set a file path to save the plots
- `seriescolor::Array`: Set different colors for the plots
- `reserves::Bool`: if reserves = true, the researves will be plotted with the active power
- `title::String = "Title"`: Set a title for the plots
"""

function stack_plot(res::IS.Results, variables::Array; kwargs...)
    res_var = Dict()
    for variable in variables
        res_var[variable] = IS.get_variables(res)[variable]
    end
    results = Results(
        IS.get_base_power(res),
        res_var,
        IS.get_optimizer_log(res),
        IS.get_total_cost(res),
        IS.get_time_stamp(res),
        res.dual_values,
        res.parameter_values,
    )
    return stack_plot(results; kwargs...)
end

function stack_plot(results::Array, variables::Array; kwargs...)
    new_results = []
    for res in results
        res_var = Dict()
        for variable in variables
            res_var[variable] = IS.get_variables(res)[variable]
        end
        results = Results(
            IS.get_base_power(res),
            res_var,
            IS.get_optimizer_log(res),
            IS.get_total_cost(res),
            IS.get_time_stamp(res),
            res.dual_values,
            res.parameter_values,
        )
        new_results = vcat(new_results, results)
    end
    return stack_plot(new_results; kwargs...)
end

function _make_ylabel(base_power::Float64)
    if isapprox(base_power, 1)
        ylabel = "Generation (MW)"
    elseif isapprox(base_power, 100)
        ylabel = "Generation (GW)"
    else
        ylabel = "Generation (MW x$base_power)"
    end
    return ylabel
end

function stair_plot(res::IS.Results; kwargs...)
    set_display = get(kwargs, :set_display, true)
    backend = Plots.backend()
    save_fig = get(kwargs, :save, nothing)
    res = _filter_variables(res; kwargs...)
    if isnothing(backend)
        throw(IS.ConflictingInputsError("No backend detected. Type gr() to set a backend."))
    end
    return _stack_plot_internal(
        res,
        backend,
        save_fig,
        set_display;
        stairs = "hv",
        linetype = :steppost,
        kwargs...,
    )
end

function stair_plot(results::Array; kwargs...)
    set_display = get(kwargs, :set_display, true)
    backend = Plots.backend()
    save_fig = get(kwargs, :save, nothing)
    new_results = _filter_variables(results[1]; kwargs...)
    for res in 2:length(results)
        filtered = _filter_variables(results[res]; kwargs...)
        new_results = hcat(new_results, filtered)
    end
    if isnothing(backend)
        throw(IS.ConflictingInputsError("No backend detected. Type gr() to set a backend."))
    end
    return _stack_plot_internal(
        new_results,
        backend,
        save_fig,
        set_display;
        stairs = "hv",
        linetype = :steppost,
        kwargs...,
    )
end

function stair_plot(res::IS.Results, variables::Array; kwargs...)
    res_var = Dict()
    for variable in variables
        res_var[variable] = IS.get_variables(res)[variable]
    end
    results = Results(
        IS.get_base_power(res),
        res_var,
        IS.get_optimizer_log(res),
        IS.get_total_cost(res),
        IS.get_time_stamp(res),
        res.dual_values,
        res.parameter_values,
    )
    return stair_plot(results; kwargs...)
end

function stair_plot(results::Array, variables::Array; kwargs...)
    new_results = []
    for res in results
        res_var = Dict()
        for variable in variables
            res_var[variable] = IS.get_variables(res)[variable]
        end
        results = Results(
            IS.get_base_power(res),
            res_var,
            IS.get_optimizer_log(res),
            IS.get_total_cost(res),
            IS.get_time_stamp(res),
            res.dual_values,
            res.parameter_values,
        )
        new_results = vcat(new_results, results)
    end
    return stair_plot(new_results; kwargs...)
end
################################### DEMAND #################################

function _shorten_time(results::IS.Results, horizon::Int64, init_time::Dates.DateTime)
    time_range = IS.get_time_stamp(results)[:, 1]
    resolution = Dates.Hour(time_range[2] - time_range[1])
    parameters = IS.get_parameters(results)
    times = [init_time:resolution:init_time + resolution*horizon]
    new_time_range = DataFrames.DataFrame(:Range => vcat(times...))
    new_params = Dict()
    init_spot = findall(x->x==init_time, time_range)[1]
    if isempty(init_spot)
        @warn "$init_time is not in the time_range."
    end
    for (k, p) in parameters
        new_params[k] = p[init_spot:(init_spot+horizon), :]
    end
    return Results(
        IS.get_base_power(results),
        IS.get_variables(results),
        IS.get_optimizer_log(results),
        IS.get_total_cost(results),
        new_time_range,
        results.dual_values,
        new_params,
    )
end

function demand_plot(res::IS.Results; kwargs...)
    results = _filter_parameters(res)
    if isempty(IS.get_parameters(results))
        @warn "No parameters provided."
    end
    backend = Plots.backend()
    horizon = get(kwargs, :horizon, nothing)
    initial_time = get(kwargs, :initial_time, nothing)
    if !isnothing(horizon) && !isnothing(initial_time)
        results = _shorten_time(results, horizon, initial_time)
    end
    return _demand_plot_internal(results, backend; kwargs...)
end

function demand_plot(results::Array; kwargs...)
    newer_results = []
    for res in results
        new_res = _filter_parameters(res)
        horizon = get(kwargs, :horizon, nothing)
        initial_time = get(kwargs, :initial_time, nothing)
        if !isnothing(horizon) && !isnothing(initial_time)
            new_res = _shorten_time(new_res, horizon, initial_time)
        end
        newer_results = vcat(newer_results, new_res)
        if isempty(IS.get_parameters(new_res))
            @warn "No parameters provided."
        end

    end
    backend = Plots.backend()
    save_fig = get(kwargs, :save, nothing)
    return _demand_plot_internal(newer_results, backend; kwargs...)
end

function make_demand_plot_data(system::PSY.System; kwargs...)
    names = collect(PSY.get_name.(PSY.get_components(PSY.PowerLoad, system)))
    component = PSY.get_component(PSY.PowerLoad, system, names[1])
    forecast_key = collect(PSY.get_forecast_keys(component))[1]
    initial_time = get(kwargs, :initial_time, forecast_key.initial_time)
    horizon = get(kwargs, :horizon, PSY.get_forecasts_horizon(system)-1)+1
    f = PSY.get_forecast(
        PSY.Deterministic,
        component,
        initial_time,
        forecast_key.label,
        horizon,
    )
    parameters = DataFrames.rename(
        DataFrames.DataFrame(PSY.get_forecast_values(component, f)),
        :A => Symbol(names[1]),
    )
    for i in 2:length(names)
        component = PSY.get_component(PSY.PowerLoad, system, names[i])
        forecast_key = collect(PSY.get_forecast_keys(component))[1]
        f = PSY.get_forecast(
            PSY.Deterministic,
            component,
            initial_time,
            forecast_key.label,
            horizon,
        )
        df = DataFrames.DataFrame(PSY.get_forecast_values(component, f))
        parameters[!, Symbol(names[i])] = df[:, 2]
    end
    save_fig = get(kwargs, :save, nothing)
    return parameters
end

function demand_plot(system::PSY.System; kwargs...)
    parameters = make_demand_plot_data(system; kwargs...)
    backend = Plots.backend()
    return _demand_plot_internal(parameters, system.basepower, Plots.backend(); kwargs...)
end

function demand_plot(systems::Array{PSY.System}; kwargs...)
    parameter_list = []
    basepowers = []
    for system in systems
        push!(basepowers, system.basepower)
        push!(parameter_list, make_demand_plot_data(system; kwargs...))
    end
    backend = Plots.backend()
    return _demand_plot_internal(parameter_list, basepowers, backend; kwargs...)
end
