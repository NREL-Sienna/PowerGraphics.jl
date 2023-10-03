

function _has_realized_variable(variable::String,results::PSI.SimulationProblemResults)
    in(variable,keys(results.values.container_key_lookup))
end



function _get_time_ticks(times,interval)
    data_time_delta = times[2]-times[1]
    @assert interval >= data_time_delta

    tick_range = times[1]:interval:times[end]
    if tick_range[end] != times[end]
        tick_range = vcat(tick_range...,times[end])
    end

    formatted_time_ticks = []
    current_day = Dates.day(times[1])
    for t in eachindex(tick_range)
        time = tick_range[t]
        day = Dates.day(time)
        if t==1 || day!=current_day
            push!(formatted_time_ticks,Dates.format(time,"m-d-yyyy H:MM"))
            current_day = day
        else
            push!(formatted_time_ticks,Dates.format(time,"H:MM"))
        end

    end
    return (tick_range,formatted_time_ticks)

end


"""
    function get_flow_matrix(line_type,results::PowerSimulations.SimulationProblemResults)
This probably needs to be moved to PowerAnalytics.jl
"""
function get_flow_matrix(line_type, results::PSI.SimulationProblemResults)
    PSY.set_units_base_system!(PSI.get_system(results), "natural_units")
    lines = PSI.get_available_components(line_type, PSI.get_system(results))
    flows = PSI.read_realized_variable(results, "FlowActivePowerVariable__$line_type")
    for line in lines
        PSY.get_name(line) ∉ names(flows) && continue
        flows[:, PSY.get_name(line)] .= abs.(flows[:, PSY.get_name(line)] ./ PSY.get_rate(line))
    end
    flow_mat = Matrix(PA.no_datetime(flows))
    return flow_mat, PSY.get_name.(lines)
end






