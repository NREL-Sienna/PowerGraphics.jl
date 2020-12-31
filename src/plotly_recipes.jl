### PlotlyJS set up

function set_seriescolor(seriescolor::Array, gens::Array)
    colors = []
    for i in 1:length(gens)
        count = i % length(seriescolor)
        count = count == 0 ? length(seriescolor) : count
        colors = vcat(colors, seriescolor[count])
    end
    return colors
end

function _empty_plot(backend::Plots.PlotlyJSBackend)
    return Plots.PlotlyJS.Plot()
end

function _empty_plots(backend::Any)
    return Vector{Plots.PlotlyJS.Plot}()
end

function _dataframe_plots_internal(
    plot::Union{Plots.PlotlyJS.Plot, Nothing},
    variable::DataFrames.DataFrame,
    time_range::Array,
    backend::Plots.PlotlyJSBackend;
    kwargs...,
)
    names = DataFrames.names(variable)
    traces = plot.data
    plot_length = length(traces)
    seriescolor = set_seriescolor(
        get(kwargs, :seriescolor, PLOTLY_DEFAULT),
        [ones(plot_length); names],
    ) #TODO: add this to GR

    save_fig = get(kwargs, :save, nothing)
    y_label = get(kwargs, :y_label, "")
    title = get(kwargs, :title, " ")
    stack = get(kwargs, :stack, false)
    bar = get(kwargs, :bar, false)

    time_interval =
        IS.convert_compound_period(length(time_range) * (time_range[2] - time_range[1]))
    interval =
        Dates.Millisecond(Dates.Hour(1)) / Dates.Millisecond(time_range[2] - time_range[1])

    plot_data = convert(Matrix, variable)
    isnothing(plot) && _empty_plot()

    barmode = stack ? "stack" : "group"
    if bar
        plot_data = sum(plot_data, dims = 1) ./ interval
        xaxis = Plots.PlotlyJS.attr(; showticklabels = false)
        plot_type = "bar"
    else
        xaxis = Plots.PlotlyJS.attr(; showticklabels = true)
        plot_type = "scatter"
    end

    line_shape = get(kwargs, :stair, false) ? "hv" : "linear"

    for ix in 1:length(names)
        stackgroup = stack ? "one" : "$ix"
        fillcolor = bar ? seriescolor[ix] : (stack ? seriescolor[ix] : "transparent")
        trace = Plots.PlotlyJS.scatter(;
            name = names[ix],
            x = time_range,
            y = plot_data[:, ix],
            stackgroup = stackgroup,
            mode = "lines",
            type = plot_type,
            line_shape = line_shape,
            line_color = seriescolor[ix],
            marker_color = seriescolor[ix],
            fillcolor = fillcolor,
            showlegend = true,
        )
        push!(traces, trace)
    end

    yaxis = Plots.PlotlyJS.attr(; showticklabels = true)
    Plots.PlotlyJS.relayout!(
        plot,
        Plots.PlotlyJS.Layout(
            title = "$title",
            yaxis = yaxis,
            xaxis = xaxis,
            yaxis_title = y_label,
            xaxis_title = "$time_interval",
            barmode = barmode,
        ),
    )
    get(kwargs, :set_display, false) && display(Plots.PlotlyJS.plot(plot))
    if !isnothing(save_fig)
        title = title == " " ? "dataframe" : title
        format = get(kwargs, :format, "png")
        save_plot(plot, joinpath(save_fig, "$title.$format"))
    end
    return plot
end
#= removing support for multi-plot figure saving
function save_plot(plots::Vector, filename::String)
    (name, ext) = splitext(filename)
    filenames = []
    for (ix, p) in enumerate(plots)
        fname = name * "_$ix" * ext
        push!(filenames, Plots.PlotlyJS.savefig(p, fname; width = 800, height = 450))
    end
    return filenames
end=#
function save_plot(plot::Plots.PlotlyJS.Plot, filename::String)
    Plots.PlotlyJS.savefig(plot, filename; width = 800, height = 450)
    return filename
end
