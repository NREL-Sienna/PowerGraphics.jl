isdefined(Base, :__precompile__) && __precompile__()

module PowerGraphics

export load_palette
export plot_generation
export plot_demand
export plot_line_loading
export plot_congested_lines
# export plot_dataframe
# export plot_powerdata
# export plot_results
# export plot_dataframe!
# export plot_powerdata!
# export plot_results!
# export report

#I/O Imports
using Dates
import Colors
import Colors: RGBA
import Printf: @sprintf
import DataFrames
import YAML
# Reexport.@reexport using Plots
# import DataStructures: OrderedDict, SortedDict
import PowerSystems
# import InfrastructureSystems
# import InteractiveUtils
import PowerAnalytics
using RecipesBase
import PowerSimulations
const PSY = PowerSystems

# const IS = InfrastructureSystems
const PA = PowerAnalytics
const PSI = PowerSimulations

include("definitions.jl")
include("utils.jl")
include("recipes.jl")
# include("plot_recipes.jl")
# include("plotly_recipes.jl")
# include("make_report.jl")
# include("call_plots.jl")

# function __init__()
#     Requires.@require Weave = "44d3d7a6-8a23-5bf8-98c5-b353f8df5ec9" include(
#         "make_report.jl",
#     )
# end

end #module
