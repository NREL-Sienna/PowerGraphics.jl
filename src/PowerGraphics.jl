isdefined(Base, :__precompile__) && __precompile__()
@info "PowerGraphics.jl loads Plots.jl. Precompile might take a while"
module PowerGraphics

export plot_demand
export plot_dataframe
export plot_pgdata
export plot_fuel
export make_fuel_dictionary
export report
export get_generation_data
export get_load_data
export get_service_data
export categorize_data

#I/O Imports
import Dates
import TimeSeries
import Reexport
import Requires
import Colors
import DataFrames
import YAML
Reexport.@reexport using Plots
import DataStructures: OrderedDict, SortedDict
import PowerSystems
import InfrastructureSystems
import PowerSimulations
import InteractiveUtils

const PSY = PowerSystems
const IS = InfrastructureSystems
const PSI = PowerSimulations

include("definitions.jl")
include("problem_results.jl")
include("plot_data.jl")
include("fuel_results.jl")
include("plot_recipes.jl")
include("plotly_recipes.jl")
include("make_report.jl")
include("call_plots.jl")

function __init__()
    Requires.@require Weave = "44d3d7a6-8a23-5bf8-98c5-b353f8df5ec9" include(
        "make_report.jl",
    )
end

end #module
