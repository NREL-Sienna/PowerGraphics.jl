
function _empty_plot()
    backend = Plots.backend()
    return _empty_plot(backend)
end

function _empty_plots()
    backend = Plots.backend()
    return _empty_plots(backend)
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

# Accepted Key Words
- `display::Bool`: set to false to prevent the plots from displaying
- `save::String = "file_path"`: set a file path to save the plots
- `format::String = "html"`: set a different format for saving a PlotlyJS plot
- `seriescolor::Array`: Set different colors for the plots
- `title::String = "Title"`: Set a title for the plots
- `horizon::Int64 = 12`: To plot a shorter window of time than the full results
- `initial_time::DateTime`: To start the plot at a different time other than the results initial time
- `aggregate::String = "System", "PowerLoad", or "Bus"`: aggregate the demand other than by generator
"""

function plot_demand(result::Union{IS.Results, PSY.System}; kwargs...)
    return plot_demand(_empty_plot(), result; kwargs...)
end

function plot_demand(
    p::Union{Plots.Plot, Plots.PlotlyJS.Plot},
    result::Union{IS.Results, PSY.System};
    kwargs...,
)
    backend = Plots.backend()
    set_display = get(kwargs, :set_display, true)
    save_fig = get(kwargs, :save, nothing)
    bar = get(kwargs, :bar, false)

    title = get(kwargs, :title, "Demand")
    y_label = get(
        kwargs,
        :y_label,
        _make_ylabel(get_base_power(result), variable = "Demand", time = bar ? "h" : ""),
    )

    load = get_load_data(result; kwargs...)
    load_agg = combine_categories(load.data) .* -1.0
    p = plot_dataframe(
        p,
        load_agg,
        load.time;
        seriescolor = ["black"],
        linestyle = :dash,
        linewidth = 3,
        y_label = y_label,
        title = title,
        kwargs...,
    )

    set_display && display(p)
    if !isnothing(save_fig)
        title = replace(title, " " => "_")
        save_plot(p, joinpath(save_fig, "$(title).png"))
    end
    return p
end

function plot_demands(results::Array; kwargs...)
    backend = Plots.backend()
    set_display = get(kwargs, :set_display, true)
    save_fig = get(kwargs, :save, nothing)
    g_title = get(kwargs, :title, "Demand")
    kwargs = ((k, v) for (k, v) in kwargs if k ∉ [:title, :save])

    plots = []
    for (ix, result) in enumerate(results)
        title = ix == 1 ? g_title : ""
        p = plot_demand(result; title = title, kwargs...)
        push!(plots, p)
    end
    p1 =
        backend == Plots.GRBackend() ? Plots.plot(plots...; layout = (length(results), 1)) :
        plots
    set_display && display(p1)
    if !isnothing(save_fig)
        @warn "Saving figures not implemented for multi-plots"
    end
    return PlotList(Dict(:Demand_Stack => p1))#, :Fuel_Bar => p2))
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
- `display::Bool`: set to false to prevent the plots from displaying
- `save::String = "file_path"`: set a file path to save the plots
- `format::String = "html"`: set a different format for saving a PlotlyJS plot
- `seriescolor::Array`: Set different colors for the plots
- `title::String = "Title"`: Set a title for the plots
- `curtailment::Bool`: plot the curtailment with the variable
- `stack::Bool`: stack plot traces
- `bar::Bool` : create bar plot
"""
function plot_dataframe(
    variable::DataFrames.DataFrame,
    time_range::Union{DataFrames.DataFrame, Array, StepRange};
    kwargs...,
)
    return plot_dataframe(_empty_plot(), variable, time_range; kwargs...)
end

function plot_dataframe(
    p::Union{Plots.Plot, Plots.PlotlyJS.Plot},
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
- `format::String = "html"`: set a different format for saving a PlotlyJS plot
- `seriescolor::Array`: Set different colors for the plots
- `title::String = "Title"`: Set a title for the plots
- `curtailment::Bool`: plot the curtailment with the variable
- `stack::Bool`: stack plot traces
- `bar::Bool` : create bar plot
"""
function plot_pgdata(pgdata::PGData; kwargs...)
    return plot_pgdata(_empty_plot(), pgdata; kwargs...)
end

function plot_pgdata(p::Union{Plots.Plot, Plots.PlotlyJS.Plot}, pgdata::PGData; kwargs...)
    if get(kwargs, :combine_categories, true)
        agg = get(kwargs, :agg, nothing)
        names = get(kwargs, :names, nothing)
        data = combine_categories(pgdata.data; names = names, agg = agg)
    else
        data = pgdata.data
    end
    plot_dataframe(p, data, pgdata.time; kwargs...)
    return p
end

################################# Plotting Fuel Plot of Results ##########################
"""
    plot_fuel(results)

This function makes a stack plot of the results by fuel type
and assigns each fuel type a specific color.

# Arguments

- `res::Union{Results, Vector{IS.Results}}`: results to be plotted

# Example

```julia
res = solve_op_problem!(OpProblem)
plot = plot_fuel(res)
```

# Accepted Key Words
- `display::Bool`: set to false to prevent the plots from displaying
- `save::String = "file_path"`: set a file path to save the plots
- `format::String = "html"`: set a different format for saving a PlotlyJS plot
- `seriescolor::Array`: Set different colors for the plots
- `title::String = "Title"`: Set a title for the plots
- `curtailment::Bool`: To plot the curtailment in the stack plot
- `load::Bool`: To plot the load line in the plot
- `stair::Bool`: Make a stair plot instead of a stack plot
- `generator_mapping_file` = "file_path" : file path to yaml definig generator category by fuel and primemover
- `variables::Union{Nothing, Vector{Symbol}}` = nothing : specific variables to plot
"""

function plot_fuel(result::IS.Results; kwargs...)
    return plot_fuel(_empty_plot(), result; kwargs...)
end

function plot_fuel(p::Union{Plots.Plot, Plots.PlotlyJS.Plot}, result::IS.Results; kwargs...)
    backend = Plots.backend()
    set_display = get(kwargs, :set_display, true)
    save_fig = get(kwargs, :save, nothing)
    curtailment = get(kwargs, :curtailment, true)
    title = get(kwargs, :title, "Fuel")
    stack = get(kwargs, :stack, true)
    bar = get(kwargs, :bar, false)
    kwargs = Dict((k, v) for (k, v) in kwargs if k ∉ [:title, :save, :set_display])

    # Generation stack
    gen = get_generation_data(result; kwargs...)
    cat = make_fuel_dictionary(PSI.get_system(result); kwargs...)
    fuel = categorize_data(gen.data, cat; curtailment = curtailment)

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

    # load line
    p = plot_demand(
        p,
        result;
        nofill = true,
        title = title,
        y_label = y_label,
        set_display = false,
        kwargs...,
    )

    # service stack
    # TODO: how to display this?

    set_display && display(p)
    if !isnothing(save_fig)
        title = replace(title, " " => "_")
        save_plot(p, joinpath(save_fig, "$(title).png"))
    end
    return p
end

function plot_fuels(results::Array; kwargs...)
    backend = Plots.backend()
    set_display = get(kwargs, :set_display, true)
    save_fig = get(kwargs, :save, nothing)
    g_title = get(kwargs, :title, "Fuel")
    kwargs = ((k, v) for (k, v) in kwargs if k ∉ [:title, :save])

    plots = []
    for (ix, result) in enumerate(results)
        title = ix == 1 ? g_title : ""
        p = plot_fuel(result; title = title, kwargs...)
        push!(plots, p)
    end
    p1 =
        backend == Plots.GRBackend() ? Plots.plot(plots...; layout = (length(results), 1)) :
        plots
    set_display && display(p1)
    if !isnothing(save_fig)
        @warn "Saving figures not implemented for multi-plots"
    end
    return PlotList(Dict(:Fuel_Stack => p1))#, :Fuel_Bar => p2))
end
