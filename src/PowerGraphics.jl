isdefined(Base, :__precompile__) && __precompile__()
@info "PowerGrahics.jl loads Plots.jl. Precompile might take a while"
module PowerGraphics

export get_stacked_aggregation_data
export get_bar_aggregation_data
export bar_plot
export stack_plot
export demand_plot
export stair_plot
export report
export make_fuel_dictionary
export fuel_plot
export match_fuel_colors
export sort_data
import Dates

#I/O Imports
import Reexport
import Requires
import Colors
import DataFrames
Reexport.@reexport using Plots
import PowerSystems
import InfrastructureSystems

const PSY = PowerSystems
const IS = InfrastructureSystems

include("plot_results.jl")
include("definitions.jl")
include("fuel_results.jl")
include("plot_recipes.jl")
include("call_plots.jl")

function __init__()
    Requires.@require Weave = "44d3d7a6-8a23-5bf8-98c5-b353f8df5ec9" include("make_report.jl")
end

end
