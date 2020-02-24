using DataFrames
using Dates
using Plots
using PowerGraphics
using InfrastructureSystems
using Test
using TestSetExtensions
using Weave

const ISP = PowerGraphics
const IS = InfrastructureSystems
path = joinpath(pwd(), "plots")
!isdir(path) && mkdir(path)

function test_plots(file_path::String)
    include("test_data.jl")

    @testset "testing results sorting" begin
        Variables = Dict(:P_ThermalStandard => [:one, :two])
        sorted = ISP.sort_data(res; Variables = Variables)
        sorted_two = ISP.sort_data(res)
        sorted_names = [:one, :two]
        sorted_names_two = [:one, :three, :two]
        @test names(sorted.variables[:P_ThermalStandard]) == sorted_names
        @test names(sorted_two.variables[:P_ThermalStandard]) == sorted_names_two
    end

    @testset "testing bar plot" begin
        results =
            ISP.Results(res.variables, res.total_cost, res.optimizer_log, res.time_stamp)
        for name in keys(results.variables)
            variable_bar = ISP.get_bar_plot_data(results, string(name))
            sort = sort!(names(results.variables[name]))
            sorted_results = res.variables[name][:, sort]
            for i in 1:length(sort)
                @test isapprox(
                    variable_bar.bar_data[i],
                    sum(sorted_results[:, i]),
                    atol = 1.0e-4,
                )
            end
            @test typeof(variable_bar) == ISP.BarPlot
        end
        bar_gen = ISP.get_bar_gen_data(results)
        @test typeof(bar_gen) == ISP.BarGeneration
    end

    @testset "testing size of stack plot data" begin
        results =
            ISP.Results(res.variables, res.total_cost, res.optimizer_log, res.time_stamp)
        for name in keys(results.variables)
            variable_stack = ISP.get_stacked_plot_data(results, string(name))
            data = variable_stack.data_matrix
            legend = variable_stack.labels
            @test size(data) == size(res.variables[name])
            @test length(legend) == size(data, 2)
            @test typeof(variable_stack) == ISP.StackedArea
        end
        gen_stack = ISP.get_stacked_generation_data(results)
        @test typeof(gen_stack) == ISP.StackedGeneration
    end

    @testset "testing plot production" begin
        ISP.bar_plot(res; save = file_path, display = false)
        ISP.stack_plot(res; save = file_path, display = false)
        ISP.fuel_plot(res, generators; save = file_path, display = false)
        list = readdir(file_path)
        @test list == [
            "Bar_Generation.png",
            "Fuel_Bar.png",
            "Fuel_Stack.png",
            "P_RenewableDispatch_Bar.png",
            "P_RenewableDispatch_Stack.png",
            "P_ThermalStandard_Bar.png",
            "P_ThermalStandard_Stack.png",
            "Stack_Generation.png",
        ]
    end

    @testset "testing multi-plot production" begin
        ISP.bar_plot([res; res]; save = file_path, display = false)
        ISP.stack_plot([res; res]; save = file_path, display = false)
        ISP.fuel_plot([res; res], generators; save = file_path, display = false)
        list = readdir(file_path)
        @test list == [
            "Bar_Generation.png",
            "Fuel_Bar.png",
            "Fuel_Stack.png",
            "P_RenewableDispatch_Bar.png",
            "P_RenewableDispatch_Stack.png",
            "P_ThermalStandard_Bar.png",
            "P_ThermalStandard_Stack.png",
            "Stack_Generation.png",
        ]
    end

    @testset "testing report production" begin
        ISP.report(res, dirname(file_path))
        @test isfile(joinpath(dirname(file_path), "report_design.pdf"))
    end
end
try
    test_plots(path)
finally
    @info("removing test files")
    rm(path, recursive = true)
end
