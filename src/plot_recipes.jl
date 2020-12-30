struct PlotList
    plots::Dict
end
function PlotList()
    PlotList(Dict())
end
Base.show(io::IO, mm::MIME"text/html", p::PlotList) =
    show(io, mm, "$(Plots.backend()) with $(length(p.plots)) plots, named $(keys(p.plots))")
Base.show(io::IO, mm::MIME"text/plain", p::PlotList) =
    show(io, mm, "$(Plots.backend()) with $(length(p.plots)) plots, named $(keys(p.plots))")

function _check_matching_variables(results::Array)
    variables = DataFrames.DataFrame()
    first_keys = collect(keys(IS.get_variables(results[1])))
    for res in 2:length(results)
        var = collect(keys(IS.get_variables(results[res])))
        if var != first_keys
            throw(IS.ConflictingInputsError("The given results do not have matching variable lists."))
        end
    end
end

function _empty_plot(backend::Any)
    return Plots.plot()
end
#=
###################################### GR FUEL PLOT ##############################

function _get_load_line_data(parameters, labels)
    loads = []
    load_names = []
    for (ix, param) in enumerate(labels)
        if Symbol(param) in [LOAD_PARAMETER, ILOAD_PARAMETER]
            push!(loads, parameters[:, ix])
            push!(load_names, param)
        end
    end
    load = cumsum(hcat(loads...), dims = 2)
    return load, permutedims(load_names)
end

function _plot_fuel_internal(
    stack::Vector{StackedGeneration},
    bar::Vector{BarGeneration},
    seriescolor::Array,
    backend::Any,
    save_fig::Any,
    set_display::Bool,
    title::String,
    ylabel::NamedTuple{(:stack, :bar), Tuple{String, String}},
    interval::Float64;
    kwargs...,
)
    stack_plots = []
    bar_plots = []
    stair = get(kwargs, :stair, false)
    linetype = stair ? :steppost : :line
    stacks = vcat([], stack)
    bars = vcat([], bar)

    for stack in stacks
        time_range = stack.time_range
        time_interval =
            IS.convert_compound_period(length(time_range) * (time_range[2] - time_range[1]))
        stack_data = cumsum(stack.data_matrix, dims = 2)
        stack_base_data = [zeros(size(stack_data, 1)) stack_data]
        labels = length(stack.labels) == 1 ? stack.labels[1] : stack.labels
        p1 = Plots.plot(
            time_range,
            stack_data;
            seriescolor = seriescolor,
            title = title,
            ylabel = ylabel.stack,
            xlabel = "$time_interval",
            lab = labels,
            xtick = [time_range[1], last(time_range)],
            grid = false,
            fillrange = stack_base_data,
            linetype = linetype,
            legend = :outerright,
        )
        (load, load_names) = _get_load_line_data(stack.parameters, stack.p_labels)
        if !isempty(load)
            Plots.plot!(
                time_range,
                load;
                seriescolor = :black,
                lab = load_names,
                legend = :outerright,
                linestyle = :dash,
                linewidth = 2.5,
                linetype = linetype,
            )
        end
        push!(stack_plots, p1)
    end
    p1 = Plots.plot(stack_plots...; layout = (length(stacks), 1))
    for bar in bars
        time_range = bar.time_range
        time_interval =
            IS.convert_compound_period(length(time_range) * (time_range[2] - time_range[1]))
        bar_data = cumsum(bar.bar_data, dims = 2) ./ interval
        bar_base_data = [0 bar_data]
        labels = length(bar.labels) == 1 ? bar.labels[1] : bar.labels
        p2 = Plots.plot(
            [3.5; 5.5],
            [bar_data; bar_data];
            seriescolor = seriescolor,
            ylabel = ylabel.bar,
            xlabel = "$time_interval",
            xticks = false,
            xlims = (1, 8),
            grid = false,
            lab = labels,
            title = title,
            legend = :outerright,
            fillrange = bar_base_data,
        )
        (load, load_names) = _get_load_line_data(bar.parameters, bar.p_labels)
        if !isempty(load)
            Plots.plot!(
                [3.5; 5.5],
                [load; load] ./ interval;
                seriescolor = :black,
                lab = load_names,
                linestyle = :dash,
                linewidth = 2.5,
                legend = :outerright,
            )
        end
        push!(bar_plots, p2)
    end
    p2 = Plots.plot(bar_plots...; layout = (length(bars), 1))
    set_display && display(p1)
    set_display && display(p2)
    if !isnothing(save_fig)
        title = replace(title, " " => "_")
        stack_title = linetype == :line ? "$(title)_Stack" : "$(title)_Stair"
        Plots.savefig(p1, joinpath(save_fig, "$(stack_title).png"))
        Plots.savefig(p2, joinpath(save_fig, "$(title)_Bar.png"))
    end
    return PlotList(Dict(:Fuel_Stack => p1, :Fuel_Bar => p2))
end

############################# BAR ##########################################

function _bar_plot_internal(
    results::Vector,
    backend::Any,
    save_fig::Any,
    set_display::Bool,
    interval::Float64,
    reserve_list::Vector;
    kwargs...,
)
    title = get(kwargs, :title, " ")
    ylabel = _make_bar_ylabel(IS.get_base_power(results[1]))
    seriescolor = get(kwargs, :seriescolor, GR_DEFAULT)
    variables = IS.get_variables(results[1])
    time_range = IS.get_timestamp(results[1])[:, 1]
    time_interval =
        IS.convert_compound_period(length(time_range) * (time_range[2] - time_range[1]))
    bars = []
    plots = []
    plot_list = Dict()
    for (name, variable) in variables
        plots = []
        bar_data = []
        for res in results
            variable = IS.get_variables(res)[name]
            data = convert(Matrix, variable)
            plot_data = sum(cumsum(data, dims = 2), dims = 1) ./ interval
            base_data = hcat(0, plot_data)
            labels = string.(names(variable))
            p = Plots.plot(
                [3.5; 5.5],
                [plot_data; plot_data];
                seriescolor = seriescolor,
                ylabel = ylabel,
                xlabel = "$time_interval",
                xticks = false,
                xlims = (1, 8),
                grid = false,
                lab = hcat(labels...),
                title = "$name",
                legend = :outerright,
                fillrange = base_data,
            )
            plots = vcat(plots, p)
        end
        plot = Plots.plot(plots...; layout = (length(results), 1))
        set_display && display(plot)
        !isnothing(save_fig) && Plots.savefig(plot, joinpath(save_fig, "$(name)_Bar.png"))
        plot_list[name] = plot
    end
    bar_plots = []
    for res in results
        bar_data = []
        for (key, variable) in IS.get_variables(res)
            bar_data = vcat(bar_data, [sum(convert(Matrix, variable), dims = 2)])
        end
        bar_data = sum(cumsum(hcat(bar_data...), dims = 2), dims = 1) ./ interval
        base_data = hcat(0, bar_data)
        labels = string.(keys(variables))
        p = Plots.plot(
            [3.5; 5.5],
            [bar_data; bar_data];
            seriescolor = seriescolor,
            ylabel = ylabel,
            xlabel = "$time_interval",
            xticks = false,
            xlims = (1, 8),
            grid = false,
            lab = hcat(labels...),
            title = title,
            legend = :outerright,
            fillrange = base_data,
        )
        parameters = res.parameter_values
        if haskey(parameters, LOAD_PARAMETER)
            load_data = sum(convert(Matrix, parameters[LOAD_PARAMETER])) ./ interval
            Plots.plot!(
                [3.5; 5.5],
                [load_data; load_data];
                seriescolor = :black,
                linestyle = :dash,
                linewidth = 2.5,
                lab = "PowerLoad",
                legend = :outerright,
            )
        end
        bar_plots = vcat(bar_plots, p)
    end
    bar_plot = Plots.plot(bar_plots...; layout = (length(results), 1))
    set_display && display(bar_plot)
    title = title == " " ? "Bar_Generation" : replace(title, " " => "_")
    !isnothing(save_fig) && Plots.savefig(bar_plot, joinpath(save_fig, "$title.png"))
    plot_list[Symbol(title)] = bar_plot

    if !isnothing(reserve_list[1])
        for key in keys(reserve_list[1])
            r_plots = []
            for reserves in reserve_list
                r_data = []
                for (k, v) in reserves[key]
                    r_data = vcat(r_data, [sum(convert(Matrix, v), dims = 2)])
                end
                r_data = sum(cumsum(hcat(r_data...), dims = 2), dims = 1) ./ interval
                r_plot = Plots.plot(
                    [3.5; 5.5],
                    [r_data; r_data];
                    seriescolor = seriescolor,
                    ylabel = ylabel,
                    xlabel = "$time_interval",
                    xticks = false,
                    xlims = (1, 8),
                    grid = false,
                    lab = hcat(string.(keys(reserves[key]))...),
                    title = "$(key) Reserves",
                    legend = :outerright,
                    fillrange = hcat(0, r_data),
                )
                r_plots = vcat(r_plots, r_plot)
            end
            r_plot = Plots.plot(r_plots...; layout = (length(results), 1))
            set_display && display(r_plot)
            !isnothing(save_fig) &&
                Plots.savefig(r_plot, joinpath(save_fig, "$(key)_Reserves.png"))
            plot_list[Symbol("$(key)_Reserves")] = r_plot
        end
    end
    return PlotList(plot_list)
end

############################ STACK ########################

function _stack_plot_internal(
    results::Vector,
    backend::Any,
    save_fig::Any,
    set_display::Bool,
    reserve_list::Vector;
    kwargs...,
)
    title = get(kwargs, :title, " ")
    ylabel = _make_ylabel(IS.get_base_power(results[1]))
    seriescolor = get(kwargs, :seriescolor, GR_DEFAULT)
    linetype = get(kwargs, :stair, false) ? :steppost : :line
    variables = IS.get_variables(results[1])
    time_range = IS.get_timestamp(results[1])[:, 1]
    time_interval =
        IS.convert_compound_period(length(time_range) * (time_range[2] - time_range[1]))
    stacks = []
    plots = []
    plot_list = Dict()
    for (name, variable) in variables
        plots = []
        stack_data = []
        for res in results
            variable = IS.get_variables(res)[name]
            data = convert(Matrix, variable)
            plot_data = cumsum(data, dims = 2)
            base_data = hcat(zeros(length(time_range)), plot_data)
            labels = string.(names(variable))
            p = Plots.plot(
                time_range,
                plot_data;
                seriescolor = seriescolor,
                ylabel = ylabel,
                xlabel = "$time_interval",
                xtick = [time_range[1], last(time_range)],
                grid = false,
                lab = hcat(labels...),
                title = "$name",
                legend = :outerright,
                linetype = linetype,
                fillrange = base_data,
            )
            plots = vcat(plots, p)
        end
        plot = Plots.plot(plots...; layout = (length(results), 1))
        set_display && display(plot)
        stack_name = linetype == :line ? "$(name)_Stack" : "$(name)_Stair"
        !isnothing(save_fig) && Plots.savefig(plot, joinpath(save_fig, "$(stack_name).png"))
        plot_list[name] = plot
    end
    stack_plots = []
    for res in results
        stack_data = []
        for (key, variable) in IS.get_variables(res)
            stack_data = vcat(stack_data, [sum(convert(Matrix, variable), dims = 2)])
        end
        stack_data = cumsum(hcat(stack_data...), dims = 2)
        base_data = hcat(zeros(length(time_range)), stack_data)
        labels = string.(keys(variables))
        p = Plots.plot(
            time_range,
            stack_data;
            seriescolor = seriescolor,
            ylabel = ylabel,
            xlabel = "$time_interval",
            xtick = [time_range[1], last(time_range)],
            grid = false,
            lab = hcat(labels...),
            title = title,
            legend = :outerright,
            linetype = linetype,
            fillrange = base_data,
        )
        parameters = res.parameter_values
        if haskey(parameters, LOAD_PARAMETER)
            load_data =
                cumsum(sum(convert(Matrix, parameters[LOAD_PARAMETER]), dims = 2), dims = 2)
            Plots.plot!(
                time_range,
                load_data;
                seriescolor = :black,
                lab = "PowerLoad",
                linestyle = :dash,
                linewidth = 2.5,
                legend = :outerright,
                linetype = linetype,
            )
        end
        stack_plots = vcat(stack_plots, p)
    end
    stack_plot = Plots.plot(stack_plots...; layout = (length(results), 1))
    set_display && display(stack_plot)
    stack_name = linetype == :line ? "Stack_Generation" : "Stair_Generation"
    title = title == " " ? stack_name : replace(title, " " => "_")
    !isnothing(save_fig) && Plots.savefig(stack_plot, joinpath(save_fig, "$title.png"))
    plot_list[Symbol(title)] = stack_plot
    if !isnothing(reserve_list[1])
        for key in keys(reserve_list[1])
            r_plots = []
            for reserves in reserve_list
                r_data = []
                for (k, v) in reserves[key]
                    r_data = vcat(r_data, [sum(convert(Matrix, v), dims = 2)])
                end
                r_data = cumsum(hcat(r_data...), dims = 2)
                r_plot = Plots.plot(
                    time_range,
                    r_data;
                    seriescolor = seriescolor,
                    ylabel = ylabel,
                    xlabel = "$time_interval",
                    xtick = [time_range[1], last(time_range)],
                    grid = false,
                    lab = hcat((string.(keys(reserves[key])))...),
                    title = "$(key) Reserves",
                    legend = :outerright,
                    linetype = linetype,
                    fillrange = hcat(zeros(length(time_range)), r_data),
                )
                r_plots = vcat(r_plots, r_plot)
            end
            r_plot = Plots.plot(r_plots...; layout = (length(results), 1))
            set_display && display(r_plot)
            !isnothing(save_fig) &&
                Plots.savefig(r_plot, joinpath(save_fig, "$(key)_Reserves.png"))
            plot_list[Symbol("$(key)_Reserves")] = r_plot
        end
    end
    return PlotList(plot_list)
end
=#
######################################### DEMAND ########################

function _demand_plot_internal(results::Vector, backend::Any; kwargs...)
    stair = get(kwargs, :stair, false)
    linetype = stair ? :steppost : :line
    seriescolor = get(kwargs, :seriescolor, GR_DEFAULT)
    save_fig = get(kwargs, :save, nothing)
    set_display = get(kwargs, :display, true)
    plot_list = Dict()
    all_plots = []
    for (ix, result) in enumerate(results)
        time_range = result.timestamp[:, 1]
        interval = time_range[2] - time_range[1]
        time_interval = IS.convert_compound_period(interval * length(time_range))
        ylabel = _make_ylabel(IS.get_base_power(result))
        p = _empty_plot(backend)
        for (key, parameter) in result.parameter_values
            labels = string.(names(parameter))
            title = get(kwargs, :title, "$key") #WTF?
            data = convert(Matrix, parameter)
            Plots.plot!(
                p,
                time_range,
                data;
                seriescolor = seriescolor,
                title = title,
                ylabel = ylabel,
                xlabel = "$time_interval",
                xtick = [time_range[1], last(time_range)],
                grid = false,
                lab = hcat(labels...),
                legend = :outerright,
                linetype = linetype,
            )
        end
        set_display && display(p)
        push!(all_plots, p)
    end
    plot_list = Dict(:demand => Plots.plot(all_plots...; layout = (length(results), 1)))
    title = replace(title, " " => "_")
    !isnothing(save_fig) &&
        Plots.savefig(plot_list[:demand], joinpath(save_fig, "$title.png"))

    return PlotList(plot_list)
end

####################### Demand Plot System ################################

function _demand_plot_internal(
    parameter_list::Array,
    base_power::Array,
    backend::Any;
    kwargs...,
)
    stair = get(kwargs, :stair, false)
    linetype = stair ? :steppost : :line
    seriescolor = get(kwargs, :seriescolor, GR_DEFAULT)
    save_fig = get(kwargs, :save, nothing)
    set_display = get(kwargs, :display, true)
    time_range = parameter_list[1][:, 1]
    interval = time_range[2] - time_range[1]
    time_interval = IS.convert_compound_period(interval * length(time_range))
    plot_list = Dict()
    plots = []
    title = get(kwargs, :title, "PowerLoad")
    for i in 1:length(parameter_list)
        ylabel = _make_ylabel(base_power[i])
        DataFrames.select!(parameter_list[i], DataFrames.Not(:timestamp))
        labels = string.(names(parameter_list[i]))
        data = convert(Matrix, parameter_list[i])
        p = Plots.plot(
            time_range,
            data;
            seriescolor = seriescolor,
            title = title,
            ylabel = ylabel,
            xlabel = "$time_interval",
            xtick = [time_range[1], last(time_range)],
            grid = false,
            lab = hcat(labels...),
            legend = :outerright,
            linetype = linetype,
        )
        plots = vcat(plots, p)
    end
    p = Plots.plot(plots...; layout = (length(parameter_list), 1))
    set_display && display(p)
    title = replace(title, " " => "_")
    !isnothing(save_fig) && Plots.savefig(p, joinpath(save_fig, "$title.png"))
    plot_list[Symbol(title)] = p
    return PlotList(plot_list)
end
#=
function _variable_plots_internal(
    plot::Any,
    variable::DataFrames.DataFrame,
    time_range::Array,
    base_power::Float64,
    variable_name::Symbol,
    backend::Any;
    kwargs...,
)
    seriescolor = get(kwargs, :seriescolor, GR_DEFAULT)
    save_fig = get(kwargs, :save, nothing)
    title = get(kwargs, :title, "$variable_name")
    y_label = _make_ylabel(base_power)
    p = _dataframe_plots_internal(
        plot,
        variable,
        time_range,
        backend;
        y_label = y_label,
        title = title,
        kwargs...,
    )
    return p
end
=#

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

    plot_list = Dict()
    data = convert(Matrix, variable)

    isnothing(plot) && _empty_plot()

    if stack
        plot_data = cumsum(data, dims = 2)
        fillrange = hcat(zeros(length(time_range)), plot_data)
    else
        plot_data = data
        fillrange = nothing
    end

    if get(kwargs, :bar, false)
        plot_data = sum(plot_data, dims = 1) ./ interval
        if stack
            x = nothing
            plot_data = plot_data[end:-1:1, end:-1:1]
            legend = :outerright
            lab = hcat(string.(names(variable))...)[end:-1:1, end:-1:1]
            n = length(lab)
            seriescolor = seriescolor[:, n:-1:1]

        else
            x = names(variable)
            plot_data = permutedims(plot_data)
            seriescolor = permutedims(seriescolor)
            legend = false
            lab = hcat(string.(names(variable))...)
        end
        p = Plots.bar!(
            x,
            plot_data;
            seriescolor = seriescolor,
            lab = lab,
            legend = legend,
            title = title,
            xlabel = "$time_interval",
        )
    else
        linetype = get(kwargs, :stair, false) ? :steppost : :line
        SUPPORTED_EXTRA_PLOT_KWARGS = [:linestyle, :linewidth]
        plot_kwargs = (k for k in kwargs if k[1] in SUPPORTED_EXTRA_PLOT_KWARGS)
        p = Plots.plot!(
            time_range,
            plot_data;
            seriescolor = seriescolor,
            ylabel = y_label,
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
