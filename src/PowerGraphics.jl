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
using Reexport
import Colors
import DataFrames
@reexport using Plots
import Weave
import PowerSystems
import InfrastructureSystems
import GR

const PSY = PowerSystems
const IS = InfrastructureSystems

include("plot_results.jl")
include("definitions.jl")
include("fuel_results.jl")
include("plot_recipes.jl")
include("call_plots.jl")
include("make_report.jl")

end
