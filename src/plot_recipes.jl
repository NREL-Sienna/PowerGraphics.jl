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

###################################### GR FUEL PLOT ##############################
function _fuel_plot_internal(
    stack::Union{StackedGeneration, Array{StackedGeneration}},
    bar::Union{BarGeneration, Array{BarGeneration}},
    seriescolor::Array,
    backend::Any,
    save_fig::Any,
    set_display::Bool,
    title::String,
    ylabel::String,
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
        p1 = Plots.plot(
            time_range,
            stack_data;
            seriescolor = seriescolor,
            title = title,
            ylabel = ylabel,
            xlabel = "$time_interval",
            lab = stack.labels,
            xtick = [time_range[1], last(time_range)],
            grid = false,
            fillrange = stack_base_data,
            linetype = linetype,
            legend = :outerright,
        )
        if !isempty(stack.p_labels)
            load = cumsum(stack.parameters, dims = 2)
            Plots.plot!(
                time_range,
                load;
                seriescolor = :black,
                lab = "PowerLoad",
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
        p2 = Plots.plot(
            [3.5; 5.5],
            [bar_data; bar_data];
            seriescolor = seriescolor,
            ylabel = ylabel,
            xlabel = "$time_interval",
            xticks = false,
            xlims = (1, 8),
            grid = false,
            lab = bar.labels,
            title = title,
            legend = :outerright,
            fillrange = bar_base_data,
        )
        if !isempty(bar.p_labels)
            load = cumsum(bar.parameters, dims = 2) ./ interval
            Plots.plot!(
                [3.5; 5.5],
                [load; load];
                seriescolor = :black,
                lab = "PowerLoad",
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
    return PlotList(Dict(:Fuel_Stack => stack_plots, :Fuel_Bar => bar_plots))
end

############################# BAR ##########################################

function _bar_plot_internal(
    res::IS.Results,
    backend::Any,
    save_fig::Any,
    set_display::Bool,
    interval::Float64,
    reserves::Any;
    kwargs...,
)
    title = get(kwargs, :title, " ")
    ylabel = _make_bar_ylabel(IS.get_base_power(res))
    seriescolor = get(kwargs, :seriescolor, GR_DEFAULT)
    time_range = IS.get_time_stamp(res)[:, 1]
    time_interval =
        IS.convert_compound_period(length(time_range) * (time_range[2] - time_range[1]))
    bar_data = []
    plot_list = Dict()
    for (name, variable) in IS.get_variables(res)
        plot_data = sum(cumsum(convert(Matrix, variable), dims = 2), dims = 1) ./ interval
        p = Plots.plot(
            [3.5; 5.5],
            [plot_data; plot_data];
            seriescolor = seriescolor,
            ylabel = ylabel,
            xlabel = "$time_interval",
            xticks = false,
            xlims = (1, 8),
            grid = false,
            lab = hcat(string.(names(variable))...),
            title = "$name",
            legend = :outerright,
            fillrange = hcat(0, plot_data),
        )
        set_display && display(p)
        !isnothing(save_fig) && Plots.savefig(p, joinpath(save_fig, "$(name)_Bar.png"))
        bar_data = vcat(bar_data, [sum(convert(Matrix, variable), dims = 2)])
        plot_list[name] = p
    end
    bar_data = sum(cumsum(hcat(bar_data...), dims = 2), dims = 1) ./ interval
    p2 = Plots.plot(
        [3.5; 5.5],
        [bar_data; bar_data];
        seriescolor = seriescolor,
        ylabel = ylabel,
        xlabel = "$time_interval",
        xticks = false,
        xlims = (1, 8),
        grid = false,
        lab = hcat(string.(keys(IS.get_variables(res)))...),
        title = title,
        legend = :outerright,
        fillrange = hcat(0, bar_data),
    )
    parameters = res.parameter_values
    if !isempty(parameters)
        load_data = sum(convert(Matrix, parameters[:P__PowerLoad])) ./ interval
        Plots.plot!(
            [3.5, 5.5],
            [load_data; load_data];
            seriescolor = :black,
            linestyle = :dash,
            linewidth = 2.5,
            lab = "PowerLoad",
            legend = :outerright,
        )
    end
    set_display && display(p2)
    title = title == " " ? "Bar_Generation" : replace(title, " " => "_")
    !isnothing(save_fig) && Plots.savefig(p2, joinpath(save_fig, "$title.png"))
    plot_list[Symbol(title)] = p2
    if !isnothing(reserves)
        for (key, reserve) in reserves
            r_data = []
            for (k, v) in reserve
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
                lab = hcat(string.(keys(reserve))...),
                title = "$(key) Reserves",
                legend = :outerright,
                fillrange = hcat(0, r_data),
            )
            set_display && display(r_plot)
            !isnothing(save_fig) &&
                Plots.savefig(r_plot, joinpath(save_fig, "$(key)_Reserves.png"))
            plot_list[Symbol("$(key)_Reserves")] = r_plot
        end
    end
    return PlotList(plot_list)
end

function _bar_plot_internal(
    results::Any,
    backend::Any,
    save_fig::Any,
    set_display::Bool,
    interval::Float64,
    reserve_list::Any;
    kwargs...,
)
    title = get(kwargs, :title, " ")
    ylabel = _make_bar_ylabel(IS.get_base_power(results[1]))
    seriescolor = get(kwargs, :seriescolor, GR_DEFAULT)
    variables = IS.get_variables(results[1])
    time_range = IS.get_time_stamp(results[1])[:, 1]
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
        if !isempty(parameters)
            load_data = sum(convert(Matrix, parameters[:P__PowerLoad])) ./ interval
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
    res::IS.Results,
    backend::Any,
    save_fig::Any,
    set_display::Bool,
    reserves::Any;
    kwargs...,
)
    title = get(kwargs, :title, " ")
    ylabel = _make_ylabel(IS.get_base_power(res))
    seriescolor = get(kwargs, :seriescolor, GR_DEFAULT)
    linetype = get(kwargs, :linetype, :line)
    time_range = IS.get_time_stamp(res)[:, 1]
    time_interval =
        IS.convert_compound_period(length(time_range) * (time_range[2] - time_range[1]))
    stack_data = []
    plot_list = Dict()
    for (name, variable) in IS.get_variables(res)
        plot_data = cumsum(convert(Matrix, variable), dims = 2)
        p = Plots.plot(
            time_range,
            plot_data;
            seriescolor = seriescolor,
            ylabel = ylabel,
            xlabel = "$time_interval",
            xtick = [time_range[1], last(time_range)],
            grid = false,
            lab = hcat(string.(names(variable))...),
            title = "$name",
            legend = :outerright,
            linetype = linetype,
            fillrange = hcat(zeros(length(time_range)), plot_data),
        )
        set_display && display(p)
        stack_name = linetype == :line ? "$(name)_Stack" : "$(name)_Stair"
        !isnothing(save_fig) && Plots.savefig(p, joinpath(save_fig, "$(stack_name).png"))
        stack_data = vcat(stack_data, [sum(convert(Matrix, variable), dims = 2)])
        plot_list[name] = p
    end
    stack_data = cumsum(hcat(stack_data...), dims = 2)
    p2 = Plots.plot(
        time_range,
        stack_data;
        seriescolor = seriescolor,
        ylabel = ylabel,
        xlabel = "$time_interval",
        xtick = [time_range[1], last(time_range)],
        grid = false,
        lab = hcat(string.(keys(IS.get_variables(res)))...),
        title = title,
        legend = :outerright,
        linetype = linetype,
        fillrange = hcat(zeros(length(time_range)), stack_data),
    )
    parameters = res.parameter_values
    if !isempty(parameters)
        load_data =
            cumsum(sum(convert(Matrix, parameters[:P__PowerLoad]), dims = 2), dims = 2)
        Plots.plot!(
            time_range,
            load_data;
            seriescolor = :black,
            lab = "PowerLoad",
            legend = :outerright,
            linestyle = :dash,
            linewidth = 2.5,
            linetype = linetype,
        )
    end
    set_display && display(p2)
    stack_title = linetype == :line ? "Stack_Generation" : "Stair_Generation"
    title = title == " " ? stack_title : replace(title, " " => "_")
    !isnothing(save_fig) && Plots.savefig(p2, joinpath(save_fig, "$title.png"))
    plot_list[Symbol(title)] = p2
    if !isnothing(reserves)
        for (key, reserve) in reserves
            r_data = []
            for (k, v) in reserve
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
                lab = hcat((string.(keys(reserve)))...),
                title = "$(key) Reserves",
                legend = :outerright,
                linetype = linetype,
                fillrange = hcat(zeros(length(time_range)), r_data),
            )
            set_display && display(r_plot)
            !isnothing(save_fig) &&
                Plots.savefig(r_plot, joinpath(save_fig, "$(key)_Reserves.png"))
            plot_list[Symbol("$(key)_Reserves")] = r_plot
        end
    end
    return PlotList(plot_list)
end

function _stack_plot_internal(
    results::Any,
    backend::Any,
    save_fig::Any,
    set_display::Bool,
    reserve_list::Any;
    kwargs...,
)
    title = get(kwargs, :title, " ")
    ylabel = _make_ylabel(IS.get_base_power(results[1]))
    seriescolor = get(kwargs, :seriescolor, GR_DEFAULT)
    linetype = get(kwargs, :linetype, :line)
    variables = IS.get_variables(results[1])
    time_range = IS.get_time_stamp(results[1])[:, 1]
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
        if !isempty(parameters)
            load_data =
                cumsum(sum(convert(Matrix, parameters[:P__PowerLoad]), dims = 2), dims = 2)
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

######################################### DEMAND ########################

function _demand_plot_internal(res::IS.Results, backend::Any; kwargs...)
    stair = get(kwargs, :stair, false)
    linetype = stair ? :steppost : :line
    seriescolor = get(kwargs, :seriescolor, GR_DEFAULT)
    save_fig = get(kwargs, :save, nothing)
    set_display = get(kwargs, :display, true)
    time_range = res.time_stamp[:, 1]
    interval = time_range[2] - time_range[1]
    time_interval = IS.convert_compound_period(interval * length(time_range))
    ylabel = _make_ylabel(IS.get_base_power(res))
    plot_list = Dict()
    for (key, parameters) in res.parameter_values
        title = get(kwargs, :title, "$key")
        data = cumsum(convert(Matrix, parameters), dims = 2)
        labels = string(names(parameters)[1])
        for i in 2:length(names(parameters))
            labels = hcat(labels, string(names(parameters)[i]))
        end
        p = Plots.plot(
            time_range,
            data;
            seriescolor = seriescolor,
            title = title,
            ylabel = ylabel,
            lab = labels,
            legend = :outerright,
            xlabel = "$time_interval",
            xtick = [time_range[1], last(time_range)],
            grid = false,
            linetype = linetype,
        )
        set_display && display(p)
        title = replace(title, " " => "_")
        !isnothing(save_fig) && Plots.savefig(p, joinpath(save_fig, "$(title).png"))
        plot_list[key] = p
    end
    return PlotList(plot_list)
end

function _demand_plot_internal(results::Array{}, backend::Any; kwargs...)
    stair = get(kwargs, :stair, false)
    linetype = stair ? :steppost : :line
    seriescolor = get(kwargs, :seriescolor, GR_DEFAULT)
    save_fig = get(kwargs, :save, nothing)
    set_display = get(kwargs, :display, true)
    time_range = results[1].time_stamp[:, 1]
    interval = time_range[2] - time_range[1]
    time_interval = IS.convert_compound_period(interval * length(time_range))
    ylabel = _make_ylabel(IS.get_base_power(results[1]))
    plot_list = Dict()
    for (key, parameters) in results[1].parameter_values
        labels = string.(names(parameters))
        plots = []
        title = get(kwargs, :title, "$key")
        for i in 1:length(results)
            params = results[i].parameter_values[key]
            data = cumsum(convert(Matrix, params), dims = 2)
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
        p = Plots.plot(plots...; layout = (length(results), 1))
        set_display && display(p)
        title = replace(title, " " => "_")
        !isnothing(save_fig) && Plots.savefig(p, joinpath(save_fig, "$title.png"))
        plot_list[key] = p
    end
    return PlotList(plot_list)
end

####################### Demand Plot System ################################

function _demand_plot_internal(
    parameters::DataFrames.DataFrame,
    basepower::Float64,
    backend::Any;
    kwargs...,
)
    stair = get(kwargs, :stair, false)
    linetype = stair ? :steppost : :line
    seriescolor = get(kwargs, :seriescolor, GR_DEFAULT)
    save_fig = get(kwargs, :save, nothing)
    set_display = get(kwargs, :display, true)
    time_range = parameters[:, :timestamp]
    interval = time_range[2] - time_range[1]
    time_interval = IS.convert_compound_period(interval * length(time_range))
    ylabel = _make_ylabel(basepower)
    plot_list = Dict()
    title = get(kwargs, :title, "PowerLoad")
    DataFrames.select!(parameters, DataFrames.Not(:timestamp))
    data = cumsum(convert(Matrix, parameters), dims = 2)
    labels = string(names(parameters)[1])
    for i in 2:length(names(parameters))
        labels = hcat(labels, string(names(parameters)[i]))
    end
    p = Plots.plot(
        time_range,
        data;
        seriescolor = seriescolor,
        title = title,
        ylabel = ylabel,
        lab = labels,
        legend = :outerright,
        xlabel = "$time_interval",
        xtick = [time_range[1], last(time_range)],
        grid = false,
        linetype = linetype,
    )
    set_display && display(p)
    title = replace(title, " " => "_")
    !isnothing(save_fig) && Plots.savefig(p, joinpath(save_fig, "$(title).png"))
    plot_list[Symbol(title)] = p
    return PlotList(plot_list)
end

function _demand_plot_internal(
    parameter_list::Array,
    basepower::Array,
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
        ylabel = _make_ylabel(basepower[i])
        DataFrames.select!(parameter_list[i], DataFrames.Not(:timestamp))
        labels = string.(names(parameter_list[i]))
        data = cumsum(convert(Matrix, parameter_list[i]), dims = 2)
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

function _reserve_plot(res::IS.Results, backend::Any; kwargs...)
    reserves = _filter_reserves(res, true)
    time_range = IS.get_time_stamp(res)[:, 1]
    time_interval =
        IS.convert_compound_period(length(time_range) * (time_range[2] - time_range[1]))
    interval = Dates.Millisecond(Dates.Hour(1)) / (time_range[2] - time_range[1])
    seriescolor = get(kwargs, :seriescolor, GR_DEFAULT)
    set_display = get(kwargs, :display, true)
    linetype = get(kwargs, :stair, false) ? :steppost : :line
    save_fig = get(kwargs, :save, nothing)
    ylabel = _make_ylabel(IS.get_base_power(res))
    bar_ylabel = _make_bar_ylabel(IS.get_base_power(res))
    plot_list = Dict()
    if !isnothing(reserves)
        for (key, reserve) in reserves
            bar_data = []
            for (k, v) in reserve
                bar_data = vcat(bar_data, [sum(convert(Matrix, v), dims = 2)])
            end
            bar_data = sum(cumsum(hcat(bar_data...), dims = 2), dims = 1) ./ interval
            bar_plot = Plots.plot(
                [3.5; 5.5],
                [bar_data; bar_data];
                seriescolor = seriescolor,
                ylabel = bar_ylabel,
                xlabel = "$(time_interval)",
                xticks = false,
                xlims = (1, 8),
                grid = false,
                lab = hcat(string.(keys(reserve))...),
                title = "$(key) Reserves",
                legend = :outerright,
                fillrange = hcat(0, bar_data),
            )
            set_display && display(bar_plot)
            !isnothing(save_fig) &&
                Plots.savefig(bar_plot, joinpath(save_fig, "Bar_$(key)_Reserves.png"))
            plot_list[Symbol("Bar_$(key)_Reserves")] = bar_plot
            stack_data = []
            for (k, v) in reserve
                stack_data = vcat(stack_data, [sum(convert(Matrix, v), dims = 2)])
            end
            stack_data = cumsum(hcat(stack_data...), dims = 2)
            time_range = IS.get_time_stamp(res)[:, 1]
            r_plot = Plots.plot(
                time_range,
                stack_data;
                seriescolor = seriescolor,
                ylabel = ylabel,
                xlabel = "$time_interval",
                xtick = [time_range[1], last(time_range)],
                grid = false,
                lab = hcat((string.(keys(reserve)))...),
                title = "$(key) Reserves",
                legend = :outerright,
                linetype = linetype,
                fillrange = hcat(zeros(length(time_range)), stack_data),
            )
            set_display && display(r_plot)
            !isnothing(save_fig) &&
                Plots.savefig(r_plot, joinpath(save_fig, "Stack_$(key)_Reserves.png"))
            plot_list[Symbol("Stack_$(key)_Reserves")] = r_plot
        end
        return PlotList(plot_list)
    end
end

function _variable_plots_internal(
    res::IS.Results,
    var_name::Symbol,
    backend::Any,
    interval::Float64;
    kwargs...,
)
    seriescolor = get(kwargs, :seriescolor, GR_DEFAULT)
    save_fig = get(kwargs, :save, nothing)
    y_label = _make_ylabel(IS.get_base_power(res))
    time_range = IS.get_time_stamp(res)[:, 1]
    time_interval =
        IS.convert_compound_period(length(time_range) * (time_range[2] - time_range[1]))
    plot_list = Dict()
    variable = IS.get_variables(res)[var_name]
    plot_data = cumsum(convert(Matrix, variable), dims = 2)
    linetype = get(kwargs, :stair, false) ? :steppost : :line
    p = Plots.plot(
        time_range,
        plot_data;
        seriescolor = seriescolor,
        ylabel = y_label,
        xlabel = "$time_interval",
        xtick = [time_range[1], last(time_range)],
        grid = false,
        lab = hcat(string.(names(variable))...),
        title = "$var_name",
        legend = :outerright,
        linetype = linetype,
    )
    get(kwargs, :display, true) && display(p)
    stack_name = linetype == :line ? "$(var_name)_Stack" : "$(var_name)_Stair"
    !isnothing(save_fig) && Plots.savefig(p, joinpath(save_fig, "$(stack_name).png"))
    plot_list["Stack_$var_name"] = p
    return PlotList(plot_list)
end
