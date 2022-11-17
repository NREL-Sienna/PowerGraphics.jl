function _empty_plot()
    backend = Plots.backend()
    return _empty_plot(backend)
end

function popkwargs(kwargs, kwarg)
    return Dict{Symbol, Any}((k, v) for (k, v) in kwargs if k ≠ kwarg)
end

function _make_ylabel(
    base_power::Float64;
    variable::String = "Generation",
    time::String = "",
)
    if isapprox(base_power, 1.0)
        ylabel = "$variable (MW$time)"
    elseif isapprox(base_power, 1000.0)
        ylabel = "$variable (GW$time)"
    else
        ylabel = "$variable (MW$time x$base_power)"
    end
    return ylabel
end

function get_default_seriescolor()
    backend = Plots.backend()
    return get_default_seriescolor(backend)
end

function get_default_seriescolor(backend)
    return GR_DEFAULT
end

function get_default_seriescolor(backend::Plots.PlotlyJSBackend)
    return PLOTLY_DEFAULT
end
################################### DEMAND #################################

"""
    plot_demand(results)
    plot_demand(system)

This function makes a plot of the demand in the system.

# Arguments

- `res::Union{Results, Vector{IS.Results}}`: results to be plotted

# Example

```julia
res = PowerSimulations.solve_op_problem!(OpProblem)
plot = plot_demand(res)
```

# Accepted Key Words

- `linestyle::Symbol = :dash` : set line style
- `title::String`: Set a title for the plots
- `horizon::Int64`: To plot a shorter window of time than the full results
- `initial_time::DateTime`: To start the plot at a different time other than the results initial time
- `aggregate::String = "System", "PowerLoad", or "Bus"`: aggregate the demand other than by generator
- `set_display::Bool = true`: set to false to prevent the plots from displaying
- `save::String = "file_path"`: set a file path to save the plots
- `format::String = "png"`: set a different format for saving a PlotlyJS plot
- `seriescolor::Array`: Set different colors for the plots
- `title::String = "Title"`: Set a title for the plots
- `stack::Bool = true`: stack plot traces
- `bar::Bool` : create bar plot
- `nofill::Bool` : force empty area fill
- `stair::Bool`: Make a stair plot instead of a stack plot
- `filter_func::Function = PowerSystems.get_available` : filter components included in plot
"""

function plot_demand(result::Union{IS.Results, PSY.System}; kwargs...)
    return plot_demand!(_empty_plot(), result; kwargs...)
end

"""
    plot_demand!(plot, results)
    plot_demand!(plot, system)

This function makes a plot of the demand in the system.

# Arguments

- `plot` : existing plot handle
- `result::Union{IS.Results, PSY.System}` : simulation results or PowerSystems.System

# Accepted Key Words

- `linestyle::Symbol = :dash` : set line style
- `title::String`: Set a title for the plots
- `horizon::Int64`: To plot a shorter window of time than the full results
- `initial_time::DateTime`: To start the plot at a different time other than the results initial time
- `aggregate::String = "System", "PowerLoad", or "Bus"`: aggregate the demand other than by generator
- `set_display::Bool = true`: set to false to prevent the plots from displaying
- `save::String = "file_path"`: set a file path to save the plots
- `format::String = "png"`: set a different format for saving a PlotlyJS plot
- `seriescolor::Array`: Set different colors for the plots
- `title::String = "Title"`: Set a title for the plots
- `stack::Bool = true`: stack plot traces
- `bar::Bool` : create bar plot
- `nofill::Bool` : force empty area fill
- `stair::Bool`: Make a stair plot instead of a stack plot
- `filter_func::Function = PowerSystems.get_available` : filter components included in plot
"""
function plot_demand!(p, result::Union{IS.Results, PSY.System}; kwargs...)
    backend = Plots.backend()
    set_display = get(kwargs, :set_display, true)
    save_fig = get(kwargs, :save, nothing)
    bar = get(kwargs, :bar, false)
    linestyle = get(kwargs, :linestyle, :solid)

    title = get(kwargs, :title, "Demand")
    y_label = get(kwargs, :y_label, bar ? "MWh" : "MW")

    load = PA.get_load_data(result; kwargs...)
    kwargs = popkwargs(kwargs, :filter_func)
    load_agg = PA.combine_categories(load.data)

    if isnothing(load_agg)
        Throw(error("No load data found"))
    end

    p = plot_dataframe!(
        p,
        load_agg,
        load.time;
        seriescolor = get(kwargs, :seriescolor, get_default_seriescolor()),
        linestyle = Symbol(linestyle),
        line_dash = string(linestyle),
        linewidth = get(kwargs, :linewidth, 1),
        y_label = y_label,
        set_display = false,
        title = title,
        kwargs...,
    )

    if set_display
        if backend == Plots.PlotlyJSBackend()
            display(Plots.PlotlyJS.plot(p))
        else
            display(p)
        end
    end
    if !isnothing(save_fig)
        title = replace(title, " " => "_")
        save_plot(p, joinpath(save_fig, "$(title).png"), backend; kwargs...)
    end
    return p
end

################################# Plotting a Single DataFrame ##########################

"""
    plot_dataframe(df)
    plot_dataframe(df, time_range)

Plots data from DataFrame where each row represents a time period and each column represents a trace

# Arguments

- `df::DataFrames.DataFrame`: DataFrame where each row represents a time period and each column represents a trace.
If only the dataframe is provided, it must have a column of `DateTime` values.
- `time_range:::Union{DataFrames.DataFrame, Array, StepRange}`: The time periods of the data

# Example

```julia
var_name = :P__ThermalStandard
df = PowerSimulations.read_variables_with_keys(results, names = [var_name])[var_name]
time_range = PowerSimulations.get_realized_timestamps(results)
plot = plot_dataframe(df, time_range)
```

# Accepted Key Words
- `curtailment::Bool`: plot the curtailment with the variable
- `set_display::Bool = true`: set to false to prevent the plots from displaying
- `save::String = "file_path"`: set a file path to save the plots
- `format::String = "png"`: set a different format for saving a PlotlyJS plot
- `seriescolor::Array`: Set different colors for the plots
- `title::String = "Title"`: Set a title for the plots
- `stack::Bool = true`: stack plot traces
- `bar::Bool` : create bar plot
- `nofill::Bool` : force empty area fill
- `stair::Bool`: Make a stair plot instead of a stack plot
"""

function plot_dataframe(df::DataFrames.DataFrame; kwargs...)
    return plot_dataframe!(_empty_plot(), PA.no_datetime(df), df.DateTime; kwargs...)
end
function plot_dataframe(
    df::DataFrames.DataFrame,
    time_range::Union{DataFrames.DataFrame, Array, StepRange};
    kwargs...,
)
    return plot_dataframe!(_empty_plot(), df, time_range; kwargs...)
end

"""
    plot_dataframe!(plot, df)
    plot_dataframe!(plot, df, time_range)

Plots data from DataFrame where each row represents a time period and each column represents a trace

# Arguments

- `plot`: existing plot handle
- `df::DataFrames.DataFrame`: DataFrame where each row represents a time period and each column represents a trace.
If only the dataframe is provided, it must have a column of `DateTime` values.
- `time_range:::Union{DataFrames.DataFrame, Array, StepRange}`: The time periods of the data

# Accepted Key Words
- `curtailment::Bool`: plot the curtailment with the variable
- `set_display::Bool = true`: set to false to prevent the plots from displaying
- `save::String = "file_path"`: set a file path to save the plots
- `format::String = "png"`: set a different format for saving a PlotlyJS plot
- `seriescolor::Array`: Set different colors for the plots
- `title::String = "Title"`: Set a title for the plots
- `stack::Bool = true`: stack plot traces
- `bar::Bool` : create bar plot
- `nofill::Bool` : force empty area fill
- `stair::Bool`: Make a stair plot instead of a stack plot
"""

function plot_dataframe!(p, df::DataFrames.DataFrame; kwargs...)
    return plot_dataframe!(p, PA.no_datetime(df), df.DateTime; kwargs...)
end

function plot_dataframe!(
    p,
    variable::DataFrames.DataFrame,
    time_range::Union{DataFrames.DataFrame, Array, StepRange};
    kwargs...,
)
    time_range =
        typeof(time_range) == DataFrames.DataFrame ? time_range[:, 1] : collect(time_range)
    backend = Plots.backend()
    p = _dataframe_plots_internal(p, variable, time_range, backend; kwargs...)
    return p
end

################################# Plotting PowerData ##########################

"""
    plot_powerdata(powerdata)

This function makes a plot of a PGdata object

# Arguments

- `powerdata::PowerData`: The dataframe to be plotted

# Accepted Key Words
- `combine_categories::Bool = false` : plot category values or each value in a category
- `curtailment::Bool`: plot the curtailment with the variable
- `set_display::Bool = true`: set to false to prevent the plots from displaying
- `save::String = "file_path"`: set a file path to save the plots
- `format::String = "png"`: set a different format for saving a PlotlyJS plot
- `seriescolor::Array`: Set different colors for the plots
- `title::String = "Title"`: Set a title for the plots
- `stack::Bool = true`: stack plot traces
- `bar::Bool` : create bar plot
- `nofill::Bool` : force empty area fill
- `stair::Bool`: Make a stair plot instead of a stack plot
"""
function plot_powerdata(powerdata::PA.PowerData; kwargs...)
    return plot_powerdata!(_empty_plot(), powerdata; kwargs...)
end

"""
    plot_powerdata!(plot, powerdata)

This function makes a plot of a PGdata object

# Arguments

- `plot` : existing plot handle (optional)
- `powerdata::PowerData`: The dataframe to be plotted

# Accepted Key Words
- `combine_categories::Bool = false` : plot category values or each value in a category
- `curtailment::Bool`: plot the curtailment with the variable
- `set_display::Bool = true`: set to false to prevent the plots from displaying
- `save::String = "file_path"`: set a file path to save the plots
- `format::String = "png"`: set a different format for saving a PlotlyJS plot
- `seriescolor::Array`: Set different colors for the plots
- `title::String = "Title"`: Set a title for the plots
- `stack::Bool = true`: stack plot traces
- `bar::Bool` : create bar plot
- `nofill::Bool` : force empty area fill
- `stair::Bool`: Make a stair plot instead of a stack plot
"""
function plot_powerdata!(p, powerdata::PA.PowerData; kwargs...)
    backend = Plots.backend()
    title = get(kwargs, :title, "")
    set_display = get(kwargs, :set_display, true)
    save_fig = get(kwargs, :save, nothing)

    if get(kwargs, :combine_categories, true)
        aggregate = get(kwargs, :aggregate, nothing)
        names = get(kwargs, :names, nothing)
        data = PA.combine_categories(powerdata.data; names = names, aggregate = aggregate)
    else
        data = powerdata.data
    end
    kwargs =
        Dict{Symbol, Any}((k, v) for (k, v) in kwargs if k ∉ [:title, :save, :set_display])

    p = plot_dataframe!(p, data, powerdata.time; set_display = false, kwargs...)

    if set_display
        if backend == Plots.PlotlyJSBackend()
            display(Plots.PlotlyJS.plot(p))
        else
            display(p)
        end
    end
    if !isnothing(save_fig)
        title = replace(title, " " => "_")
        format = get(kwargs, :format, "png")
        save_plot(p, joinpath(save_fig, "$title.$format"), backend; kwargs...)
    end
    return p
end

"""
    plot_results(results)

This function makes a plot of a results dictionary object

# Arguments

- `results::Dict{String, DataFrame`: The results to be plotted

# Accepted Key Words
- `combine_categories::Bool = false` : plot category values or each value in a category
- `curtailment::Bool`: plot the curtailment with the variable
- `set_display::Bool = true`: set to false to prevent the plots from displaying
- `save::String = "file_path"`: set a file path to save the plots
- `format::String = "png"`: set a different format for saving a PlotlyJS plot
- `seriescolor::Array`: Set different colors for the plots
- `title::String = "Title"`: Set a title for the plots
- `stack::Bool = true`: stack plot traces
- `bar::Bool` : create bar plot
- `nofill::Bool` : force empty area fill
- `stair::Bool`: Make a stair plot instead of a stack plot
"""
function plot_results(results::Dict{String, DataFrames.DataFrame}; kwargs...)
    return plot_powerdata!(_empty_plot(), PA.PowerData(results); kwargs...)
end

"""
    plot_results!(plot, results)

This function makes a plot of a results dictionary

# Arguments

- `plot` : existing plot handle (optional)
- `results::Dict{String, DataFrame}`: The results to be plotted

# Accepted Key Words
- `combine_categories::Bool = false` : plot category values or each value in a category
- `curtailment::Bool`: plot the curtailment with the variable
- `set_display::Bool = true`: set to false to prevent the plots from displaying
- `save::String = "file_path"`: set a file path to save the plots
- `format::String = "png"`: set a different format for saving a PlotlyJS plot
- `seriescolor::Array`: Set different colors for the plots
- `title::String = "Title"`: Set a title for the plots
- `stack::Bool = true`: stack plot traces
- `bar::Bool` : create bar plot
- `nofill::Bool` : force empty area fill
- `stair::Bool`: Make a stair plot instead of a stack plot
"""
function plot_results!(p, results::Dict{String, DataFrames.DataFrame}; kwargs...)
    return plot_powerdata!(p, PA.PowerData(results); kwargs...)
    return p
end

################################# Plotting Fuel Plot of Results ##########################
"""
    plot_fuel(results)

This function makes a stack plot of the results by fuel type
and assigns each fuel type a specific color.

# Arguments

- `res::PowerSimulations.Results` : results to be plotted

# Example

```julia
res = solve_op_problem!(OpProblem)
plot = plot_fuel(res)
```

# Accepted Key Words
- `generator_mapping_file` = "file_path" : file path to yaml definig generator category by fuel and primemover
- `variables::Union{Nothing, Vector{Symbol}}` = nothing : specific variables to plot
- `slacks::Bool = true` : display slack variables
- `load::Bool = true` : display load line
- `curtailment::Bool = true`: To plot the curtailment in the stack plot
- `set_display::Bool = true`: set to false to prevent the plots from displaying
- `save::String = "file_path"`: set a file path to save the plots
- `format::String = "png"`: set a different format for saving a PlotlyJS plot
- `seriescolor::Array`: Set different colors for the plots
- `title::String = "Title"`: Set a title for the plots
- `stack::Bool = true`: stack plot traces
- `bar::Bool` : create bar plot
- `nofill::Bool` : force empty area fill
- `stair::Bool`: Make a stair plot instead of a stack plot
- `filter_func::Function = PowerSystems.get_available` : filter components included in plot
"""

function plot_fuel(result::IS.Results; kwargs...)
    return plot_fuel!(_empty_plot(), result; kwargs...)
end

"""
    plot_fuel!(plot, results)

This function makes a stack plot of the results by fuel type
and assigns each fuel type a specific color.

# Arguments

- `plot` : existing plot handle (optional)
- `res::PowerSimulations.Results` : results to be plotted

# Accepted Key Words
- `generator_mapping_file` = "file_path" : file path to yaml definig generator category by fuel and primemover
- `variables::Union{Nothing, Vector{Symbol}}` = nothing : specific variables to plot
- `slacks::Bool = true` : display slack variables
- `load::Bool = true` : display load line
- `curtailment::Bool = true`: To plot the curtailment in the stack plot
- `set_display::Bool = true`: set to false to prevent the plots from displaying
- `save::String = "file_path"`: set a file path to save the plots
- `format::String = "png"`: set a different format for saving a PlotlyJS plot
- `seriescolor::Array`: Set different colors for the plots
- `title::String = "Title"`: Set a title for the plots
- `stack::Bool = true`: stack plot traces
- `bar::Bool` : create bar plot
- `nofill::Bool` : force empty area fill
- `stair::Bool`: Make a stair plot instead of a stack plot
- `filter_func::Function = PowerSystems.get_available` : filter components included in plot
"""
function plot_fuel!(p, result::IS.Results; kwargs...)
    backend = Plots.backend()
    set_display = get(kwargs, :set_display, true)
    save_fig = get(kwargs, :save, nothing)
    curtailment = get(kwargs, :curtailment, true)
    slacks = get(kwargs, :slacks, true)
    load = get(kwargs, :load, true)
    title = get(kwargs, :title, "Fuel")
    stack = get(kwargs, :stack, true)
    bar = get(kwargs, :bar, false)
    kwargs =
        Dict{Symbol, Any}((k, v) for (k, v) in kwargs if k ∉ [:title, :save, :set_display])

    # Generation stack
    gen = PA.get_generation_data(result; kwargs...)
    sys = PA.PSI.get_system(result)
    if sys === nothing
        Throw(error("No System data present: please run `set_system!(results, sys)`"))
    end
    cat = PA.make_fuel_dictionary(sys; kwargs...)
    fuel = PA.categorize_data(gen.data, cat; curtailment = curtailment, slacks = slacks)

    filter_func = get(kwargs, :filter_func, PSY.get_available)
    kwargs = popkwargs(kwargs, :filter_func)

    # passing names here enforces order
    # TODO: enable custom sort with kwarg
    fuel_agg = PA.combine_categories(fuel; names = intersect(CATEGORY_DEFAULT, keys(fuel)))
    y_label = get(kwargs, :y_label, bar ? "MWh" : "MW")

    seriescolor = get(kwargs, :seriescolor, match_fuel_colors(fuel_agg, backend))
    p = plot_dataframe!(
        p,
        fuel_agg,
        gen.time;
        stack = stack,
        seriescolor = seriescolor,
        y_label = y_label,
        title = title,
        set_display = false,
        kwargs...,
    )

    kwargs = popkwargs(popkwargs(kwargs, :nofill), :seriescolor)

    kwargs[:linestyle] = get(kwargs, :linestyle, :dash)
    kwargs[:linewidth] = get(kwargs, :linewidth, 3)
    kwargs[:filter_func] = filter_func

    if load
        # load line
        p = plot_demand!(
            p,
            result;
            nofill = true,
            title = title,
            y_label = y_label,
            set_display = false,
            stack = stack,
            seriescolor = ["black"],
            kwargs...,
        )
    end

    # service stack
    # TODO: how to display this?

    if set_display
        if backend == Plots.PlotlyJSBackend()
            display(Plots.PlotlyJS.plot(p))
        else
            display(p)
        end
    end
    if !isnothing(save_fig)
        title = replace(title, " " => "_")
        format = get(kwargs, :format, "png")
        save_plot(p, joinpath(save_fig, "$title.$format"), backend; kwargs...)
    end
    return p
end

"""
    save_plot(plot, filename)

Saves plot to specified filename

# Arguments

- `plot`: plot object
- `filename::String` : save to filename

# Example

```julia
res = solve_op_problem!(OpProblem)
plot = plot_fuel(res)
save_plot(plot, "my_plot.png")
```

# Accepted Key Words (currently only implemented for PlotlyJS backend)
- `width::Union{Nothing,Int}=nothing`
- `height::Union{Nothing,Int}=nothing`
- `scale::Union{Nothing,Real}=nothing`
"""
function save_plot(plot, filename::String; kwargs...) # this needs to be typed but Plots.PlotlyJS.Plot doesn't exist until PlotlyJS is loaded
    backend = Plots.backend()
    return save_plot(plot, filename, backend; kwargs...)
end
