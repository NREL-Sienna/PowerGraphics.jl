function _empty_plot()
    backend = Plots.backend()
    return _empty_plot(backend)
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

This function makes a plot of the demand in the system.

# Arguments

- `res::Union{Results, Vector{IS.Results}}`: results to be plotted

# Example

```julia
res = solve_op_problem!(OpProblem)
plot = plot_demand(res)
```

# Arguments
- `plot` : existing plot handle (optional)
- `result::Union{IS.Results, PSY.System}` : simulation results or PowerSystems.System

# Accepted Key Words
- `set_display::Bool`: set to false to prevent the plots from displaying
- `save::String = "file_path"`: set a file path to save the plots
- `format::String = "png"`: set a different format for saving a PlotlyJS plot
- `seriescolor::Array`: Set different colors for the plots
- `linestyle::Symbol = :dash` : set line style
- `title::String = "Title"`: Set a title for the plots
- `horizon::Int64 = 12`: To plot a shorter window of time than the full results
- `initial_time::DateTime`: To start the plot at a different time other than the results initial time
- `aggregate::String = "System", "PowerLoad", or "Bus"`: aggregate the demand other than by generator
"""

function plot_demand(result::Union{IS.Results, PSY.System}; kwargs...)
    return plot_demand(_empty_plot(), result; kwargs...)
end

function plot_demand(p, result::Union{IS.Results, PSY.System}; kwargs...)
    backend = Plots.backend()
    set_display = get(kwargs, :set_display, true)
    save_fig = get(kwargs, :save, nothing)
    bar = get(kwargs, :bar, false)
    linestyle = get(kwargs, :linestyle, :solid)

    title = get(kwargs, :title, "Demand")
    y_label = get(
        kwargs,
        :y_label,
        _make_ylabel(get_base_power(result), variable = "Demand", time = bar ? "h" : ""),
    )

    load = get_load_data(result; kwargs...)
    load_agg = combine_categories(load.data)

    if isnothing(load_agg)
        Throw(error("No load data found"))
    end

    p = plot_dataframe(
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
    plot_dataframe(df, time_range)
    plot_dataframe(plot, variable, time_range)

This function makes a plot of a specific dataframe and time range, not necessarily from the results

# Arguments

- `df::DataFrames.DataFrame`: The dataframe to be plotted
- `time_range::Union{Array, DataFrame}`: The time range to be plotted

# Example

```julia
var_name = :P__ThermalStandard
df = PSI.read_realized_variables(results, names = [var_name])[var_name]
time_range = PSI.get_realized_timestamps(results)
plot = plot_dataframe(df, time_range)
```

# Accepted Key Words
- `set_display::Bool`: set to false to prevent the plots from displaying
- `save::String = "file_path"`: set a file path to save the plots
- `format::String = "png"`: set a different format for saving a PlotlyJS plot
- `seriescolor::Array`: Set different colors for the plots
- `title::String = "Title"`: Set a title for the plots
- `curtailment::Bool`: plot the curtailment with the variable
- `stack::Bool`: stack plot traces
- `bar::Bool` : create bar plot
- `nofill::Bool` : force empty area fill
"""
function plot_dataframe(
    variable::DataFrames.DataFrame,
    time_range::Union{DataFrames.DataFrame, Array, StepRange};
    kwargs...,
)
    return plot_dataframe(_empty_plot(), variable, time_range; kwargs...)
end

function plot_dataframe(
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

################################# Plotting PGData ##########################

"""
    plot_pgdata(pgdata, time_range)
    plot_pgdata(plot, pgdata, time_range)

This function makes a plot of a PGdata object

# Arguments

- `plot` : existing plot handle (optional)
- `pgdata::PGData`: The dataframe to be plotted

# Example

```julia
var_name = :P__ThermalStandard
df = PSI.read_realized_variables(results, names = [var_name])[var_name]
time_range = PSI.get_realized_timestamps(results)
plot = plot_dataframe(df, time_range)
```

# Accepted Key Words
- `combine_categories::Bool = false` : plot category values or each value in a category
- `display::Bool`: set to false to prevent the plots from displaying
- `save::String = "file_path"`: set a file path to save the plots
- `format::String = "png"`: set a different format for saving a PlotlyJS plot
- `seriescolor::Array`: Set different colors for the plots
- `title::String = "Title"`: Set a title for the plots
- `curtailment::Bool`: plot the curtailment with the variable
- `stack::Bool`: stack plot traces
- `bar::Bool` : create bar plot
- `nofill::Bool` : force empty area fill
"""
function plot_pgdata(pgdata::PGData; kwargs...)
    return plot_pgdata(_empty_plot(), pgdata; kwargs...)
end

function plot_pgdata(p, pgdata::PGData; kwargs...)
    backend = Plots.backend()
    title = get(kwargs, :title, "")
    set_display = get(kwargs, :set_display, true)
    save_fig = get(kwargs, :save, nothing)

    if get(kwargs, :combine_categories, true)
        aggregate = get(kwargs, :aggregate, nothing)
        names = get(kwargs, :names, nothing)
        data = combine_categories(pgdata.data; names = names, aggregate = aggregate)
    else
        data = pgdata.data
    end
    kwargs =
        Dict{Symbol, Any}((k, v) for (k, v) in kwargs if k ∉ [:title, :save, :set_display])


    p = plot_dataframe(p, data, pgdata.time; set_display = false, kwargs...)

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

################################# Plotting Fuel Plot of Results ##########################
"""
    plot_fuel(results)

This function makes a stack plot of the results by fuel type
and assigns each fuel type a specific color.

# Arguments

- `plot` : existing plot handle (optional)
- `res::Results` : results to be plotted

# Example

```julia
res = solve_op_problem!(OpProblem)
plot = plot_fuel(res)
```

# Accepted Key Words
- `set_display::Bool = true`: set to false to prevent the plots from displaying
- `slacks::Bool = true` : display slack variables
- `load::Bool = true` : display load line
- `curtailment::Bool = true`: To plot the curtailment in the stack plot
- `save::String = "file_path"`: set a file path to save the plots
- `format::String = "png"`: set a different format for saving a PlotlyJS plot
- `seriescolor::Array`: Set different colors for the plots
- `title::String = "Title"`: Set a title for the plots
- `stack::Bool = true`: stack plot traces
- `bar::Bool` : create bar plot
- `nofill::Bool` : force empty area fill
- `stair::Bool`: Make a stair plot instead of a stack plot
- `generator_mapping_file` = "file_path" : file path to yaml definig generator category by fuel and primemover
- `variables::Union{Nothing, Vector{Symbol}}` = nothing : specific variables to plot
"""

function plot_fuel(result::IS.Results; kwargs...)
    return plot_fuel(_empty_plot(), result; kwargs...)
end

function plot_fuel(p, result::IS.Results; kwargs...)
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
    gen = get_generation_data(result; kwargs...)
    sys = PSI.get_system(result)
    if sys === nothing
        Throw(error("No System data present: please run `set_system!(results, sys)`"))
    end
    cat = make_fuel_dictionary(sys; kwargs...)
    fuel = categorize_data(gen.data, cat; curtailment = curtailment, slacks = slacks)

    # passing names here enforces order
    # TODO: enable custom sort with kwarg
    fuel_agg = combine_categories(fuel; names = intersect(CATEGORY_DEFAULT, keys(fuel)))
    y_label = get(
        kwargs,
        :y_label,
        _make_ylabel(get_base_power(result), variable = "", time = bar ? "h" : ""),
    )

    seriescolor = get(kwargs, :seriescolor, match_fuel_colors(fuel_agg, backend))
    p = plot_dataframe(
        fuel_agg,
        gen.time;
        stack = stack,
        seriescolor = seriescolor,
        y_label = y_label,
        title = title,
        set_display = false,
        kwargs...,
    )

    kwargs = Dict{Symbol, Any}((k, v) for (k, v) in kwargs if k ∉ [:nofill, :seriescolor])
    kwargs[:linestyle] = get(kwargs, :linestyle, :dash)
    kwargs[:linewidth] = get(kwargs, :linewidth, 3)

    if load
        # load line
        p = plot_demand(
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
