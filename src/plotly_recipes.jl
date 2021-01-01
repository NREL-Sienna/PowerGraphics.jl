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

function _empty_plots(backend::Plots.PlotlyJSBackend)
    return Vector{Plots.PlotlyJS.Plot}()
end

function _dataframe_plots_internal(
    plot::Any, # this needs to be typed but Plots.PlotlyJS.Plot doesn't exist until PlotlyJS is loaded
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
    nofill = get(kwargs, :nofill, !bar && !stack)

    time_interval =
        IS.convert_compound_period(length(time_range) * (time_range[2] - time_range[1]))
    interval =
        Dates.Millisecond(Dates.Hour(1)) / Dates.Millisecond(time_range[2] - time_range[1])

    plot_data = convert(Matrix, variable)
    showxticklabels = true
    isnothing(plot) && _empty_plot()

    barmode = stack ? "stack" : "group"
    plot_kwargs = Dict()
    if bar
        plot_data = sum(plot_data, dims = 1) ./ interval
        showtxicklabels = false
        if nofill
            plot_kwargs[:type] = "scatter"
            plot_data = [plot_data; plot_data]
            x = plot_length == 0 ? time_range : plot.data[1][:x]
            plot_kwargs[:fill] = "tozeroy"
        else
            plot_kwargs[:type] = "bar"
            plot_kwargs[:fill] = "tonexty"
        end
    else
        if !nofill && stack
            plot_kwargs[:fill] = "tonexty"
        end
        plot_kwargs[:plot_type] = "scatter"
    end

    plot_kwargs[:line_shape] = get(kwargs, :stair, false) ? "hv" : "linear"
    plot_kwargs[:mode] = "lines"
    plot_kwargs[:line_dash] = get(kwargs, :line_dash, "solid")
    plot_kwargs[:showlegend] = true
    plot_kwargs[:x] = time_range

    for ix in 1:length(names)
        if bar
            plot_kwargs[:marker_color] = seriescolor[ix]
        end
        if stack && !nofill
            plot_kwargs[:stackgroup] = "one"
            plot_kwargs[:fillcolor] = nofill ? "transparent" : seriescolor[ix]
        elseif !nofill
            plot_kwargs[:stackgroup] = string(ix + plot_length)
        end
        plot_kwargs[:line_color] = seriescolor[ix]
        plot_kwargs[:name] = names[ix]

        trace = Plots.PlotlyJS.scatter(;
            y = plot_data[:, ix],
            plot_kwargs...
        )
        push!(traces, trace)
    end
    y_lims = get(kwargs, :ylims, [0.0, maximum(plot_data)])
    yaxis = Plots.PlotlyJS.attr(; showticklabels = true, range = y_lims)
    xaxis = Plots.PlotlyJS.attr(; showticklabels = showxticklabels, kwargs...)

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

    #bar && nofill && Plots.PlotlyJS.relayout!(plot, Plots.PlotlyJS.Layout(shapes = hline(dropdims(plot_data, dims = 1))))
    get(kwargs, :set_display, false) && display(Plots.PlotlyJS.plot(plot))
    if !isnothing(save_fig)
        title = title == " " ? "dataframe" : title
        format = get(kwargs, :format, "png")
        save_plot(plot, joinpath(save_fig, "$title.$format"), backend; kwargs...)
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
function save_plot(plot::Any, filename::String, backend::Plots.PlotlyJSBackend; kwargs...) # this needs to be typed but Plots.PlotlyJS.Plot doesn't exist until PlotlyJS is loaded
    save_kwargs =  Dict{Symbol, Any}(((k, v) for (k, v) in kwargs if k in SUPPORTED_PLOTLY_SAVE_KWARGS))
    save_kwargs[:height] = get(kwargs, :height, 450)
    save_kwargs[:width] = get(kwargs, :width, 800)

    if get(save_kwargs, :format, "png") == "html"
        Plots.PlotlyJS.savehtml(Plots.PlotlyJS.plot(plot), filename, get(save_kwargs, :js, :embed))
    else
        Plots.PlotlyJS.savefig(plot, filename; save_kwargs...)
    end
    return filename
end
