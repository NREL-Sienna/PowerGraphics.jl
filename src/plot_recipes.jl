

function _empty_plot(backend::Any)
    return Plots.plot()
end

function _empty_plots(backend::Any)
    return Vector{Plots.Plot}()
end

function _dataframe_plots_internal(
    plot::Union{Plots.Plot, Nothing},
    variable::DataFrames.DataFrame,
    time_range::Array,
    backend::Any;
    kwargs...,
)
    seriescolor = get(kwargs, :seriescolor, GR_DEFAULT)
    save_fig = get(kwargs, :save, nothing)
    y_label = get(kwargs, :y_label, "")
    title = get(kwargs, :title, " ")
    stack = get(kwargs, :stack, false)

    time_interval =
        IS.convert_compound_period(length(time_range) * (time_range[2] - time_range[1]))
    interval =
        Dates.Millisecond(Dates.Hour(1)) / Dates.Millisecond(time_range[2] - time_range[1])

    data = convert(Matrix, variable)

    isnothing(plot) && _empty_plot()

    if stack
        plot_data = cumsum(data, dims = 2)
        fillrange = hcat(zeros(length(time_range)), plot_data)
    else
        plot_data = data
        fillrange = nothing
    end

    plot_kwargs = ((k, v) for (k, v) in kwargs if k in SUPPORTED_EXTRA_PLOT_KWARGS)

    if get(kwargs, :bar, false)
        plot_data = sum(plot_data, dims = 1) ./ interval
        if stack
            x = nothing
            plot_data = plot_data[end:-1:1, end:-1:1]
            legend = :outerright
            lab = hcat(string.(names(variable))...)[end:-1:1, end:-1:1]
            seriescolor = seriescolor[:, length(lab):-1:1]
        else
            x = names(variable)
            plot_data = permutedims(plot_data)
            seriescolor = permutedims(seriescolor)
            legend = false
            lab = hcat(string.(names(variable))...)
        end
        plot_func = get(kwargs, :nofill, false) ? Plots.hline! : Plots.bar!
        p = plot_func(
            x,
            plot_data;
            seriescolor = seriescolor,
            lab = lab,
            ylabel = y_label,
            legend = legend,
            title = title,
            ylims = get(kwargs, :ylims, (0.0, Inf)),
            xlabel = "$time_interval",
            xtick = false,
            plot_kwargs...,
        )
    else
        linetype = get(kwargs, :stair, false) ? :steppost : :line
        p = Plots.plot!(
            time_range,
            plot_data;
            seriescolor = seriescolor,
            ylabel = y_label,
            ylims = get(kwargs, :ylims, (0.0, Inf)),
            xlabel = "$time_interval",
            xtick = [time_range[1], last(time_range)],
            grid = false,
            lab = hcat(string.(names(variable))...),
            title = title,
            legend = :outerright,
            linetype = linetype,
            fillrange = fillrange,
            plot_kwargs...,
        )
    end
    get(kwargs, :set_display, false) && display(p)
    title = title == " " ? "dataframe" : title
    !isnothing(save_fig) && Plots.savefig(p, joinpath(save_fig, "$(title).png"))
    return p
end

function save_plot(plot::Plots.Plot, filename::String)
    Plots.savefig(plot, filename)
end
