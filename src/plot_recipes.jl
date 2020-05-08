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

### PlotlyJS set up
function set_seriescolor(seriescolor::Array, gens::Array)
    colors = []
    for i in 1:length(gens)
        count = i % length(seriescolor)
        if count == 0
            count = length(seriescolor)
        end
        colors = vcat(colors, seriescolor[count])
    end
    return colors
end

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

########################################## PLOTLYJS STACK ##########################
function _stack_plot_internal(
    res::IS.Results,
    backend::Plots.PlotlyJSBackend,
    save_fig::Any,
    set_display::Bool;
    kwargs...,
)
    seriescolor = get(kwargs, :seriescolor, PLOTLY_DEFAULT)
    title = get(kwargs, :title, " ")
    ylabel = _make_ylabel(IS.get_base_power(res))
    stack = plotly_stack_plots(res, seriescolor, ylabel; kwargs...)
    if title == " "
        plot_title = :Stack_Generation
    else
        plot_title = Symbol(title)
    end
    stack[plot_title] = plotly_stack_gen(res, seriescolor, title, ylabel; kwargs...)
    return PlotList(stack)
end

function _stack_plot_internal(
    res::Array{},
    backend::Plots.PlotlyJSBackend,
    save_fig::Any,
    set_display::Bool;
    kwargs...,
)
    seriescolor = get(kwargs, :seriescolor, PLOTLY_DEFAULT)
    title = get(kwargs, :title, " ")
    ylabel = _make_ylabel(IS.get_base_power(res[1]))
    stack = plotly_stack_plots(res, seriescolor, ylabel; kwargs...)
    if title == " "
        plot_title = :Stack_Generation
    else
        plot_title = Symbol(title)
    end
    stack[plot_title] = plotly_stack_gen(res, seriescolor, title, ylabel; kwargs...)
    return PlotList(stack)
end

function plotly_stack_gen(
    res::IS.Results,
    seriescolor::Array,
    title::String,
    ylabel::String;
    kwargs...,
)
    set_display = get(kwargs, :display, true)
    line_shape = get(kwargs, :stairs, "linear")
    save_fig = get(kwargs, :save, nothing)
    traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
    gens = collect(keys(IS.get_variables(res)))
    params = collect(keys(res.parameter_values))
    time_range = IS.get_time_stamp(res)[:, 1]
    stack = []
    for (k, v) in IS.get_variables(res)
        stack = vcat(stack, [sum(convert(Matrix, v), dims = 2)])
    end
    stack = hcat(stack...)
    parameters = []
    for (p, v) in res.parameter_values
        parameters = vcat(stack, [sum(convert(Matrix, v), dims = 2)])
    end
    parameters = hcat(parameters...)
    seriescolor = set_seriescolor(seriescolor, gens)
    for gen in 1:length(gens)
        push!(
            traces,
            Plots.PlotlyJS.scatter(;
                name = gens[gen],
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
    if !isnothing(save_fig)
        if title == " "
            if line_shape == "linear"
                title = "Stack_Generation"
            else
                title = "Stair_Generation"
            end
        end
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

function plotly_stack_gen(
    results::Array,
    seriescolor::Array,
    title::String,
    ylabel::String;
    kwargs...,
)
    set_display = get(kwargs, :display, true)
    line_shape = get(kwargs, :stairs, "linear")
    save_fig = get(kwargs, :save, nothing)
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
        seriescolor = set_seriescolor(seriescolor, gens)
        line_shape = get(kwargs, :stairs, "linear")
        if i == 1
            leg = true
        else
            leg = false
        end
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
    if !isnothing(save_fig)
        if title == " "
            if line_shape == "linear"
                title = "Stack_Generation"
            else
                title = "Stair_Generation"
            end
        end
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

function plotly_stack_plots(
    results::IS.Results,
    seriescolor::Array,
    ylabel::String;
    kwargs...,
)
    set_display = get(kwargs, :display, true)
    save_fig = get(kwargs, :save, nothing)
    line_shape = get(kwargs, :stairs, "linear")
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
                    fill = "tonexty",
                    line_color = seriescolor[gen],
                    fillcolor = seriescolor[gen],
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
            if line_shape == "linear"
                key_title = "$(key)_Stack"
            else
                key_title = "$(key)_Stair"
            end
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
    line_shape = get(kwargs, :stairs, "linear")
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
                if res == 1
                    leg = true
                else
                    leg = false
                end
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
                        fillcolor = seriescolor[gen],
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
            if line_shape == "linear"
                key_title = "$(key)_Stack"
            else
                key_title = "$(key)_Stair"
            end
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
    stair = get(kwargs, :stair, false)
    if stair
        line_shape = "hv"
    else
        line_shape = "linear"
    end
    set_display = get(kwargs, :display, true)
    save_fig = get(kwargs, :save, nothing)
    line_shape = get(kwargs, :stair, "linear")
    plots = []
    for stack in 1:length(stacks)
        trace = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
        gens = stacks[stack].labels
        seriescolor = set_seriescolor(seriescolor, gens)
        for gen in 1:length(gens)
            if stack == 1
                leg = true
            else
                leg = false
            end
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
    set_display::Bool;
    kwargs...,
)
    seriescolor = get(kwargs, :seriescolor, PLOTLY_DEFAULT)
    title = get(kwargs, :title, " ")
    ylabel = _make_ylabel(IS.get_base_power(res))
    plots = plotly_bar_plots(res, seriescolor, ylabel; kwargs...)
    if title == " "
        plot_title = :Bar_Generation
    else
        plot_title = Symbol(title)
    end
    plots[plot_title] = plotly_bar_gen(res, seriescolor, title, ylabel; kwargs...)
    return PlotList(plots)
end

function _bar_plot_internal(
    res::Array,
    backend::Plots.PlotlyJSBackend,
    save_fig::Any,
    set_display::Bool;
    kwargs...,
)
    seriescolor = get(kwargs, :seriescolor, PLOTLY_DEFAULT)
    title = get(kwargs, :title, " ")
    ylabel = _make_ylabel(IS.get_base_power(res[1]))
    plots = plotly_bar_plots(res, seriescolor, ylabel; kwargs...)
    if title == " "
        plot_title = :Bar_Generation
    else
        plot_title = Symbol(title)
    end
    plots[plot_title] = plotly_bar_gen(res, seriescolor, title, ylabel; kwargs...)
    return PlotList(plots)
end

function plotly_fuel_bar_gen(
    bar_gen::BarGeneration,
    seriescolor::Array,
    title::String,
    ylabel::String;
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
                y = bar_gen.bar_data[:, gen],
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
        if title == " "
            title = "Bar_Generation"
        end
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

function plotly_fuel_bar_gen(
    bar_gen::Array{BarGeneration},
    seriescolor::Array,
    title::String,
    ylabel::String;
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
            if bar == 1
                leg = true
            else
                leg = false
            end
            push!(
                traces,
                Plots.PlotlyJS.scatter(;
                    name = gens[gen],
                    showlegend = leg,
                    x = ["$time_span, $(time_range[1])"],
                    y = bar_gen[bar].bar_data[:, gen],
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
        if title == " "
            title = "Bar_Generation"
        end
        title = replace(title, " " => "_")
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
    ylabel::String;
    kwargs...,
)
    time_range = IS.get_time_stamp(res)[:, 1]
    set_display = get(kwargs, :display, true)
    save_fig = get(kwargs, :save, nothing)
    time_span = IS.convert_compound_period(
        convert(Dates.TimePeriod, time_range[2] - time_range[1]) * length(time_range),
    )
    traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
    p_traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
    gens = collect(keys(IS.get_variables(res)))
    params = collect(keys((res.parameter_values)))
    seriescolor = set_seriescolor(seriescolor, gens)
    data = []
    for (k, v) in IS.get_variables(res)
        data = vcat(data, [sum(Matrix(v), dims = 2)])
    end
    bar_data = hcat(data...)
    p_data = []
    for (p, v) in res.parameter_values
        p_data = vcat(p_data, [sum(convert(Matrix, v), dims = 1)])
    end
    p_data = hcat(p_data...)
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
    if !isnothing(save_fig)
        if title == " "
            title = "Bar_Generation"
        end
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

function plotly_bar_gen(
    results::Array,
    seriescolor::Array,
    title::String,
    ylabel::String;
    kwargs...,
)
    time_range = IS.get_time_stamp(results[1])[:, 1]
    set_display = get(kwargs, :display, true)
    save_fig = get(kwargs, :save, nothing)
    time_span = IS.convert_compound_period(
        convert(Dates.TimePeriod, time_range[2] - time_range[1]) * length(time_range),
    )
    plots = []
    for res in results
        traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
        p_traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
        gens = collect(keys(IS.get_variables(res)))
        seriescolor = set_seriescolor(seriescolor, gens)
        params = collect(keys((res.parameter_values)))
        data = []
        for (k, v) in IS.get_variables(res)
            data = vcat(data, [sum(convert(Matrix, v), dims = 1)])
        end
        data = hcat(data...)
        p_data = []
        for (p, v) in res.parameter_values
            p_data = vcat(p_data, [sum(convert(Matrix, v), dims = 1)])
        end
        p_data = hcat(p_data...)
        for gen in 1:length(gens)
            if bar == 1
                leg = true
            else
                leg = false
            end
            push!(
                traces,
                Plots.PlotlyJS.scatter(;
                    name = gens[gen],
                    showlegend = leg,
                    x = ["$time_span, $(time_range[1])"],
                    y = data[:, gen],
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
        if title == " "
            title = "Bar_Generation"
        end
        title = replace(title, " " => "_")
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

function plotly_bar_plots(results::Array, seriescolor::Array, ylabel::String; kwargs...)
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
                if res == 1
                    leg = true
                else
                    leg = false
                end
                push!(
                    traces,
                    Plots.PlotlyJS.scatter(;
                        name = gens[gen],
                        showlegend = leg,
                        x = ["$time_span, $(time_range[1, 1])"],
                        y = sum(convert(Matrix, var), dims = 1),
                        type = "bar",
                        barmode = "stack",
                        stackgroup = "one",
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
        plots = vcat(plots...)
        set_display && Plots.display(plots)
        if !isnothing(save_fig)
            format = get(kwargs, :format, "html")
            Plots.PlotlyJS.savefig(
                plots,
                joinpath(save_fig, "$(key)_Bar.$format");
                width = 630,
                height = 630,
            )
        end
        plot_list[key] = plots
    end
    return plot_list
end

function plotly_bar_plots(res::IS.Results, seriescolor::Array, ylabel::String; kwargs...)
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
                    y = sum(convert(Matrix, var)[:, gen], dims = 1),
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
    ylabel::String;
    kwargs...,
)
    stair = get(kwargs, :stair, false)
    if stair
        stack_title = "$(title) Stair"
    else
        stack_title = "$(title) Stack"
    end
    stacks = plotly_fuel_stack_gen(stack, seriescolor, stack_title, ylabel; kwargs...)
    bars = plotly_fuel_bar_gen(bar, seriescolor, "$(title) Bar", ylabel; kwargs...)
    return
end

function _fuel_plot_internal(
    stack::Union{StackedGeneration, Array{StackedGeneration}},
    bar::Union{BarGeneration, Array{BarGeneration}},
    seriescolor::Array,
    backend::Any,
    save_fig::Any,
    set_display::Bool,
    title::String,
    ylabel::String;
    kwargs...,
)
    stack_plots = []
    bar_plots = []
    stair = get(kwargs, :stair, false)
    if stair
        linetype = :steppost
    else
        linetype = :line
    end
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
        )
        if !isempty(stack.p_labels)
            load = cumsum(stack.parameters, dims = 2)
            Plots.plot!(
                time_range,
                load;
                seriescolor = :black,
                lab = "PowerLoad",
                legend = :outerright,
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
        bar_data = cumsum(bar.bar_data, dims = 2)
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
            load = cumsum(bar.parameters, dims = 2)
            Plots.plot!(
                [3.5; 5.5],
                [load; load];
                seriescolor = :black,
                lab = "PowerLoad",
                legend = :outerright,
            )
        end
        push!(bar_plots, p2)
    end
    p2 = Plots.plot(bar_plots...; layout = (length(bars), 1))
    set_display && display(p1)
    set_display && display(p2)
    if !isnothing(save_fig)
        if linetype == :line
            Plots.savefig(p1, joinpath(save_fig, "$(title)_Stack.png"))
        else
            Plots.savefig(p1, joinpath(save_fig, "$(title)_Stair.png"))
        end
        Plots.savefig(p2, joinpath(save_fig, "$(title)_Bar.png"))
    end
    return (stack_plots, bar_plots)
end

############################# BAR ##########################################

function _bar_plot_internal(
    res::IS.Results,
    backend::Any,
    save_fig::Any,
    set_display::Bool;
    kwargs...,
)
    title = get(kwargs, :title, " ")
    ylabel = _make_ylabel(IS.get_base_power(res))
    seriescolor = get(kwargs, :seriescolor, GR_DEFAULT)
    variables = IS.get_variables(res)
    time_range = IS.get_time_stamp(res)[:, 1]
    time_interval =
        IS.convert_compound_period(length(time_range) * (time_range[2] - time_range[1]))
    bar_data = []
    plot_list = Dict()
    for (name, variable) in variables
        data = convert(Matrix, variable)
        plot_data = sum(cumsum(data, dims = 2), dims = 1)
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
        set_display && display(p)
        if !isnothing(save_fig)
            Plots.savefig(p, joinpath(save_fig, "$(name)_Bar.png"))
        end
        bar_data = vcat(bar_data, [sum(data, dims = 2)])
        plot_list[name] = p
    end
    bar_data = sum(cumsum(hcat(bar_data...), dims = 2), dims = 1)
    base_data = hcat(0, bar_data)
    labels = string.(keys(variables))
    p2 = Plots.plot(
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
        load_data = -1.0 .* sum(convert(Matrix, parameters[:PowerLoad]))
        Plots.plot!(
            [3.5, 5.5],
            [load_data; load_data];
            seriescolor = :black,
            lab = "PowerLoad",
            legend = :outerright,
        )
    end
    set_display && display(p2)
    if title == " "
        title = "Bar_Generation"
    end
    if !isnothing(save_fig)
        title = replace(title, " " => "_")
        Plots.savefig(p2, joinpath(save_fig, "$title.png"))
    end
    plot_list[Symbol(title)] = p2
    return PlotList(plot_list)
end

function _bar_plot_internal(
    results::Any,
    backend::Any,
    save_fig::Any,
    set_display::Bool;
    kwargs...,
)
    title = get(kwargs, :title, " ")
    ylabel = _make_ylabel(IS.get_base_power(results[1]))
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
            plot_data = sum(cumsum(data, dims = 2), dims = 1)
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
        if !isnothing(save_fig)
            Plots.savefig(plot, joinpath(save_fig, "$(name)_Bar.png"))
        end
        plot_list[name] = plot
    end
    bar_plots = []
    for res in results
        bar_data = []
        for (key, variable) in IS.get_variables(res)
            bar_data = vcat(bar_data, [sum(convert(Matrix, variable), dims = 2)])
        end
        bar_data = sum(cumsum(hcat(bar_data...), dims = 2), dims = 1)
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
            load_data = -1.0 .* sum(convert(Matrix, parameters[:PowerLoad]))
            Plots.plot!(
                [3.5; 5.5],
                [load_data; load_data];
                seriescolor = :black,
                lab = "PowerLoad",
                legend = :outerright,
            )
        end
        bar_plots = vcat(bar_plots, p)
    end
    bar_plot = Plots.plot(bar_plots...; layout = (length(results), 1))
    set_display && display(bar_plot)
    if title == " "
        title = "Bar_Generation"
    end
    if !isnothing(save_fig)
        title = replace(title, " " => "_")
        Plots.savefig(bar_plot, joinpath(save_fig, "$title.png"))
    end
    plot_list[Symbol(title)] = bar_plot
    return PlotList(plot_list)
end

############################ STACK ########################

function _stack_plot_internal(
    res::IS.Results,
    backend::Any,
    save_fig::Any,
    set_display::Bool;
    kwargs...,
)
    title = get(kwargs, :title, " ")
    ylabel = _make_ylabel(IS.get_base_power(res))
    seriescolor = get(kwargs, :seriescolor, GR_DEFAULT)
    linetype = get(kwargs, :linetype, :line)
    variables = IS.get_variables(res)
    time_range = IS.get_time_stamp(res)[:, 1]
    time_interval =
        IS.convert_compound_period(length(time_range) * (time_range[2] - time_range[1]))
    stack_data = []
    plot_list = Dict()
    for (name, variable) in variables
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
        set_display && display(p)
        if !isnothing(save_fig)
            if linetype == :line
                Plots.savefig(p, joinpath(save_fig, "$(name)_Stack.png"))
            else
                Plots.savefig(p, joinpath(save_fig, "$(name)_Stair.png"))
            end
        end
        stack_data = vcat(stack_data, [sum(data, dims = 2)])
        plot_list[name] = p
    end
    stack_data = cumsum(hcat(stack_data...), dims = 2)
    base_data = hcat(zeros(length(time_range)), stack_data)
    labels = string.(keys(variables))
    p2 = Plots.plot(
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
            -1.0 .* cumsum(sum(convert(Matrix, parameters[:PowerLoad]), dims = 2), dims = 2)
        Plots.plot!(
            time_range,
            load_data;
            seriescolor = :black,
            lab = "PowerLoad",
            legend = :outerright,
            linetype = linetype,
        )
    end
    set_display && display(p2)
    if title == " "
        if linetype == :line
            title = "Stack_Generation"
        else
            title = "Stair_Generation"
        end
    end
    if !isnothing(save_fig)
        title = replace(title, " " => "_")
        Plots.savefig(p2, joinpath(save_fig, "$title.png"))
    end
    plot_list[Symbol(title)] = p2
    return PlotList(plot_list)
end

function _stack_plot_internal(
    results::Any,
    backend::Any,
    save_fig::Any,
    set_display::Bool;
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
        if !isnothing(save_fig)
            if linetype == :line
                Plots.savefig(plot, joinpath(save_fig, "$(name)_Stack.png"))
            else
                Plots.savefig(plot, joinpath(save_fig, "$(name)_Stair.png"))
            end
        end
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
                -1.0 .*
                cumsum(sum(convert(Matrix, parameters[:PowerLoad]), dims = 2), dims = 2)
            Plots.plot!(
                time_range,
                load_data;
                seriescolor = :black,
                lab = "PowerLoad",
                legend = :outerright,
                linetype = linetype,
            )
        end
        stack_plots = vcat(stack_plots, p)
    end
    stack_plot = Plots.plot(stack_plots...; layout = (length(results), 1))
    set_display && display(stack_plot)
    if title == " "
        if linetype == :line
            title = "Stack_Generation"
        else
            title = "Stair_Generation"
        end
    end
    if !isnothing(save_fig)
        title = replace(title, " " => "_")
        Plots.savefig(stack_plot, joinpath(save_fig, "$title.png"))
    end
    plot_list[Symbol(title)] = stack_plot
    return PlotList(plot_list)
end

######################################### DEMAND ########################

function _demand_plot_internal(res::IS.Results, backend::Plots.PlotlyJSBackend; kwargs...)
    seriescolor = get(kwargs, :seriescolor, [:auto])
    stair = get(kwargs, :stair, false)
    if stair
        line_shape = "hv"
    else
        line_shape = "linear"
    end
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
                    y = -1.0 .* parameters[:, param_names[i]],
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
    seriescolor = get(kwargs, :seriescolor, [:auto])
    save_fig = get(kwargs, :save, nothing)
    set_display = get(kwargs, :display, true)
    ylabel = _make_ylabel(IS.get_base_power(results[1]))
    stair = get(kwargs, :stair, false)
    if stair
        line_shape = "hv"
    else
        line_shape = "linear"
    end
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
            if n == 1
                leg = true
            else
                leg = false
            end
            for i in 1:n_traces
                push!(
                    traces,
                    Plots.PlotlyJS.scatter(;
                        name = p_names[i],
                        x = results[n].time_stamp[:, 1],
                        y = -1.0 .* parameters[:, p_names[i]],
                        stackgroup = "one",
                        mode = "lines",
                        fill = "tonexty",
                        line_color = seriescolor[i],
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

function _demand_plot_internal(res::IS.Results, backend::Any; kwargs...)
    stair = get(kwargs, :stair, false)
    if stair
        linetype = :steppost
    else
        linetype = :line
    end
    seriescolor = get(kwargs, :seriescolor, :auto)
    save_fig = get(kwargs, :save, nothing)
    set_display = get(kwargs, :display, true)
    time_range = res.time_stamp[:, 1]
    interval = time_range[2] - time_range[1]
    time_interval = IS.convert_compound_period(interval * length(time_range))
    ylabel = _make_ylabel(IS.get_base_power(res))
    plot_list = Dict()
    for (key, parameters) in res.parameter_values
        title = get(kwargs, :title, "$key")
        data = -1.0 .* cumsum(convert(Matrix, parameters), dims = 2)
        labels = [string(names(parameters)[1])]
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
        if !isnothing(save_fig)
            title = replace(title, " " => "_")
            Plots.savefig(p, joinpath(save_fig, "$(title).png"))
        end
        plot_list[key] = p
    end
    return PlotList(plot_list)
end

function _demand_plot_internal(results::Array{}, backend::Any; kwargs...)
    stair = get(kwargs, :stair, false)
    if stair
        linetype = :steppost
    else
        linetype = :line
    end
    seriescolor = get(kwargs, :seriescolor, :auto)
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
            data = -1.0 .* cumsum(convert(Matrix, params), dims = 2)
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
        if !isnothing(save_fig)
            Plots.savefig(p, joinpath(save_fig, "$title.png"))
        end
        plot_list[key] = p
    end
    return PlotList(plot_list)
end

####################### Demand Plot System

function _demand_plot_internal(
    parameters::DataFrames.DataFrame,
    basepower::Float64,
    backend::Plots.PlotlyJSBackend;
    kwargs...,
)
    stair = get(kwargs, :stair, false)
    if stair
        line_shape = "hv"
    else
        line_shape = "linear"
    end
    save_fig = get(kwargs, :save, nothing)
    set_display = get(kwargs, :display, true)
    ylabel = _make_ylabel(basepower)
    plot_list = Dict()
    traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
    data = DataFrames.select(parameters, DataFrames.Not(:timestamp))
    param_names = names(data)
    n_traces = length(param_names)
    seriescolor = get(kwargs, :seriescolor, repeat([:auto], n_traces))
    title = get(kwargs, :title, "PowerLoad")
    for i in 1:n_traces
        push!(
            traces,
            Plots.PlotlyJS.scatter(;
                name = param_names[i],
                x = parameters[:, :timestamp],
                y = -1.0 .* data[:, param_names[i]],
                stackgroup = "one",
                mode = "lines",
                fill = "tonexty",
                line_color = seriescolor,
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
    seriescolor = get(kwargs, :seriescolor, PLOTLY_DEFAULT)
    save_fig = get(kwargs, :save, nothing)
    set_display = get(kwargs, :display, true)
    stair = get(kwargs, :stair, false)
    if stair
        line_shape = "hv"
    else
        line_shape = "linear"
    end
    plot_list = Dict()
    plots = []
    title = get(kwargs, :title, "PowerLoad")
    for i in 1:length(parameters)
        data = DataFrames.select(parameters[i], DataFrames.Not(:timestamp))
        p_names = collect(names(data))
        ylabel = _make_ylabel(basepower[i])
        traces = Plots.PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
        for n in 1:length(p_names)
            if n == 1
                leg = true
            else
                leg = false
            end
            push!(
                traces,
                Plots.PlotlyJS.scatter(;
                    name = p_names[n],
                    x = parameters[i][:, :timestamp],
                    y = -1.0 .* data[:, p_names[n]],
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

function _demand_plot_internal(
    parameters::DataFrames.DataFrame,
    basepower::Float64,
    backend::Any;
    kwargs...,
)
    stair = get(kwargs, :stair, false)
    if stair
        linetype = :steppost
    else
        linetype = :line
    end
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
    data = -1.0 .* cumsum(convert(Matrix, parameters), dims = 2)
    labels = [string(names(parameters)[1])]
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
    if !isnothing(save_fig)
        title = replace(title, " " => "_")
        Plots.savefig(p, joinpath(save_fig, "$(title).png"))
    end
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
    if stair
        linetype = :steppost
    else
        linetype = :line
    end
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
        data = -1.0 .* cumsum(convert(Matrix, parameter_list[i]), dims = 2)
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
    if !isnothing(save_fig)
        Plots.savefig(p, joinpath(save_fig, "$title.png"))
    end
    plot_list[Symbol(title)] = p
    return PlotList(plot_list)
end
