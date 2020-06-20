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

########################################## PLOTLYJS STACK ##########################

function _stack_plot_internal(
    res::IS.Results,
    backend::Plots.PlotlyJSBackend,
    save_fig::Any,
    set_display::Bool,
    reserves::Any;
    kwargs...,
)
    seriescolor = get(kwargs, :seriescolor, PLOTLY_DEFAULT)
    title = get(kwargs, :title, " ")
    ylabel = _make_ylabel(IS.get_base_power(res))
    stack = plotly_stack_plots(res, seriescolor, ylabel; kwargs...)
    gen_stack = plotly_stack_gen(res, seriescolor, title, ylabel, reserves; kwargs...)
    return PlotList(merge(stack, gen_stack))
end

function _stack_plot_internal(
    res::Array{},
    backend::Plots.PlotlyJSBackend,
    save_fig::Any,
    set_display::Bool,
    reserves::Any;
    kwargs...,
)
    seriescolor = get(kwargs, :seriescolor, PLOTLY_DEFAULT)
    title = get(kwargs, :title, " ")
    ylabel = _make_ylabel(IS.get_base_power(res[1]))
    stack = plotly_stack_plots(res, seriescolor, ylabel; kwargs...)
    gen_stack = plotly_stack_gen(res, seriescolor, title, ylabel, reserves; kwargs...)
    return PlotList(merge(stack, gen_stack))
end

function plotly_stack_gen(
    res::IS.Results,
    seriescolors::Array,
    title::String,
    ylabel::String,
    reserves::Any;
    kwargs...,
)
    set_display = get(kwargs, :display, true)
    line_shape = get(kwargs, :stair, false) ? "hv" : "linear"
    save_fig = get(kwargs, :save, nothing)
    format = get(kwargs, :format, "html")
    plot_output = Dict()
    traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
    gens = collect(keys(IS.get_variables(res)))
    params = collect(keys(res.parameter_values))
    time_range = IS.get_time_stamp(res)[:, 1]
    stack = []
    plot_stack = Dict()
    for (k, v) in IS.get_variables(res)
        stack = vcat(stack, [sum(convert(Matrix, v), dims = 2)])
    end
    stack = hcat(stack...)
    parameters = []
    for (p, v) in res.parameter_values
        parameters = vcat(parameters, [sum(convert(Matrix, v), dims = 2)])
    end
    parameters = hcat(parameters...)
    seriescolor = set_seriescolor(seriescolors, gens)
    for gen in 1:length(gens)
        push!(
            traces,
            Plots.PlotlyJS.scatter(;
                name = gens[gen],
                x = time_range,
                y = stack[:, gen],
                stackgroup = "one",
                showlegend = true,
                mode = "lines",
                line_shape = line_shape,
                fill = "tonexty",
                line_color = seriescolor[gen],
                fillcolor = seriescolor[gen],
            ),
        )
    end
    if !isempty(params)
        for param in 1:length(params)
            push!(
                traces,
                Plots.PlotlyJS.scatter(;
                    name = params[param],
                    x = time_range,
                    y = parameters[:, param],
                    stackgroup = "two",
                    mode = "lines",
                    line_shape = line_shape,
                    fill = "tozeroy",
                    line_color = "black",
                    line_dash = "dash",
                    line_width = "3",
                    fillcolor = "rgba(0, 0, 0, 0)",
                ),
            )
        end
    end
    p = Plots.PlotlyJS.plot(
        traces,
        Plots.PlotlyJS.Layout(title = title, yaxis_title = ylabel),
    )
    set_display && Plots.display(p)
    if !isnothing(reserves)
        reserve_plot = []
        for (key, reserve) in reserves
            r_data = []
            r_gens = []
            r_traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
            for (k, v) in reserve
                r_data = vcat(r_data, [sum(convert(Matrix, v), dims = 2)])
                r_gens = vcat(r_gens, k)
            end
            r_data = hcat(r_data...)
            up_seriescolor = set_seriescolor(seriescolors, r_gens)
            for gen in 1:size(r_gens, 1)
                push!(
                    r_traces,
                    Plots.PlotlyJS.scatter(;
                        name = r_gens[gen],
                        x = time_range,
                        y = r_data[:, gen],
                        stackgroup = "one",
                        mode = "lines",
                        showlegend = true,
                        line_shape = line_shape,
                        fill = "tonexty",
                        line_color = up_seriescolor[gen],
                        fillcolor = up_seriescolor[gen],
                    ),
                )
            end
            r_plot = Plots.PlotlyJS.plot(
                r_traces,
                Plots.PlotlyJS.Layout(title = "$(key) Reserves", yaxis_title = ylabel),
            )
            set_display && Plots.display(r_plot)
            if !isnothing(save_fig)
                Plots.PlotlyJS.savefig(
                    r_plot,
                    joinpath(save_fig, "$(key)_Reserves.$format");
                    width = 630,
                    height = 630,
                )
            end
            plot_output[Symbol("$(key)_Reserves")] = r_plot
        end
    end
    stack_title = line_shape == "linear" ? "Stack_Generation" : "Stair_Generation"
    title = title == " " ? stack_title : replace(title, " " => "_")
    if !isnothing(save_fig)
        Plots.PlotlyJS.savefig(
            p,
            joinpath(save_fig, "$title.$format");
            width = 630,
            height = 630,
        )
    end
    plot_output[Symbol(title)] = p
    return plot_output
end

function plotly_stack_gen(
    results::Array,
    seriescolors::Array,
    title::String,
    ylabel::String,
    reserve_list::Any;
    kwargs...,
)
    set_display = get(kwargs, :display, true)
    line_shape = get(kwargs, :stair, false) ? "hv" : "linear"
    save_fig = get(kwargs, :save, nothing)
    format = get(kwargs, :format, "html")
    plot_output = Dict()
    plots = []
    for i in 1:length(results)
        gens = collect(keys(IS.get_variables(results[i])))
        params = collect(keys(results[i].parameter_values))
        time_range = IS.get_time_stamp(results[i])[:, 1]
        stack = []
        for (k, v) in IS.get_variables(results[i])
            stack = vcat(stack, [sum(convert(Matrix, v), dims = 2)])
        end
        parameters = []
        for (p, v) in results[i].parameter_values
            parameters = vcat(stack, [sum(convert(Matrix, v), dims = 2)])
        end
        stack = hcat(stack...)
        parameters = hcat(parameters...)
        trace = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
        seriescolor = set_seriescolor(seriescolors, gens)
        line_shape = get(kwargs, :stairs, "linear")
        i == 1 ? leg = true : leg = false
        for gen in 1:length(gens)
            push!(
                trace,
                Plots.PlotlyJS.scatter(;
                    name = gens[gen],
                    showlegend = leg,
                    x = time_range,
                    y = stack[:, gen],
                    stackgroup = "one",
                    mode = "lines",
                    line_shape = line_shape,
                    fill = "tonexty",
                    line_color = seriescolor[gen],
                    fillcolor = seriescolor[gen],
                ),
            )
        end
        if !isempty(params)
            for param in 1:length(params)
                push!(
                    trace,
                    Plots.PlotlyJS.scatter(;
                        name = params[param],
                        x = time_range,
                        y = parameters[:, param],
                        showlegend = leg,
                        stackgroup = "two",
                        mode = "lines",
                        line_shape = line_shape,
                        fill = "tozeroy",
                        line_color = "black",
                        line_dash = "dash",
                        line_width = "3",
                        fillcolor = "rgba(0, 0, 0, 0)",
                    ),
                )
            end
        end
        p = Plots.PlotlyJS.plot(
            trace,
            Plots.PlotlyJS.Layout(title = title, yaxis_title = ylabel),
        )
        plots = vcat(plots, p)
    end
    plots = vcat(plots...)
    set_display && Plots.display(plots)
    if !isnothing(reserve_list[1])
        for key in keys(reserve_list[1])
            r_plots = []
            for i in 1:length(reserve_list)
                i == 1 ? leg = true : leg = false
                time_range = IS.get_time_stamp(results[i])[:, 1]
                r_data = []
                r_gens = []
                r_traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
                for (k, v) in reserve_list[i][key]
                    r_data = vcat(r_data, [sum(convert(Matrix, v), dims = 2)])
                    r_gens = vcat(r_gens, k)
                end
                r_data = hcat(r_data...)
                r_seriescolor = set_seriescolor(seriescolors, r_gens)
                for gen in 1:size(r_gens, 1)
                    push!(
                        r_traces,
                        Plots.PlotlyJS.scatter(;
                            name = r_gens[gen],
                            x = time_range,
                            y = r_data[:, gen],
                            stackgroup = "one",
                            mode = "lines",
                            showlegend = leg,
                            line_shape = line_shape,
                            fill = "tonexty",
                            line_color = r_seriescolor[gen],
                            fillcolor = r_seriescolor[gen],
                        ),
                    )
                end
                r_plot = Plots.PlotlyJS.plot(
                    r_traces,
                    Plots.PlotlyJS.Layout(title = "$(key) Reserves", yaxis_title = ylabel),
                )
                r_plots = vcat(r_plots, r_plot)
            end
            r_plot = vcat(r_plots...)
            set_display && Plots.display(r_plot)
            if !isnothing(save_fig)
                Plots.PlotlyJS.savefig(
                    r_plot,
                    joinpath(save_fig, "$(key)_Reserves.$format");
                    width = 630,
                    height = 630,
                )
            end
            plot_output[Symbol("$(key)_Reserves")] = r_plot
        end
    end
    stack_title = line_shape == "linear" ? "Stack_Generation" : "Stair_Generation"
    title = title == " " ? stack_title : replace(title, " " => "_")
    if !isnothing(save_fig)
        Plots.PlotlyJS.savefig(
            plots,
            joinpath(save_fig, "$title.$format");
            width = 630,
            height = 630,
        )
    end
    plot_output[Symbol(title)] = plots
    return plot_output
end

function plotly_stack_plots(
    results::IS.Results,
    seriescolor::Array,
    ylabel::String;
    kwargs...,
)
    set_display = get(kwargs, :display, true)
    save_fig = get(kwargs, :save, nothing)
    line_shape = get(kwargs, :stair, false) ? "hv" : "linear"
    plot_list = Dict()
    for (key, var) in IS.get_variables(results)
        traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
        var = IS.get_variables(results)[key]
        gens = collect(names(var))
        seriescolor = set_seriescolor(seriescolor, gens)
        for gen in 1:length(gens)
            push!(
                traces,
                Plots.PlotlyJS.scatter(;
                    name = gens[gen],
                    x = results.time_stamp[:, 1],
                    y = convert(Matrix, var)[:, gen],
                    stackgroup = "one",
                    mode = "lines",
                    line_shape = line_shape,
                    line_color = seriescolor[gen],
                    fillcolor = "transparent",
                ),
            )
        end
        p = Plots.PlotlyJS.plot(
            traces,
            Plots.PlotlyJS.Layout(title = "$key", yaxis_title = ylabel),
        )
        set_display && Plots.display(p)
        if !isnothing(save_fig)
            format = get(kwargs, :format, "html")
            key_title = line_shape == "linear" ? "$(key)_Stack" : "$(key)_Stair"
            Plots.PlotlyJS.savefig(
                p,
                joinpath(save_fig, "$key_title.$format");
                width = 630,
                height = 630,
            )
        end
        plot_list[key] = p
    end
    return plot_list
end

function plotly_stack_plots(results::Array, seriescolor::Array, ylabel::String; kwargs...)
    set_display = get(kwargs, :display, true)
    save_fig = get(kwargs, :save, nothing)
    line_shape = get(kwargs, :stair, false) ? "hv" : "linear"
    _check_matching_variables(results)
    plot_list = Dict()
    for key in collect(keys(IS.get_variables(results[1, 1])))
        plots = []
        for res in 1:size(results, 2)
            traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
            var = IS.get_variables(results[1, res])[key]
            gens = collect(names(var))
            seriescolor = set_seriescolor(seriescolor, gens)
            for gen in 1:length(gens)
                leg = res == 1 ? true : false
                push!(
                    traces,
                    Plots.PlotlyJS.scatter(;
                        name = gens[gen],
                        showlegend = leg,
                        x = results[1, res].time_stamp[:, 1],
                        y = convert(Matrix, var)[:, gen],
                        stackgroup = "one",
                        mode = "lines",
                        line_shape = line_shape,
                        fill = "tonexty",
                        line_color = seriescolor[gen],
                        fillcolor = "transparent",
                    ),
                )
            end
            p = Plots.PlotlyJS.plot(
                traces,
                Plots.PlotlyJS.Layout(
                    title = "$key",
                    yaxis_title = ylabel,
                    grid = (rows = 3, columns = 1, pattern = "independent"),
                ),
            )
            plots = vcat(plots, p)
        end
        plots = vcat(plots...)
        set_display && Plots.display(plots)
        if !isnothing(save_fig)
            format = get(kwargs, :format, "html")
            key_title = line_shape == "linear" ? "$(key)_Stack" : "$(key)_Stair"
            Plots.PlotlyJS.savefig(
                plots,
                joinpath(save_fig, "$key_title.$format");
                width = 630,
                height = 630,
            )
        end
        plot_list[key] = plots
    end
    return plot_list
end

function plotly_fuel_stack_gen(
    stacked_gen::StackedGeneration,
    seriescolor::Array,
    title::String,
    ylabel::String;
    kwargs...,
)
    stair = get(kwargs, :stair, false)
    line_shape = stair ? "hv" : "linear"
    set_display = get(kwargs, :display, true)
    save_fig = get(kwargs, :save, nothing)
    traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
    gens = stacked_gen.labels
    seriescolor = set_seriescolor(seriescolor, gens)
    for gen in 1:length(gens)
        push!(
            traces,
            Plots.PlotlyJS.scatter(;
                name = gens[gen],
                x = stacked_gen.time_range,
                y = stacked_gen.data_matrix[:, gen],
                stackgroup = "one",
                mode = "lines",
                fill = "tonexty",
                line_color = seriescolor[gen],
                fillcolor = seriescolor[gen],
                line_shape = line_shape,
            ),
        )
    end
    if get(kwargs, :load, false) == true
        push!(
            traces,
            Plots.PlotlyJS.scatter(;
                name = "Load",
                x = stacked_gen.time_range,
                y = stacked_gen.parameters[:, 1],
                mode = "lines",
                line_color = "black",
                line_shape = line_shape,
                marker_size = 12,
            ),
        )
    end

    p = Plots.PlotlyJS.plot(
        traces,
        Plots.PlotlyJS.Layout(title = title, yaxis_title = ylabel),
    )
    set_display && Plots.display(p)
    if !isnothing(save_fig)
        format = get(kwargs, :format, "html")
        title = replace(title, " " => "_")
        Plots.PlotlyJS.savefig(
            p,
            joinpath(save_fig, "$title.$format");
            width = 630,
            height = 630,
        )
    end
    return p
end

function plotly_fuel_stack_gen(
    stacks::Array{StackedGeneration},
    seriescolor::Array,
    title::String,
    ylabel::String;
    kwargs...,
)
    line_shape = get(kwargs, :stair, false) ? "hv" : "linear"
    set_display = get(kwargs, :display, true)
    save_fig = get(kwargs, :save, nothing)
    plots = []
    for stack in 1:length(stacks)
        trace = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
        gens = stacks[stack].labels
        seriescolor = set_seriescolor(seriescolor, gens)
        for gen in 1:length(gens)
            leg = stack == 1 ? true : false
            push!(
                trace,
                Plots.PlotlyJS.scatter(;
                    name = gens[gen],
                    showlegend = leg,
                    x = stacks[stack].time_range,
                    y = stacks[stack].data_matrix[:, gen],
                    stackgroup = "one",
                    mode = "lines",
                    fill = "tonexty",
                    line_color = seriescolor[gen],
                    fillcolor = seriescolor[gen],
                    line_shape = line_shape,
                ),
            )
        end
        p = Plots.PlotlyJS.plot(
            trace,
            Plots.PlotlyJS.Layout(title = title, yaxis_title = ylabel),
        )
        plots = vcat(plots, p)
    end
    plots = vcat(plots...)
    set_display && Plots.display(plots)
    if !isnothing(save_fig)
        format = get(kwargs, :format, "html")
        title = replace(title, " " => "_")
        Plots.PlotlyJS.savefig(
            plots,
            joinpath(save_fig, "$title.$format");
            width = 630,
            height = 630,
        )
    end
    return plots
end
############################# PLOTLYJS BAR ##############################################
function _bar_plot_internal(
    res::IS.Results,
    backend::Plots.PlotlyJSBackend,
    save_fig::Any,
    set_display::Bool,
    interval::Float64,
    reserves::Any;
    kwargs...,
)
    seriescolor = get(kwargs, :seriescolor, PLOTLY_DEFAULT)
    title = get(kwargs, :title, " ")
    ylabel = _make_bar_ylabel(IS.get_base_power(res))
    plots = plotly_bar_plots(res, seriescolor, ylabel, interval; kwargs...)
    gen_plots =
        plotly_bar_gen(res, seriescolor, title, ylabel, interval, reserves; kwargs...)
    return PlotList(merge(plots, gen_plots))
end

function _bar_plot_internal(
    res::Array,
    backend::Plots.PlotlyJSBackend,
    save_fig::Any,
    set_display::Bool,
    interval::Float64,
    reserves::Any;
    kwargs...,
)
    seriescolor = get(kwargs, :seriescolor, PLOTLY_DEFAULT)
    title = get(kwargs, :title, " ")
    ylabel = _make_bar_ylabel(IS.get_base_power(res[1]))
    plots = plotly_bar_plots(res, seriescolor, ylabel, interval; kwargs...)
    gen_plots =
        plotly_bar_gen(res, seriescolor, title, ylabel, interval, reserves; kwargs...)
    return PlotList(merge(plots, gen_plots))
end

function plotly_fuel_bar_gen(
    bar_gen::BarGeneration,
    seriescolor::Array,
    title::String,
    ylabel::String,
    interval::Float64;
    kwargs...,
)
    time_range = convert.(Dates.DateTime, bar_gen.time_range)
    set_display = get(kwargs, :display, true)
    save_fig = get(kwargs, :save, nothing)
    time_span = IS.convert_compound_period(
        convert(Dates.TimePeriod, time_range[2] - time_range[1]) * length(time_range),
    )
    traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
    p_traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
    gens = bar_gen.labels
    params = bar_gen.p_labels
    seriescolor = set_seriescolor(seriescolor, gens)
    for gen in 1:length(gens)
        push!(
            traces,
            Plots.PlotlyJS.scatter(;
                name = gens[gen],
                x = ["$time_span, $(time_range[1])"],
                y = (bar_gen.bar_data[:, gen]) ./ interval,
                type = "bar",
                barmode = "stack",
                stackgroup = "one",
                marker_color = seriescolor[gen],
            ),
        )
    end
    #=
    for param in 1:length(params)
        push!(
            p_traces,
            Plots.PlotlyJS.scatter(;
                name = params[param],
                x = ["$time_span, $(time_range[1])"],
                y = bar_gen.parameters[:, param],
                type = "bar",
                stackgroup = "two",
                marker_color = "rgba(0, 0, 0, 0)",
                marker_line_color = "rgba(0, 0, 0, 0.6)",
                marker_line_width=1.5,
            ),
        )
    end
    =#
    p = Plots.PlotlyJS.plot(
        traces,
        Plots.PlotlyJS.Layout(
            title = title,
            yaxis_title = ylabel,
            color = seriescolor,
            barmode = "stack",
        ),
    )
    set_display && Plots.display(p)
    if !isnothing(save_fig)
        title = title == " " ? "Bar_Generation" : replace(title, " " => "_")
        format = get(kwargs, :format, "html")
        Plots.PlotlyJS.savefig(
            p,
            joinpath(save_fig, "$title.$format");
            width = 630,
            height = 630,
        )
    end
    return p
end

function plotly_fuel_bar_gen(
    bar_gen::Array{BarGeneration},
    seriescolor::Array,
    title::String,
    ylabel::String,
    interval::Float64;
    kwargs...,
)
    time_range = bar_gen[1].time_range
    set_display = get(kwargs, :display, true)
    save_fig = get(kwargs, :save, nothing)
    time_span = IS.convert_compound_period(
        convert(Dates.TimePeriod, time_range[2] - time_range[1]) * length(time_range),
    )
    seriescolor = set_seriescolor(seriescolor, bar_gen[1].labels)
    plots = []
    for bar in 1:length(bar_gen)
        traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
        p_traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
        gens = bar_gen[bar].labels
        params = bar_gen[bar].p_labels
        for gen in 1:length(gens)
            leg = bar == 1 ? true : false
            push!(
                traces,
                Plots.PlotlyJS.scatter(;
                    name = gens[gen],
                    showlegend = leg,
                    x = ["$time_span, $(time_range[1])"],
                    y = (bar_gen[bar].bar_data[:, gen]) ./ interval,
                    type = "bar",
                    barmode = "stack",
                    marker_color = seriescolor[gen],
                ),
            )
        end
        #=
        for param in 1:length(params)
            push!(
                p_traces,
                Plots.PlotlyJS.scatter(;
                    name = params[param],
                    x = ["$time_span, $(time_range[1])"],
                    y = bar_gen.parameters[:, param],
                    type = "bar",
                    marker_color = "rgba(0, 0, 0, .1)",
                ),
            )
        end
        =#
        p = Plots.PlotlyJS.plot(
            [traces; p_traces],
            Plots.PlotlyJS.Layout(
                title = title,
                yaxis_title = ylabel,
                color = seriescolor,
                barmode = "overlay",
            ),
        )
        plots = vcat(plots, p)
    end
    plots = vcat(plots...)
    set_display && Plots.display(plots)
    if !isnothing(save_fig)
        title = title == " " ? "Bar_Generation" : replace(title, " " => "_")
        format = get(kwargs, :format, "html")
        Plots.PlotlyJS.savefig(
            plots,
            joinpath(save_fig, "$title.$format");
            width = 630,
            height = 630,
        )
    end
    return plots
end

function plotly_bar_gen(
    res::IS.Results,
    seriescolor::Array,
    title::String,
    ylabel::String,
    interval::Float64,
    reserves::Any;
    kwargs...,
)
    time_range = IS.get_time_stamp(res)[:, 1]
    set_display = get(kwargs, :display, true)
    save_fig = get(kwargs, :save, nothing)
    format = get(kwargs, :format, "html")
    plot_output = Dict()
    time_span = IS.convert_compound_period(
        convert(Dates.TimePeriod, time_range[2] - time_range[1]) * length(time_range),
    )
    traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
    p_traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
    gens = collect(keys(IS.get_variables(res)))
    params = collect(keys((res.parameter_values)))
    seriescolors = set_seriescolor(seriescolor, gens)
    data = []
    for (k, v) in IS.get_variables(res)
        data = vcat(data, [sum(sum(convert(Matrix, v), dims = 2), dims = 1)])
    end
    bar_data = hcat(data...) ./ interval
    p_data = []
    for (p, v) in res.parameter_values
        p_data = vcat(p_data, [sum(sum(convert(Matrix, v), dims = 2), dims = 1)])
    end
    p_data = hcat(p_data...) ./ interval
    for gen in 1:length(gens)
        push!(
            traces,
            Plots.PlotlyJS.scatter(;
                name = gens[gen],
                x = ["$time_span, $(time_range[1])"],
                y = bar_data[:, gen],
                type = "bar",
                barmode = "stack",
                stackgroup = "one",
                marker_color = seriescolors[gen],
            ),
        )
    end
    #=
    for param in 1:length(params)
        push!(
            p_traces,
            Plots.PlotlyJS.scatter(;
                name = params[param],
                x = ["$time_span, $(time_range[1])"],
                y = param_bar_data[:, param],
                type = "bar",
                stackgroup = "two",
                marker_color = "rgba(0, 0, 0, 0)",
                marker_line_color = "rgba(0, 0, 0, 0.6)",
                marker_line_width=1.5,
            ),
        )
    end
    =#
    p = Plots.PlotlyJS.plot(
        traces,
        Plots.PlotlyJS.Layout(
            title = title,
            yaxis_title = ylabel,
            color = seriescolor,
            barmode = "stack",
        ),
    )
    set_display && Plots.display(p)
    title = title == " " ? "Bar_Generation" : replace(title, " " => "_")
    if !isnothing(save_fig)
        Plots.PlotlyJS.savefig(
            p,
            joinpath(save_fig, "$title.$format");
            width = 630,
            height = 630,
        )
    end
    plot_output[Symbol(title)] = p
    if !isnothing(reserves)
        reserve_plots = []
        for (key, reserve) in reserves
            r_traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
            r_data = []
            for (k, v) in reserve
                r_data = vcat(r_data, [sum(sum(convert(Matrix, v), dims = 2), dims = 1)])
            end
            r_data = hcat(r_data...) / interval
            r_gens = collect(keys(reserve))
            r_seriescolors = set_seriescolor(seriescolor, r_gens)
            for gen in 1:length(r_gens)
                push!(
                    r_traces,
                    Plots.PlotlyJS.scatter(;
                        name = r_gens[gen],
                        x = ["$time_span, $(time_range[1])"],
                        y = r_data[:, gen],
                        type = "bar",
                        barmode = "stack",
                        stackgroup = "one",
                        marker_color = r_seriescolors[gen],
                    ),
                )
            end
            r_plot = Plots.PlotlyJS.plot(
                r_traces,
                Plots.PlotlyJS.Layout(
                    title = "$(key) Reserves",
                    yaxis_title = ylabel,
                    color = seriescolor,
                    barmode = "stack",
                ),
            )
            set_display && Plots.display(r_plot)#, Plots.display(down_plot)
            if !isnothing(save_fig)
                Plots.PlotlyJS.savefig(
                    r_plot,
                    joinpath(save_fig, "$(key)_Reserves.$format");
                    width = 630,
                    height = 630,
                )
            end
            reserve_plots = vcat(reserve_plots, r_plot)
            plot_output[Symbol("$(key)_Reserves")] = r_plot
        end
    end
    return plot_output
end

function plotly_bar_gen(
    results::Array,
    seriescolor::Array,
    title::String,
    ylabel::String,
    interval::Float64,
    reserve_list::Any;
    kwargs...,
)
    time_range = IS.get_time_stamp(results[1])[:, 1]
    set_display = get(kwargs, :display, true)
    save_fig = get(kwargs, :save, nothing)
    format = get(kwargs, :format, "html")
    time_span = IS.convert_compound_period(
        convert(Dates.TimePeriod, time_range[2] - time_range[1]) * length(time_range),
    )
    plots = []
    plot_output = Dict()
    for i in 1:length(results)
        traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
        p_traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
        gens = collect(keys(IS.get_variables(results[i])))
        seriescolors = set_seriescolor(seriescolor, gens)
        params = collect(keys((results[i].parameter_values)))
        data = []
        for (k, v) in IS.get_variables(results[i])
            data = vcat(data, [sum(sum(convert(Matrix, v), dims = 2), dims = 1)])
        end
        data = hcat(data...) ./ interval
        p_data = []
        for (p, v) in results[i].parameter_values
            p_data = vcat(p_data, [sum(sum(convert(Matrix, v), dims = 2), dims = 1)])
        end
        p_data = hcat(p_data...) ./ interval
        for gen in 1:length(gens)
            i == 1 ? leg = true : leg = false
            push!(
                traces,
                Plots.PlotlyJS.scatter(;
                    name = gens[gen],
                    showlegend = leg,
                    x = ["$time_span, $(time_range[1])"],
                    y = data[:, gen],
                    type = "bar",
                    barmode = "stack",
                    marker_color = seriescolors[gen],
                ),
            )
        end
        #=
        for param in 1:length(params)
            push!(
                p_traces,
                Plots.PlotlyJS.scatter(;
                    name = params[param],
                    x = ["$time_span, $(time_range[1])"],
                    y = bar_gen.parameters[:, param],
                    type = "bar",
                    marker_color = "rgba(0, 0, 0, .1)",
                ),
            )
        end
        =#
        p = Plots.PlotlyJS.plot(
            [traces; p_traces],
            Plots.PlotlyJS.Layout(
                title = title,
                yaxis_title = ylabel,
                color = seriescolors,
                barmode = "overlay",
            ),
        )
        plots = vcat(plots, p)
    end
    plots = vcat(plots...)
    set_display && Plots.display(plots)
    title = title == " " ? "Bar_Generation" : title
    title = replace(title, " " => "_")
    plot_output[Symbol(title)] = plots
    if !isnothing(save_fig)
        format = get(kwargs, :format, "html")
        Plots.PlotlyJS.savefig(
            plots,
            joinpath(save_fig, "$title.$format");
            width = 630,
            height = 630,
        )
    end
    if !isnothing(reserve_list[1])
        for key in keys(reserve_list[1])
            r_plots = []
            for i in 1:length(reserve_list)
                r_data = []
                for (k, v) in reserve_list[i][key]
                    r_data =
                        vcat(r_data, [sum(sum(convert(Matrix, v), dims = 2), dims = 1)])
                end
                r_data = hcat(r_data...) / interval
                r_gens = collect(keys(reserve_list[i][key]))
                r_traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
                r_seriescolor = set_seriescolor(seriescolor, r_gens)
                for gen in 1:length(r_gens)
                    i == 1 ? leg = true : leg = false
                    push!(
                        r_traces,
                        Plots.PlotlyJS.scatter(;
                            name = r_gens[gen],
                            x = ["$time_span, $(time_range[1])"],
                            y = r_data[:, gen],
                            type = "bar",
                            barmode = "stack",
                            stackgroup = "one",
                            marker_color = r_seriescolor[gen],
                            showlegend = leg,
                        ),
                    )
                end
                r_plot = Plots.PlotlyJS.plot(
                    r_traces,
                    Plots.PlotlyJS.Layout(
                        title = "$(key) Reserves",
                        yaxis_title = ylabel,
                        color = seriescolor,
                        barmode = "stack",
                    ),
                )
                r_plots = vcat(r_plots, r_plot)
            end
            r_plot = vcat(r_plots...)
            set_display && Plots.display(r_plot)
            if !isnothing(save_fig)
                Plots.PlotlyJS.savefig(
                    r_plot,
                    joinpath(save_fig, "$(key)_Reserves.$format");
                    width = 630,
                    height = 630,
                )
            end
            plot_output[Symbol("$(key)_Reserves")] = r_plot
        end
    end
    return plot_output
end

function plotly_bar_plots(
    results::Array,
    seriescolor::Array,
    ylabel::String,
    interval::Float64;
    kwargs...,
)
    set_display = get(kwargs, :display, true)
    save_fig = get(kwargs, :save, nothing)
    time_range = results[1].time_stamp
    time_span = IS.convert_compound_period(
        convert(Dates.TimePeriod, time_range[2, 1] - time_range[1, 1]) *
        size(time_range, 1),
    )
    plot_list = Dict()
    for key in collect(keys(IS.get_variables(results[1])))
        plots = []
        for res in 1:length(results)
            var = IS.get_variables(results[res])[key]
            traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
            gens = collect(names(var))
            seriescolor = set_seriescolor(seriescolor, gens)
            for gen in 1:length(gens)
                leg = res == 1 ? true : false
                push!(
                    traces,
                    Plots.PlotlyJS.scatter(;
                        name = gens[gen],
                        showlegend = leg,
                        x = ["$time_span, $(time_range[1, 1])"],
                        y = sum(convert(Matrix, var)[:, gen], dims = 1) ./ interval,
                        type = "bar",
                        barmode = "stack",
                        marker_color = seriescolor[gen],
                    ),
                )
            end
            p = Plots.PlotlyJS.plot(
                traces,
                Plots.PlotlyJS.Layout(
                    title = "$key",
                    yaxis_title = ylabel,
                    barmode = "stack",
                ),
            )
            plots = vcat(plots, p)
        end
        plot = vcat(plots...)
        set_display && Plots.display(plot)
        if !isnothing(save_fig)
            format = get(kwargs, :format, "html")
            Plots.PlotlyJS.savefig(
                plot,
                joinpath(save_fig, "$(key)_Bar.$format");
                width = 630,
                height = 630,
            )
        end
        plot_list[key] = plot
    end
    return plot_list
end

function plotly_bar_plots(
    res::IS.Results,
    seriescolor::Array,
    ylabel::String,
    interval::Float64;
    kwargs...,
)
    set_display = get(kwargs, :display, true)
    save_fig = get(kwargs, :save, nothing)
    time_range = IS.get_time_stamp(res)
    time_span = IS.convert_compound_period(
        convert(Dates.TimePeriod, time_range[2, 1] - time_range[1, 1]) *
        size(time_range, 1),
    )
    plot_list = Dict()
    for (key, var) in IS.get_variables(res)
        traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
        gens = collect(names(var))
        seriescolor = set_seriescolor(seriescolor, gens)
        for gen in 1:length(gens)
            push!(
                traces,
                Plots.PlotlyJS.scatter(;
                    name = gens[gen],
                    x = ["$time_span, $(time_range[1, 1])"],
                    y = sum(convert(Matrix, var)[:, gen], dims = 1) ./ interval,
                    type = "bar",
                    barmode = "stack",
                    marker_color = seriescolor[gen],
                ),
            )
        end
        p = Plots.PlotlyJS.plot(
            traces,
            Plots.PlotlyJS.Layout(barmode = "stack", title = "$key", yaxis_title = ylabel),
        )
        set_display && Plots.display(p)
        if !isnothing(save_fig)
            format = get(kwargs, :format, "html")
            Plots.PlotlyJS.savefig(
                p,
                joinpath(save_fig, "$(key)_Bar.$format");
                width = 630,
                height = 630,
            )
        end
        plot_list[key] = p
    end
    return plot_list
end

###################################### PLOTLYJS FUEL ################################
function _fuel_plot_internal(
    stack::Union{StackedGeneration, Array{StackedGeneration}},
    bar::Union{BarGeneration, Array{BarGeneration}},
    seriescolor::Array,
    backend::Plots.PlotlyJSBackend,
    save_fig::Any,
    set_display::Bool,
    title::String,
    ylabel::String,
    interval::Float64;
    kwargs...,
)
    stair = get(kwargs, :stair, false)
    stack_title = stair ? "$(title) Stair" : stack_title = "$(title) Stack"
    stacks = plotly_fuel_stack_gen(stack, seriescolor, stack_title, ylabel; kwargs...)
    bars =
        plotly_fuel_bar_gen(bar, seriescolor, "$(title) Bar", ylabel, interval; kwargs...)
    return PlotList(Dict(:Fuel_Stack => stacks, :Fuel_Bar => bars))
end

############################## PLOTLYJS DEMAND PLOTS ##########################

function _demand_plot_internal(res::IS.Results, backend::Plots.PlotlyJSBackend; kwargs...)
    seriescolor = get(kwargs, :seriescolor, PLOTLY_DEFAULT)
    line_shape = get(kwargs, :stair, false) ? "hv" : "linear"
    save_fig = get(kwargs, :save, nothing)
    set_display = get(kwargs, :display, true)
    ylabel = _make_ylabel(IS.get_base_power(res))
    plot_list = Dict()
    for (key, parameters) in res.parameter_values
        traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
        param_names = names(parameters)
        n_traces = length(param_names)
        seriescolor = length(seriescolor) < n_traces ?
            repeat(seriescolor, Int64(ceil(n_traces / length(seriescolor)))) : seriescolor
        title = get(kwargs, :title, "$key")
        for i in 1:n_traces
            push!(
                traces,
                Plots.PlotlyJS.scatter(;
                    name = param_names[i],
                    x = res.time_stamp[:, 1],
                    y = parameters[:, param_names[i]],
                    stackgroup = "one",
                    mode = "lines",
                    fill = "tonexty",
                    line_color = seriescolor[i],
                    line_shape = line_shape,
                ),
            )
        end
        format = get(kwargs, :format, "html")
        p = Plots.PlotlyJS.plot(
            traces,
            Plots.PlotlyJS.Layout(title = title, yaxis_title = ylabel),
        )
        set_display && Plots.display(p)
        if !isnothing(save_fig)
            title = replace(title, " " => "_")
            Plots.PlotlyJS.savefig(
                p,
                joinpath(save_fig, "$title.$format");
                width = 630,
                height = 630,
            )
        end
        plot_list[key] = p
    end
    return PlotList(plot_list)
end

function _demand_plot_internal(results::Array, backend::Plots.PlotlyJSBackend; kwargs...)
    seriescolor = get(kwargs, :seriescolor, PLOTLY_DEFAULT)
    save_fig = get(kwargs, :save, nothing)
    set_display = get(kwargs, :display, true)
    ylabel = _make_ylabel(IS.get_base_power(results[1]))
    line_shape = get(kwargs, :stair, false) ? "hv" : "linear"
    plot_list = Dict()
    for (key, parameters) in results[1].parameter_values
        plots = []
        title = get(kwargs, :title, "$key")
        for n in 1:length(results)
            traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
            parameters = results[n].parameter_values[key]
            p_names = collect(names(parameters))
            n_traces = length(p_names)
            seriescolor = length(seriescolor) < n_traces ?
                repeat(seriescolor, Int64(ceil(n_traces / length(seriescolor)))) :
                seriescolor
            n == 1 ? leg = true : leg = false
            for i in 1:n_traces
                push!(
                    traces,
                    Plots.PlotlyJS.scatter(;
                        name = p_names[i],
                        x = results[n].time_stamp[:, 1],
                        y = parameters[:, p_names[i]],
                        stackgroup = "one",
                        mode = "lines",
                        fill = "tonexty",
                        line_color = seriescolor[i],
                        showlegend = leg,
                    ),
                )
            end
            title = get(kwargs, :title, "$key")
            p = Plots.PlotlyJS.plot(
                traces,
                Plots.PlotlyJS.Layout(title = title, yaxis_title = ylabel),
            )
            plots = vcat(plots, p)
        end
        plots = vcat(plots...)
        set_display && Plots.display(plots)
        if !isnothing(save_fig)
            format = get(kwargs, :format, "html")
            Plots.PlotlyJS.savefig(
                plots,
                joinpath(save_fig, "$title.$format");
                width = 630,
                height = 630,
            )
        end
        plot_list[key] = plots
    end
    return PlotList(plot_list)
end

################################ SYSTEM DEMAND PLOTS ###################################

function _demand_plot_internal(
    parameters::DataFrames.DataFrame,
    basepower::Float64,
    backend::Plots.PlotlyJSBackend;
    kwargs...,
)
    line_shape = get(kwargs, :stair, false) ? "hv" : "linear"
    save_fig = get(kwargs, :save, nothing)
    set_display = get(kwargs, :display, true)
    ylabel = _make_ylabel(basepower)
    plot_list = Dict()
    traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
    data = DataFrames.select(parameters, DataFrames.Not(:timestamp))
    param_names = names(data)
    n_traces = length(param_names)
    seriescolor = get(kwargs, :seriescolor, PLOTLY_DEFAULT)#repeat([PLOTLY_DEFAULT], n_traces))
    seriescolor = length(seriescolor) < n_traces ?
        repeat(seriescolor, Int64(ceil(n_traces / length(seriescolor)))) : seriescolor
    title = get(kwargs, :title, "PowerLoad")
    for i in 1:n_traces
        push!(
            traces,
            Plots.PlotlyJS.scatter(;
                name = param_names[i],
                x = parameters[:, :timestamp],
                y = data[:, param_names[i]],
                stackgroup = "one",
                mode = "lines",
                fill = "tonexty",
                line_color = seriescolor[i],
                line_shape = line_shape,
            ),
        )
    end
    format = get(kwargs, :format, "html")
    p = Plots.PlotlyJS.plot(
        traces,
        Plots.PlotlyJS.Layout(title = title, yaxis_title = ylabel),
    )
    set_display && Plots.display(p)
    if !isnothing(save_fig)
        title = replace(title, " " => "_")
        Plots.PlotlyJS.savefig(
            p,
            joinpath(save_fig, "$title.$format");
            width = 630,
            height = 630,
        )
    end
    plot_list[Symbol(title)] = p
    return PlotList(plot_list)
end

function _demand_plot_internal(
    parameters::Array,
    basepower::Array,
    backend::Plots.PlotlyJSBackend;
    kwargs...,
)
    n_traces = length(parameters[1])
    seriescolor = get(kwargs, :seriescolor, PLOTLY_DEFAULT)
    seriescolor = length(seriescolor) < n_traces ?
        repeat(seriescolor, Int64(ceil(n_traces / length(seriescolor)))) : seriescolor
    save_fig = get(kwargs, :save, nothing)
    set_display = get(kwargs, :display, true)
    line_shape = get(kwargs, :stair, false) ? "hv" : "linear"
    plot_list = Dict()
    plots = []
    title = get(kwargs, :title, "PowerLoad")
    for i in 1:length(parameters)
        data = DataFrames.select(parameters[i], DataFrames.Not(:timestamp))
        p_names = collect(names(data))
        ylabel = _make_ylabel(basepower[i])
        traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
        for n in 1:length(p_names)
            i == 1 ? leg = true : leg = false
            push!(
                traces,
                Plots.PlotlyJS.scatter(;
                    name = p_names[n],
                    x = parameters[i][:, :timestamp],
                    y = data[:, p_names[n]],
                    stackgroup = "one",
                    mode = "lines",
                    fill = "tonexty",
                    line_color = seriescolor[n],
                    showlegend = leg,
                ),
            )
        end
        p = Plots.PlotlyJS.plot(
            traces,
            Plots.PlotlyJS.Layout(title = title, yaxis_title = ylabel),
        )
        plots = vcat(plots, p)
    end
    plots = vcat(plots...)
    set_display && Plots.display(plots)
    if !isnothing(save_fig)
        format = get(kwargs, :format, "html")
        title = replace(title, " " => "_")
        Plots.PlotlyJS.savefig(
            plots,
            joinpath(save_fig, "$title.$format");
            width = 630,
            height = 630,
        )
    end
    plot_list[Symbol(title)] = plots
    return PlotList(plot_list)
end

function _reserve_plot(res::IS.Results, backend::Plots.PlotlyJSBackend; kwargs...)
    reserves = _filter_reserves(res, true)
    time_interval = IS.get_time_stamp(res)[2, 1] - IS.get_time_stamp(res)[1, 1]
    interval = Dates.Millisecond(Dates.Hour(1)) / time_interval
    seriescolor = get(kwargs, :seriescolor, PLOTLY_DEFAULT)
    set_display = get(kwargs, :display, true)
    line_shape = get(kwargs, :stair, false) ? "hv" : "linear"
    save_fig = get(kwargs, :save, nothing)
    ylabel = _make_ylabel(IS.get_base_power(res))
    bar_ylabel = _make_bar_ylabel(IS.get_base_power(res))
    time_range = IS.get_time_stamp(res)[:, 1]
    time_span = IS.convert_compound_period(
        convert(Dates.TimePeriod, time_range[2] - time_range[1]) * length(time_range),
    )
    format = get(kwargs, :format, "html")
    plot_list = Dict()
    if !isnothing(reserves)
        for (key, reserve) in reserves
            stack_data = []
            stack_gens = []
            stack_traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
            for (k, v) in reserve
                stack_data = vcat(stack_data, [sum(convert(Matrix, v), dims = 2)])
                stack_gens = vcat(stack_gens, k)
            end
            stack_data = hcat(stack_data...)
            up_seriescolor = set_seriescolor(seriescolor, stack_gens)
            for gen in 1:size(stack_gens, 1)
                push!(
                    stack_traces,
                    Plots.PlotlyJS.scatter(;
                        name = stack_gens[gen],
                        x = time_range,
                        y = stack_data[:, gen],
                        stackgroup = "one",
                        mode = "lines",
                        showlegend = true,
                        line_shape = line_shape,
                        fill = "tonexty",
                        line_color = up_seriescolor[gen],
                        fillcolor = up_seriescolor[gen],
                    ),
                )
            end
            stack_plot = Plots.PlotlyJS.plot(
                stack_traces,
                Plots.PlotlyJS.Layout(title = "$(key) Reserves", yaxis_title = ylabel),
            )
            #bar
            bar_traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
            bar_data = []
            for (k, v) in reserve
                bar_data =
                    vcat(bar_data, [sum(sum(convert(Matrix, v), dims = 2), dims = 1)])
            end
            bar_data = hcat(bar_data...) / interval
            bar_gens = collect(keys(reserve))
            bar_seriescolors = set_seriescolor(seriescolor, bar_gens)
            for gen in 1:length(bar_gens)
                push!(
                    bar_traces,
                    Plots.PlotlyJS.scatter(;
                        name = bar_gens[gen],
                        x = ["$time_span, $(time_range[1])"],
                        y = bar_data[:, gen],
                        type = "bar",
                        barmode = "stack",
                        stackgroup = "one",
                        marker_color = bar_seriescolors[gen],
                    ),
                )
            end
            bar_plot = Plots.PlotlyJS.plot(
                bar_traces,
                Plots.PlotlyJS.Layout(
                    title = "$(key) Reserves",
                    yaxis_title = ylabel,
                    color = seriescolor,
                    barmode = "stack",
                ),
            )
            set_display && Plots.display(stack_plot), Plots.display(bar_plot)
            if !isnothing(save_fig)
                Plots.PlotlyJS.savefig(
                    stack_plot,
                    joinpath(save_fig, "Stack_$(key)_Reserves.$format");
                    width = 630,
                    height = 630,
                )
                Plots.PlotlyJS.savefig(
                    bar_plot,
                    joinpath(save_fig, "Bar_$(key)_Reserves.$format");
                    width = 630,
                    height = 630,
                )
            end
            plot_list[Symbol("Stack_$(key)_Reserves")] = stack_plot
            plot_list[Symbol("Bar_$(key)_Reserves")] = bar_plot
        end
    end
end

function _variable_plots_internal(
    res::IS.Results,
    variable::Symbol,
    backend::Plots.PlotlyJSBackend,
    interval::Float64;
    kwargs...,
)
    seriescolor = get(kwargs, :seriescolor, PLOTLY_DEFAULT)
    y_label = _make_ylabel(IS.get_base_power(res))
    plotlist = Dict()
    stack = get(kwargs, :stair, false) ? "Stair" : "Stack"
    plotlist["$(stack)_$(variable)"] =
        plotly_stack_plots(res, seriescolor, y_label; kwargs...)
    return PlotList(plotlist)
end
