var documenterSearchIndex = {"docs":
[{"location":"how_to_guides/backends/#Change-Backends","page":"Change Backends","title":"Change Backends","text":"","category":"section"},{"location":"how_to_guides/backends/","page":"Change Backends","title":"Change Backends","text":"PowerGraphics.jl relies on Plots.jl to enable plotting via different backends. See the Plots.jl section on backends for more details. Currently, two backends are supported in PowerGraphics.jl:","category":"page"},{"location":"how_to_guides/backends/","page":"Change Backends","title":"Change Backends","text":"GR (default): creates static plots — run the gr() command to load\nPlotlyJS: creates interactive plots - run the plotlyjs() command to load","category":"page"},{"location":"how_to_guides/backends/","page":"Change Backends","title":"Change Backends","text":"If you run neither command, PowerGraphics.jl will default to using GR.","category":"page"},{"location":"tutorials/examples/#PowerGraphics.jl-Examples","page":"Examples","title":"PowerGraphics.jl Examples","text":"","category":"section"},{"location":"tutorials/examples/","page":"Examples","title":"Examples","text":"Example of Bar and Stack Plots on SIIPExamples","category":"page"},{"location":"reference/public/#api","page":"Public API","title":"Public API Reference","text":"","category":"section"},{"location":"reference/public/","page":"Public API","title":"Public API","text":"Modules = [PowerGraphics]\nPublic = true","category":"page"},{"location":"reference/public/#PowerGraphics.load_palette-Tuple{}","page":"Public API","title":"PowerGraphics.load_palette","text":"load_palette()\nload_palette(file)\n\nLoads color palette yaml from environment, the DEFAULT_PALETTE_FILE, or a given file. See color-palette.yaml for an example.\n\nArguments\n\nfile : path to YAML color palette\n\n\n\n\n\n","category":"method"},{"location":"reference/public/#PowerGraphics.plot_dataframe!-Tuple{Any, DataFrames.DataFrame}","page":"Public API","title":"PowerGraphics.plot_dataframe!","text":"plot_dataframe!(plot, df)\nplot_dataframe!(plot, df, time_range)\n\nPlots data from a DataFrames.DataFrame where each row represents a time period and each column represents a trace\n\nArguments\n\nplot: existing plot handle, such as the result of plot()\ndf::DataFrames.DataFrame: DataFrame where each row represents a time period and each column represents a trace.\n\nIf only the DataFrame is provided, it must have a column of DateTime values.\n\ntime_range:::Union{DataFrames.DataFrame, Array, StepRange}: The time periods of the data\n\nAccepted Key Words\n\ncurtailment::Bool: plot the curtailment with the variable\nset_display::Bool = true: set to false to prevent the plots from displaying\nsave::String = \"file_path\": set a file path to save the plots\nformat::String = \"png\": set a different format for saving a PlotlyJS plot\nseriescolor::Array: Set different colors for the plots\ntitle::String = \"Title\": Set a title for the plots\nstack::Bool = true: stack plot traces\nbar::Bool : create bar plot\nnofill::Bool : force empty area fill\nstair::Bool: Make a stair plot instead of a stack plot\n\n\n\n\n\n","category":"method"},{"location":"reference/public/#PowerGraphics.plot_dataframe-Tuple{DataFrames.DataFrame}","page":"Public API","title":"PowerGraphics.plot_dataframe","text":"plot_dataframe(df)\nplot_dataframe(df, time_range)\n\nPlots data from a DataFrames.DataFrame where each row represents a time period and each column represents a trace\n\nArguments\n\ndf::DataFrames.DataFrame: DataFrame where each row represents a time period and each column represents a trace.\n\nIf only the DataFrame is provided, it must have a column of DateTime values.\n\ntime_range:::Union{DataFrames.DataFrame, Array, StepRange}: The time periods of the data\n\nExample\n\nvar_name = :P__ThermalStandard\ndf = PowerSimulations.read_variables_with_keys(results, names = [var_name])[var_name]\ntime_range = PowerSimulations.get_realized_timestamps(results)\nplot = plot_dataframe(df, time_range)\n\nAccepted Key Words\n\ncurtailment::Bool: plot the curtailment with the variable\nset_display::Bool = true: set to false to prevent the plots from displaying\nsave::String = \"file_path\": set a file path to save the plots\nformat::String = \"png\": set a different format for saving a PlotlyJS plot\nseriescolor::Array: Set different colors for the plots\ntitle::String = \"Title\": Set a title for the plots\nstack::Bool = true: stack plot traces\nbar::Bool : create bar plot\nnofill::Bool : force empty area fill\nstair::Bool: Make a stair plot instead of a stack plot\n\n\n\n\n\n","category":"method"},{"location":"reference/public/#PowerGraphics.plot_demand!-Tuple{Any, Union{InfrastructureSystems.Results, PowerSystems.System}}","page":"Public API","title":"PowerGraphics.plot_demand!","text":"plot_demand!(plot, result)\nplot_demand!(plot, system)\n\nPlots the demand in the system.\n\nArguments\n\nplot: existing plot handle, such as the result of plot()\nres::Union{InfrastructureSystems.Results,PowerSystems.System}:    A Results object (e.g., PowerSimulations.SimulationProblemResults)   or PowerSystems.System to plot the demand from\n\nAccepted Key Words\n\nlinestyle::Symbol = :dash : set line style\ntitle::String: Set a title for the plots\nhorizon::Int64: To plot a shorter window of time than the full results\ninitial_time::DateTime: To start the plot at a different time other than the results initial time\naggregate::String = \"System\", \"PowerLoad\", or \"Bus\": aggregate the demand by   PowerSystems.System, PowerSystems.PowerLoad, or PowerSystems.Bus,   rather than by generator\nset_display::Bool = true: set to false to prevent the plots from displaying\nsave::String = \"file_path\": set a file path to save the plots\nformat::String = \"png\": set a different format for saving a PlotlyJS plot\nseriescolor::Array: Set different colors for the plots\ntitle::String = \"Title\": Set a title for the plots\nstack::Bool = true: stack plot traces\nbar::Bool : create bar plot\nnofill::Bool : force empty area fill\nstair::Bool: Make a stair plot instead of a stack plot\nfilter_func::Function =PowerSystems.get_available: filter components included in plot\npalette : color palette from load_palette\n\n\n\n\n\n","category":"method"},{"location":"reference/public/#PowerGraphics.plot_fuel!-Tuple{Any, InfrastructureSystems.Results}","page":"Public API","title":"PowerGraphics.plot_fuel!","text":"plot_fuel!(plot, results)\n\nPlots a stack plot of the results by fuel type and assigns each fuel type a specific color.\n\nArguments\n\nplot: existing plot handle, such as the result of plot() (optional)\nres::InfrastructureSystems.Results:    A Results object (e.g., PowerSimulations.SimulationProblemResults)   to be plotted\n\nAccepted Key Words\n\ngenerator_mapping_file = \"file_path\" : file path to yaml defining generator category by fuel and primemover\nvariables::Union{Nothing, Vector{Symbol}} = nothing : specific variables to plot\nslacks::Bool = true : display slack variables\nload::Bool = true : display load line\ncurtailment::Bool = true: To plot the curtailment in the stack plot\nset_display::Bool = true: set to false to prevent the plots from displaying\nsave::String = \"file_path\": set a file path to save the plots\nformat::String = \"png\": set a different format for saving a PlotlyJS plot\nseriescolor::Array: Set different colors for the plots\ntitle::String = \"Title\": Set a title for the plots\nstack::Bool = true: stack plot traces\nbar::Bool : create bar plot\nnofill::Bool : force empty area fill\nstair::Bool: Make a stair plot instead of a stack plot\nfilter_func::Function =PowerSystems.get_available: filter components included in plot\npalette : Color palette as from load_palette.\n\n\n\n\n\n","category":"method"},{"location":"reference/public/#PowerGraphics.plot_fuel-Tuple{InfrastructureSystems.Results}","page":"Public API","title":"PowerGraphics.plot_fuel","text":"plot_fuel(results)\n\nPlots a stack plot of the results by fuel type and assigns each fuel type a specific color.\n\nArguments\n\nres::InfrastructureSystems.Results:    A Results object (e.g., PowerSimulations.SimulationProblemResults)   to be plotted\nExample\n\nres = solve_op_problem!(OpProblem)\nplot = plot_fuel(res)\n\nAccepted Key Words\n\ngenerator_mapping_file = \"file_path\" : file path to yaml defining generator category by fuel and primemover\nvariables::Union{Nothing, Vector{Symbol}} = nothing : specific variables to plot\nslacks::Bool = true : display slack variables\nload::Bool = true : display load line\ncurtailment::Bool = true: To plot the curtailment in the stack plot\nset_display::Bool = true: set to false to prevent the plots from displaying\nsave::String = \"file_path\": set a file path to save the plots\nformat::String = \"png\": set a different format for saving a PlotlyJS plot\nseriescolor::Array: Set different colors for the plots\ntitle::String = \"Title\": Set a title for the plots\nstack::Bool = true: stack plot traces\nbar::Bool : create bar plot\nnofill::Bool : force empty area fill\nstair::Bool: Make a stair plot instead of a stack plot\nfilter_func::Function =PowerSystems.get_available: filter components included in plot\n\n\n\n\n\n","category":"method"},{"location":"reference/public/#PowerGraphics.plot_powerdata!-Tuple{Any, PowerAnalytics.PowerData}","page":"Public API","title":"PowerGraphics.plot_powerdata!","text":"plot_powerdata!(plot, powerdata)\n\nMakes a plot from a PowerAnalytics.PowerData object\n\nArguments\n\nplot: existing plot handle, such as the result of plot() (optional)\npowerdata::PowerAnalytics.PowerData: The PowerData object to be plotted\n\nAccepted Key Words\n\ncombine_categories::Bool = false : plot category values or each value in a category\ncurtailment::Bool: plot the curtailment with the variable\nset_display::Bool = true: set to false to prevent the plots from displaying\nsave::String = \"file_path\": set a file path to save the plots\nformat::String = \"png\": set a different format for saving a PlotlyJS plot\nseriescolor::Array: Set different colors for the plots\ntitle::String = \"Title\": Set a title for the plots\nstack::Bool = true: stack plot traces\nbar::Bool : create bar plot\nnofill::Bool : force empty area fill\nstair::Bool: Make a stair plot instead of a stack plot\n\n\n\n\n\n","category":"method"},{"location":"reference/public/#PowerGraphics.plot_powerdata-Tuple{PowerAnalytics.PowerData}","page":"Public API","title":"PowerGraphics.plot_powerdata","text":"plot_powerdata(powerdata)\n\nMakes a plot from a PowerAnalytics.PowerData object\n\nArguments\n\npowerdata::PowerAnalytics.PowerData: The PowerData object to be plotted\n\nAccepted Key Words\n\ncombine_categories::Bool = false : plot category values or each value in a category\ncurtailment::Bool: plot the curtailment with the variable\nset_display::Bool = true: set to false to prevent the plots from displaying\nsave::String = \"file_path\": set a file path to save the plots\nformat::String = \"png\": set a different format for saving a PlotlyJS plot\nseriescolor::Array: Set different colors for the plots\ntitle::String = \"Title\": Set a title for the plots\nstack::Bool = true: stack plot traces\nbar::Bool : create bar plot\nnofill::Bool : force empty area fill\nstair::Bool: Make a stair plot instead of a stack plot\n\n\n\n\n\n","category":"method"},{"location":"reference/public/#PowerGraphics.plot_results!-Tuple{Any, Dict{String, DataFrames.DataFrame}}","page":"Public API","title":"PowerGraphics.plot_results!","text":"plot_results!(plot, results)\n\nMakes a plot from a results dictionary\n\nArguments\n\nplot: existing plot handle, such as the result of plot() (optional)\nresults::Dict{String, DataFrame}: The results to be plotted\n\nAccepted Key Words\n\ncombine_categories::Bool = false : plot category values or each value in a category\ncurtailment::Bool: plot the curtailment with the variable\nset_display::Bool = true: set to false to prevent the plots from displaying\nsave::String = \"file_path\": set a file path to save the plots\nformat::String = \"png\": set a different format for saving a PlotlyJS plot\nseriescolor::Array: Set different colors for the plots\ntitle::String = \"Title\": Set a title for the plots\nstack::Bool = true: stack plot traces\nbar::Bool : create bar plot\nnofill::Bool : force empty area fill\nstair::Bool: Make a stair plot instead of a stack plot\n\n\n\n\n\n","category":"method"},{"location":"reference/public/#PowerGraphics.plot_results-Tuple{Dict{String, DataFrames.DataFrame}}","page":"Public API","title":"PowerGraphics.plot_results","text":"plot_results(results)\n\nMakes a plot from a results dictionary object\n\nArguments\n\nresults::Dict{String, DataFrame: The results to be plotted\n\nAccepted Key Words\n\ncombine_categories::Bool = false : plot category values or each value in a category\ncurtailment::Bool: plot the curtailment with the variable\nset_display::Bool = true: set to false to prevent the plots from displaying\nsave::String = \"file_path\": set a file path to save the plots\nformat::String = \"png\": set a different format for saving a PlotlyJS plot\nseriescolor::Array: Set different colors for the plots\ntitle::String = \"Title\": Set a title for the plots\nstack::Bool = true: stack plot traces\nbar::Bool : create bar plot\nnofill::Bool : force empty area fill\nstair::Bool: Make a stair plot instead of a stack plot\n\n\n\n\n\n","category":"method"},{"location":"reference/public/#PowerGraphics.report-Tuple{InfrastructureSystems.Results, String, String}","page":"Public API","title":"PowerGraphics.report","text":"report(res::IS.Results, out_path::String, design_template::String)\n\nThis function uses Weave.jl to either generate a LaTeX or HTML file based on the report_design.jmd (Julia markdown) file that it reads. \n\nAn example template is available here\n\nArguments\n\nresults::IS.Results: The results to be plotted\nout_path::String: folder path to the location the report should be generated\ndesign_template::String = \"file_path\": directs the function to the julia markdown report design, the default\n\nExample\n\nresults = solve_op_problem!(OpModel)\nout_path = \"/Users/downloads\"\nreport(results, out_path, template)\n\nAccepted Key Words\n\ndoctype::String = \"md2html\": create an HTML, default is PDF via latex\nbackend::Plots.AbstractBackend = Plots.gr(): sets the Plots.jl backend\n\n\n\n\n\n","category":"method"},{"location":"reference/public/#PowerGraphics.save_plot-Tuple{Any, String}","page":"Public API","title":"PowerGraphics.save_plot","text":"save_plot(plot, filename)\n\nSaves plot to specified filename\n\nArguments\n\nplot: plot object\nfilename::String : save to filename\n\nExample\n\nres = solve_op_problem!(OpProblem)\nplot = plot_fuel(res)\nsave_plot(plot, \"my_plot.png\")\n\nAccepted Key Words (currently only implemented for PlotlyJS backend)\n\nwidth::Union{Nothing,Int}=nothing\nheight::Union{Nothing,Int}=nothing\nscale::Union{Nothing,Real}=nothing\n\n\n\n\n\n","category":"method"},{"location":"explanation/stub/","page":"-","title":"-","text":"Please refer to the Explanation section of the diataxis framework.","category":"page"},{"location":"reference/developer_guidelines/#Developer-Guidelines","page":"Developer Guidelines","title":"Developer Guidelines","text":"","category":"section"},{"location":"reference/developer_guidelines/","page":"Developer Guidelines","title":"Developer Guidelines","text":"In order to contribute to PowerGraphics.jl repository please read the following sections of InfrastructureSystems.jl and SiennaTemplate.jl documentation in detail:","category":"page"},{"location":"reference/developer_guidelines/","page":"Developer Guidelines","title":"Developer Guidelines","text":"Style Guide\nDocumentation Best Practices\nContributing Guidelines","category":"page"},{"location":"reference/developer_guidelines/","page":"Developer Guidelines","title":"Developer Guidelines","text":"Pull requests are always welcome to fix bugs or add additional modeling capabilities.","category":"page"},{"location":"reference/developer_guidelines/","page":"Developer Guidelines","title":"Developer Guidelines","text":"All the code contributions need to include tests with a minimum coverage of 70%","category":"page"},{"location":"#Welcome-to-PowerGraphics.jl","page":"Welcome","title":"Welcome to PowerGraphics.jl","text":"","category":"section"},{"location":"","page":"Welcome","title":"Welcome","text":"CurrentModule = PowerGraphics","category":"page"},{"location":"#Overview","page":"Welcome","title":"Overview","text":"","category":"section"},{"location":"","page":"Welcome","title":"Welcome","text":"PowerGraphics.jl is a Julia package for plotting results from PowerSimulations.jl.","category":"page"},{"location":"#About-Sienna","page":"Welcome","title":"About Sienna","text":"","category":"section"},{"location":"","page":"Welcome","title":"Welcome","text":"PowerGraphics.jl is part of the National Renewable Energy Laboratory's Sienna ecosystem, an open source framework for power system modeling, simulation, and optimization. The Sienna ecosystem can be found on GitHub. It contains three applications:","category":"page"},{"location":"","page":"Welcome","title":"Welcome","text":"Sienna\\Data enables efficient data input, analysis, and transformation\nSienna\\Ops enables enables system scheduling simulations by formulating and solving optimization problems\nSienna\\Dyn enables system transient analysis including small signal stability and full system dynamic simulations","category":"page"},{"location":"","page":"Welcome","title":"Welcome","text":"Each application uses multiple packages in the Julia programming language.","category":"page"},{"location":"#Installation","page":"Welcome","title":"Installation","text":"","category":"section"},{"location":"","page":"Welcome","title":"Welcome","text":"See the Sienna installation page to install PowerGraphics.jl and other Sienna packages.","category":"page"},{"location":"reference/internal/#Internal-API","page":"Internals","title":"Internal API","text":"","category":"section"},{"location":"reference/internal/","page":"Internals","title":"Internals","text":"Modules = [PowerGraphics]\nPublic = false","category":"page"}]
}
