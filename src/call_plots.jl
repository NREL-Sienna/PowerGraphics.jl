function _filter_variables(results::IS.Results; kwargs...)
    filter_results = Dict()
    reserves = get(kwargs, :reserves, false)
    if reserves
        for (key, var) in IS.get_variables(results)
            start = split("$key", "_")[1]
            if in(start, VARIABLE_TYPES)
                filter_results[key] = var
            end
        end
    else
        for (key, var) in IS.get_variables(results)
            start = split("$key", "_")[1]
            if start == "P"
                filter_results[key] = var
            end
        end
    end
    results = Results(
        IS.get_base_power(results),
        filter_results,
        IS.get_optimizer_log(results),
        IS.get_total_cost(results),
        IS.get_time_stamp(results),
        results.dual_values,
        results.parameter_values,
    )
    return results
end

function fuel_plot(res::IS.Results, variables::Array, generator_dict::Dict; kwargs...)
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
    fuel_plot(results, generator_dict; kwargs...)
end

function fuel_plot(res::IS.Results, variables::Array, system::PSY.System; kwargs...)
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
    fuel_plot(results, system; kwargs...)
end

function fuel_plot(results::Array, variables::Array, system::PSY.System; kwargs...)
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
    fuel_plot(new_results, system; kwargs...)
end

function fuel_plot(results::Array, variables::Array, generator_dict::Dict; kwargs...)
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
    fuel_plot(new_results, generator_dict; kwargs...)
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
"""
function fuel_plot(res::IS.Results, sys::PSY.System; kwargs...)
    ref = make_fuel_dictionary(res, sys)
    fuel_plot(res, ref; kwargs...)
end

function fuel_plot(res::Array, sys::PSY.System; kwargs...)
    ref = make_fuel_dictionary(res[1], sys)
    fuel_plot(res, ref; kwargs...)
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
generator_dict = make_fuel_dictionary(res, sys)
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
    title = get(kwargs, :title, " ")
    if isnothing(backend)
        throw(IS.ConflictingInputsError("No backend detected. Type gr() to set a backend."))
    end
    _fuel_plot_internal(
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
    new_res = _filter_variables(results[1]; kwargs...)
    stack = get_stacked_aggregation_data(new_res, generator_dict)
    bar = get_bar_aggregation_data(new_res, generator_dict)
    for i in 2:length(results)
        new_res = _filter_variables(results[i]; kwargs...)
        stack = hcat(stack, get_stacked_aggregation_data(new_res, generator_dict))
        bar = hcat(bar, get_bar_aggregation_data(new_res, generator_dict))
    end
    backend = Plots.backend()
    default_colors = match_fuel_colors(stack[1], bar[1], backend, FUEL_DEFAULT)
    seriescolor = get(kwargs, :seriescolor, default_colors)
    title = get(kwargs, :title, " ")
    ylabel = _make_ylabel(IS.get_base_power(results[1]))
    if isnothing(backend)
        throw(IS.ConflictingInputsError("No backend detected. Type gr() to set a backend."))
    end
    _fuel_plot_internal(
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

function _fuel_plot_internal(
    stack::Any,
    bar::Any,
    seriescolor::Array,
    backend::Plots.PlotlyJSBackend,
    save_fig::Any,
    set_display::Bool,
    title::String,
    ylabel::String;
    kwargs...,
)
    title = get(kwargs, :title, "Fuel")
    plotly_stack_gen(stack, seriescolor, "$(title)_Stack", ylabel; kwargs...)
    plotly_bar_gen(bar, seriescolor, "$(title)_Bar", ylabel; kwargs...)
end

function _fuel_plot_internal(
    stack::Any,
    bar::Any,
    seriescolor::Array,
    backend::Any,
    save_fig::Any,
    set_display::Bool,
    title::String,
    ylabel::String;
    kwargs...,
)
    title = get(kwargs, :title, "Fuel")
    p1 = RecipesBase.plot(stack, seriescolor; title = title, ylabel = ylabel)
    p2 = RecipesBase.plot(bar, seriescolor; title = title, ylabel = ylabel)
    set_display && display(p1)
    set_display && display(p2)
    if !isnothing(save_fig)
        title = replace(title, " " => "_")
        Plots.savefig(p1, joinpath(save_fig, "$(title)_Stack.png"))
        Plots.savefig(p2, joinpath(save_fig, "$(title)_Bar.png"))
    end
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
    bar_gen = get_bar_gen_data(res)
    if isnothing(backend)
        throw(IS.ConflictingInputsError("No backend detected. Type gr() to set a backend."))
    end
    _bar_plot_internal(res, bar_gen, backend, save_fig, set_display; kwargs...)
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
    bar_gen = get_bar_gen_data(res)
    for i in 2:size(results, 1)
        filter = _filter_variables(results[i]; kwargs...)
        res = hcat(res, filter)
        bar_gen = hcat(bar_gen, get_bar_gen_data(filter))
    end
    if isnothing(backend)
        throw(IS.ConflictingInputsError("No backend detected. Type gr() to set a backend."))
    end
    _bar_plot_internal(res, bar_gen, backend, save_fig, set_display; kwargs...)
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
    bar_plot(results; kwargs...)
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
    bar_plot(new_results; kwargs...)
end

function _bar_plot_internal(
    res::IS.Results,
    bar_gen::BarGeneration,
    backend::Plots.PlotlyJSBackend,
    save_fig::Any,
    set_display::Bool;
    kwargs...,
)
    seriescolor = get(kwargs, :seriescolor, PLOTLY_DEFAULT)
    title = get(kwargs, :title, " ")
    ylabel = _make_ylabel(IS.get_base_power(res))
    plotly_bar_plots(res, seriescolor, ylabel; kwargs...)
    plotly_bar_gen(bar_gen, seriescolor, title, ylabel; kwargs...)
end

function _bar_plot_internal(
    res::Array,
    bar_gen::Array,
    backend::Plots.PlotlyJSBackend,
    save_fig::Any,
    set_display::Bool;
    kwargs...,
)
    seriescolor = get(kwargs, :seriescolor, PLOTLY_DEFAULT)
    title = get(kwargs, :title, " ")
    ylabel = _make_ylabel(IS.get_base_power(res[1]))
    plotly_bar_plots(res, seriescolor, ylabel; kwargs...)
    plotly_bar_gen(bar_gen, seriescolor, title, ylabel; kwargs...)
end

function _bar_plot_internal(
    res::IS.Results,
    bar_gen::BarGeneration,
    backend::Any,
    save_fig::Any,
    set_display::Bool;
    kwargs...,
)
    seriescolor = get(kwargs, :seriescolor, GR_DEFAULT)
    ylabel = _make_ylabel(IS.get_base_power(res))
    title = get(kwargs, :title, " ")
    for name in string.(keys(IS.get_variables(res)))
        variable_bar = get_bar_plot_data(res, name)
        p = RecipesBase.plot(variable_bar, name, seriescolor; ylabel = ylabel)
        set_display && display(p)
        if !isnothing(save_fig)
            Plots.savefig(p, joinpath(save_fig, "$(name)_Bar.png"))
        end
    end
    p2 = RecipesBase.plot(bar_gen, seriescolor; title = title, ylabel = ylabel)
    set_display && display(p2)
    if !isnothing(save_fig)
        if title == " "
            title = "Bar_Generation"
        end
        title = replace(title, " " => "_")
        Plots.savefig(p2, joinpath(save_fig, "$title.png"))
    end
end

function _bar_plot_internal(
    results::Array,
    bar_gen::Array,
    backend::Any,
    save_fig::Any,
    set_display::Bool;
    kwargs...,
)
    seriescolor = get(kwargs, :seriescolor, GR_DEFAULT)
    title = get(kwargs, :title, " ")
    ylabel = _make_ylabel(IS.get_base_power(results[1]))
    for name in string.(keys(IS.get_variables(results[1, 1])))
        variable_bar = get_bar_plot_data(results[1, 1], name)
        for i in 2:length(results)
            variable_bar = hcat(variable_bar, get_bar_plot_data(results[i], name))
        end
        p = RecipesBase.plot(variable_bar, name, seriescolor; ylabel = ylabel)
        set_display && display(p)
        if !isnothing(save_fig)
            Plots.savefig(p, joinpath(save_fig, "$(name)_Bar.png"))
        end
    end
    p2 = RecipesBase.plot(bar_gen, seriescolor; title = title, ylabel = ylabel)
    set_display && display(p2)
    if !isnothing(save_fig)
        if title == " "
            title = "Bar_Generation"
        end
        title = replace(title, " " => "_")
        Plots.savefig(p2, joinpath(save_fig, "$title.png"))
    end
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
    _filter_variables(res; kwargs...)
    stacked_gen = get_stacked_generation_data(res)
    if isnothing(backend)
        throw(IS.ConflictingInputsError("No backend detected. Type gr() to set a backend."))
    end
    _stack_plot_internal(res, stacked_gen, backend, save_fig, set_display; kwargs...)
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
    stacked_gen = get_stacked_generation_data(new_results)
    for res in 2:length(results)
        filtered = _filter_variables(results[res]; kwargs...)
        new_results = hcat(new_results, filtered)
        stacked_gen = hcat(stacked_gen, get_stacked_generation_data(filtered))
    end
    if isnothing(backend)
        throw(IS.ConflictingInputsError("No backend detected. Type gr() to set a backend."))
    end
    _stack_plot_internal(
        new_results,
        stacked_gen,
        backend,
        save_fig,
        set_display;
        kwargs...,
    )
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
    stack_plot(results; kwargs...)
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
    stack_plot(new_results; kwargs...)
end

function _stack_plot_internal(
    res::IS.Results,
    stack::StackedGeneration,
    backend::Plots.PlotlyJSBackend,
    save_fig::Any,
    set_display::Bool;
    kwargs...,
)
    seriescolor = get(kwargs, :seriescolor, PLOTLY_DEFAULT)
    title = get(kwargs, :title, " ")
    ylabel = _make_ylabel(IS.get_base_power(res))
    plotly_stack_plots(res, seriescolor, ylabel; kwargs...)
    plotly_stack_gen(stack, seriescolor, title, ylabel; kwargs...)
end

function _stack_plot_internal(
    res::Array{},
    stack::Array{},
    backend::Plots.PlotlyJSBackend,
    save_fig::Any,
    set_display::Bool;
    kwargs...,
)
    seriescolor = get(kwargs, :seriescolor, PLOTLY_DEFAULT)
    title = get(kwargs, :title, " ")
    ylabel = _make_ylabel(IS.get_base_power(res[1]))
    plotly_stack_plots(res, seriescolor, ylabel; kwargs...)
    plotly_stack_gen(stack, seriescolor, title, ylabel; kwargs...)
end

function _stack_plot_internal(
    res::IS.Results,
    stack::StackedGeneration,
    backend::Any,
    save_fig::Any,
    set_display::Bool;
    kwargs...,
)
    title = get(kwargs, :title, " ")
    ylabel = _make_ylabel(IS.get_base_power(res))
    seriescolor = get(kwargs, :seriescolor, GR_DEFAULT)
    for name in string.(keys(IS.get_variables(res)))
        variable_stack = get_stacked_plot_data(res, name)
        p = RecipesBase.plot(variable_stack, name, seriescolor; ylabel = ylabel)
        set_display && display(p)
        if !isnothing(save_fig)
            Plots.savefig(p, joinpath(save_fig, "$(name)_Stack.png"))
        end
    end
    p2 = RecipesBase.plot(stack, seriescolor; title = title, ylabel = ylabel)
    set_display && display(p2)
    if !isnothing(save_fig)
        if title == " "
            title = "Stack_Generation"
        end
        title = replace(title, " " => "_")
        Plots.savefig(p2, joinpath(save_fig, "$title.png"))
    end
end

function _stack_plot_internal(
    results::Any,
    stack::Any,
    backend::Any,
    save_fig::Any,
    set_display::Bool;
    kwargs...,
)
    seriescolor = get(kwargs, :seriescolor, GR_DEFAULT)
    title = get(kwargs, :title, " ")
    ylabel = _make_ylabel(IS.get_base_power(results[1]))
    for name in string.(keys(IS.get_variables(results[1])))
        variable_stack = get_stacked_plot_data(results[1], name)
        for res in 2:length(results)
            variable_stack = hcat(variable_stack, get_stacked_plot_data(results[res], name))
        end
        p = RecipesBase.plot(variable_stack, name, seriescolor; ylabel = ylabel)
        set_display && display(p)
        if !isnothing(save_fig)
            Plots.savefig(p, joinpath(save_fig, "$(name)_Stack.png"))
        end
    end
    p2 = RecipesBase.plot(stack, seriescolor; title = title, ylabel = ylabel)
    set_display && display(p2)
    if !isnothing(save_fig)
        if title == " "
            title = "Stack_Generation"
        end
        title = replace(title, " " => "_")
        Plots.savefig(p2, joinpath(save_fig, "$title.png"))
    end
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
