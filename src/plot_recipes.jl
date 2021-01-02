
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
    title = get(kwargs, :title, " ")
    bar = get(kwargs, :bar, false)
    stack = get(kwargs, :stack, false)
    nofill = get(kwargs, :nofill, false)

    time_interval =
        IS.convert_compound_period(length(time_range) * (time_range[2] - time_range[1]))
    interval =
        Dates.Millisecond(Dates.Hour(1)) / Dates.Millisecond(time_range[2] - time_range[1])

    data = convert(Matrix, variable)
    labels = names(variable)

    isnothing(plot) && _empty_plot()
    plot_kwargs =
        Dict{Symbol, Any}(((k, v) for (k, v) in kwargs if k in SUPPORTED_EXTRA_PLOT_KWARGS))

    if stack
        plot_data = cumsum(data, dims = 2)
        if !nofill
            plot_kwargs[:fillrange] = hcat(zeros(length(time_range)), plot_data)
        end
    else
        plot_data = data
    end

    plot_kwargs[:seriescolor] = seriescolor
    plot_kwargs[:title] = title
    plot_kwargs[:ylims] = get(kwargs, :ylims, (0.0, Inf))
    plot_kwargs[:ylabel] = get(kwargs, :y_label, "")
    plot_kwargs[:xlabel] = "$time_interval"
    plot_kwargs[:grid] = false

    if bar
        plot_data = sum(plot_data, dims = 1) ./ interval
        if stack
            x = nothing
            plot_data = plot_data[end:-1:1, end:-1:1]
            plot_kwargs[:lab] = hcat(string.(labels)...)[end:-1:1, end:-1:1]
            plot_kwargs[:seriescolor] = seriescolor[:, length(labels):-1:1]
            plot_kwargs[:legend] = :outerright
        else
            x = labels
            plot_data = permutedims(plot_data)
            plot_kwargs[:lab] = hcat(string.(labels)...)
            plot_kwargs[:seriescolor] = permutedims(seriescolor)
            plot_kwargs[:legend] = false
        end
        plot_func = nofill ? Plots.hline! : Plots.bar!
        p = plot_func(x, plot_data; plot_kwargs...)
    else
        plot_kwargs[:lab] = hcat(string.(labels)...)
        plot_kwargs[:linetype] = get(kwargs, :stair, false) ? :steppost : :line
        plot_kwargs[:xtick] = [time_range[1], last(time_range)]
        plot_kwargs[:legend] = :outerright

        p = Plots.plot!(time_range, plot_data; plot_kwargs...)
    end
    get(kwargs, :set_display, false) && display(p)
    title = title == " " ? "dataframe" : title
    !isnothing(save_fig) &&
        save_plot(p, joinpath(save_fig, "$(title).png"), backend; kwargs...)
    return p
end

function save_plot(plot::Plots.Plot, filename::String, backend::Any; kwargs...)
    Plots.savefig(plot, filename) # TODO: add kwargs support
end
