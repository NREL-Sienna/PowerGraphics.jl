
"""
    function plot_generation(results::PowerSimulations.SimulationProblemResults)
Plots generation with the ability to aggregate across time and/or generation categories. 
# Arguments
    - `stack::Bool = true`: Whether to stack the plot. If `true`, aggregates across data categories.
    - `bar::Bool = false`: Whether to plot as a line or bar chart. If `true` aggregates across time.
    - `show_load::Bool = true`: Whether or not to show the load.
    - `xtickinterval::TimePeriod = Hour(1)`: The time interval between xticks. Only relevant when `bar=false`. Alternatively users can pass their own xticks entirely.
    - `gen_palette::Vector{PaletteColor}`: The color and ordering of the data categories. Uses default palette if unset.
"""
@userplot Plot_Generation
@recipe function f(plt::Plot_Generation ; stack = true, bar = false, show_load = true, xtickinterval = Hour(1), gen_palette = load_palette(DEFAULT_PALETTE_FILE))
    
    # make sure plot was given the right data types
    results = plt.args[1]::PSI.SimulationProblemResults
    @assert supertype(typeof(xtickinterval)) ==TimePeriod "Argument `xtickinterval` must be of type Dates.TimePeriod (e.g., Dates.Hour(1)) got "*typeof(supertype(xtickinterval))
    @assert isa(stack,Bool) "Argument `stack` must be a Bool, got "*typeof(stack)
    @assert isa(bar,Bool) "Argument `bar` must be a Bool, got "*typeof(bar)
    @assert isa(show_load,Bool) "Argument `show_load` must be a Bool, got "*typeof(show_load)
    @assert isa(gen_palette,Vector{PaletteColor}) "Argument `gen_palette` must be of type Vector{PaletteColor}, got "*typeof(gen_palette)
    
    # get data
    gen = PA.get_generation_data(results)
    gen_dict = PA.make_fuel_dictionary(PSI.get_system(results))
    gen_agg = PA.categorize_data(gen.data, gen_dict)

    for df in values(gen_agg)
        if "DateTime" in names(df)
            DataFrames.select!(df,DataFrames.Not(:DateTime))
        end
    end

    # set plot attributes
    fontfamily      --> "Helvetica"
    ylab            --> (bar ? "MWh" : "MW") # how do we know what units the data will be?
    legend          --> :outerright
    size            --> (800,400)
    grid            --> false
    title           --> "Generation"
    left_margin     --> (3,:mm)
    bottom_margin   --> (bar ? (3,:mm) : (9,:mm))

    # if plotting as timeseries, set xticks
    if !bar
        xticks      --> _get_time_ticks(gen.time,xtickinterval)
        xrotation   --> 45
        xlab        --> "Time"
    end

    
    if !stack && !bar 
    # plot data as regular time series lines
        for pl in gen_palette
            if pl.category in keys(gen_agg)
                @series begin
                    # set attributes for this series
                    linecolor := pl.color
                    seriestype := :path
                    label :=pl.category
                    
                    # data for series
                    gen.time,sum.(eachrow(gen_agg[pl.category])) 
                end
                
            end
        end
    end

    if stack && !bar
    # plot data as stacked time series
       
        # get order of categories
        ordered_gen_keys = collect(keys(gen_agg))[sortperm([gen_palette[findfirst([j.category for j in gen_palette] .==k)].order for k in keys(gen_agg)])]
        mat = hcat([sum.(eachrow(gen_agg[k])) for k in ordered_gen_keys]...)
        
        data = cumsum(mat,dims=2)
       
        # plot generation
        for i in eachindex(ordered_gen_keys)
            gen_type = ordered_gen_keys[i]
            pl = gen_palette[findfirst([k.category == gen_type for k in gen_palette])]
            if i ==1
                @series begin
                    linecolor := pl.color
                    fillcolor := pl.color
                    fillrange := 0
                    seriestype := :path
                    label := gen_type
                    gen.time,data[:,i]
                end
            else
                @series begin
                    linecolor := pl.color
                    fillcolor := pl.color
                    fillrange := data[:,i-1] 
                    label     := gen_type 
                    seriestype := :path
                    gen.time,data[:,i]
                end
            end
        end
    end

    if bar
        actual_palette = gen_palette[[findfirst([j.category for j in gen_palette] .==k) for k in keys(gen_agg)]]
        if stack
            xticks --> false
            xlab --> canonicalize(gen.time[end]-gen.time[1]+(gen.time[end]-gen.time[end-1]))
            # plot sum of generation 
            ordered_gen_keys = collect(keys(gen_agg))[sortperm([pl.order for pl in actual_palette])]
            mat = hcat([sum.(eachrow(gen_agg[k])) for k in ordered_gen_keys]...)
            data = cumsum(mat,dims=1)[end,:]
            for i in reverse(eachindex(ordered_gen_keys))
                gen_type = ordered_gen_keys[i]
                clr = actual_palette[findfirst([pl.category == gen_type for pl in actual_palette])].color
                if i==1
                    @series begin
                        seriestype := :bar
                        label := gen_type
                        fillcolor := clr
                        bar_width := .5
                        [1],[data[i]]
                    end
                else
                    @series begin
                        seriestype := :bar
                        label := gen_type
                        fillcolor := clr
                        bar_width := .5
                        [1],[sum(data[1:i])]
                    end
                end     
            end
        else
            ordered_gen_keys = collect(keys(gen_agg))[sortperm([pl.order for pl in actual_palette])]
            mat = hcat([sum.(eachrow(gen_agg[k])) for k in ordered_gen_keys]...)
        
            data = cumsum(mat,dims=1)[end,:]

            xticks --> (1:length(ordered_gen_keys),ordered_gen_keys)
            xlims --> (.5,length(ordered_gen_keys)+.5)

            for i in eachindex(ordered_gen_keys)
                fuel_type = ordered_gen_keys[i]
                @series begin
                    seriestype := :bar
                    label := ""
                    color := actual_palette[findfirst([pl.category == fuel_type for pl in actual_palette])].color
                    [i],[data[i]]
                end 
            end 
        end
    end
    if show_load
        load_data = PA.get_load_data(results)
        
        df = load_data.data[:Load]
        if "DateTime" in names(df)
            DataFrames.select!(df,DataFrames.Not(:DateTime))
        end
        
        if !stack && !bar
            @series begin
                linecolor := "black"
                linewidth := 2
                linestyle := :dash
                seriestype := :path
                label     := "Load"
                load_data.time,sum.(eachrow(df))
            end
        end
    
        if stack
            if !bar 
                @series begin
                    linecolor := "black"
                    linewidth := 2
                    linestyle := :dash
                    seriestype := :path
                    label     := "Load"
                    load_data.time,sum.(eachrow(df))
                end
    
            else
                total_load = sum(sum.(eachrow(df)))
                    
                @series begin
                    linecolor := "black"
                    linewidth := 2
                    linestyle := :dash
                    seriestype := :path
                    label     := ""
                    [.5,1.5],[total_load,total_load]
                end
                
            end
        elseif bar
            total_load = sum(sum.(eachrow(df)))
                    
                @series begin
                    linecolor := "black"
                    linewidth := 2
                    linestyle := :dash
                    seriestype := :path
                    label     := "Load"
                    [0,length(gen_agg)],[total_load,total_load]
                end
        end
    end

end


"""
    function plot_demand(results::PowerSimulations.SimulationProblemResults; xtickinterval = Hour(1))

Plots load as a function of time. Time tick intervals can be adjusted with `xtickinterval`, or users can pass their own `xticks`.
"""
@userplot Plot_Demand
@recipe function f(plt::Plot_Demand; xtickinterval=Hour(1))
    
    # check types
    results = plt.args[1]::PSI.SimulationProblemResults
    @assert supertype(typeof(xtickinterval)) ==TimePeriod "Argument `xtickinterval` must be of type Dates.TimePeriod (e.g., Dates.Hour(1)), got "*typeof(supertype(xtickinterval))

    # get data
    load = PA.get_load_data(results)
    df = load.data[:Load]
    if "DateTime" in names(df)
        DataFrames.select!(df,DataFrames.Not(:DateTime))
    end


    # set attributes
    fontfamily      --> "Helvetica"
    ylab            --> "MW"
    xrotation       --> 45
    legend          --> :outerright
    size            --> (800,400)
    grid            --> false
    left_margin     --> (3,:mm)
    xticks      --> _get_time_ticks(load.time,xtickinterval)
    xrotation   --> 45
    xlab        --> "Time"
    ylims --> (0,maximum(sum.(eachrow(df))))

    # make data series
    @series begin
        linecolor --> "black"
        linewidth --> 2
        linestyle --> :dash
        seriestype := :path
        label     --> "Load"
        load.time,sum.(eachrow(df))
    end
end


"""
    function plot_line_loading(results::PowerSimulations.SimulationProblemResults)
Plots CDF of line loadings
"""
@userplot Plot_Line_Loading
@recipe function f(plt::Plot_Line_Loading;)

    # check types
    results = plt.args[1]::PSI.SimulationProblemResults

    # get data
    flow_mat, flow_nam = get_flow_matrix(PSY.Line, results)

    if _has_realized_variable("FlowActivePowerVariable__MonitoredLine",results)
        ml_mat, ml_nam = get_flow_matrix(PSY.MonitoredLine, results)
        flow_mat = hcat(flow_mat, ml_mat)
        flow_nam = vcat(flow_nam, ml_nam)
    end
    max_flow = maximum(flow_mat)

    incr = 0.0:1:max_flow*100.0
    ln_hrs = zeros(length(incr))
    for (ix, i) in enumerate(incr)
        ln_hrs[ix] = sum(flow_mat .>= i / 100.0) / *(size(flow_mat)...)
    end

    # set attributes
    fontfamily      --> "Helvetica"
    ylab            --> "(line-hrs > x% loading)/∑line-hrs"
    xlab            --> "% loading"
    label           --> ""
    size            --> (800,400)
    grid            --> false
    left_margin     --> (3,:mm)
    bottom_margin   --> (3,:mm)

    # make data series
    @series begin
        incr, ln_hrs
    end

end

"""
    function plot_congested_lines(results::PowerSimulations.SimulationProblemResults)
Plots line congestion over time
# Arguments
    - `line_type = PowerSystems.Line`: The type of lines to grab data for
    - `congestion_level::AbstractFloat = 0.9 `: The threshold congestion level.
    - `xtickinterval::TimePeriod = Hour(1)`: The time interval between xticks. Alternatively, users can pass their own xticks entirely.
    - `normalize::Bool = false`: Whether to normalize the timeseries by the total number of lines (not the max number of congested lines!)
"""
@userplot Plot_Congested_Lines
@recipe function f(plt::Plot_Congested_Lines;line_type = PSY.Line, congestion_level = 0.9,xtickinterval=Hour(1),normalize=false)
        
    # verify type of arguments
    results = plt.args[1]::PSI.SimulationProblemResults
    @assert isa(congestion_level,AbstractFloat) "Argument `congestion_level` must be an AbstractFloat, got "*typeof(congestion_level)
    @assert supertype(typeof(xtickinterval)) ==TimePeriod "Argument `xtickinterval` must be of type Dates.TimePeriod (e.g., Dates.Hour(1)), got "*typeof(supertype(xtickinterval))
    @assert isa(normalize,Bool) "Argument `normalize` must be a Bool, got "*typeof(normalize)

    # get data
    ylabel = normalize ? (@sprintf "Fraction of lines > %.0f%s loading" congestion_level*100 "%") : (@sprintf "Number of lines > %.0f%s loading" congestion_level*100 "%")
    times = PSI.get_realized_timestamps(results)
    flow_mat, line_names = get_flow_matrix(line_type, results)
    divid = normalize ? length(line_names) : 1
    cong = map(r->length(findall(r.>congestion_level))/divid,eachrow(flow_mat))

    # set attributes
    fontfamily      --> "Helvetica"
    ylab            --> ylabel
    xlab            --> "Time"
    xrotation       --> 45
    legend          --> :outerright
    size            --> (800,400)
    grid            --> false
    left_margin     --> (3,:mm)
    bottom_margin   --> (8,:mm)
    label           --> "$line_type"
    xticks          --> _get_time_ticks(times,xtickinterval)

    # make data series
    @series begin
        times,cong
    end

end