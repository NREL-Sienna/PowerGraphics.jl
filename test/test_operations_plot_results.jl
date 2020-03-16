path = joinpath(pwd(), "plots")
!isdir(path) && mkdir(path)

function test_plots(file_path::String)
    include("test_data.jl")

    @testset "test results sorting" begin
        Variables = Dict(:P_ThermalStandard => [:one, :two])
        sorted = PSG.sort_data(res; Variables = Variables)
        sorted_two = PSG.sort_data(res)
        sorted_names = [:one, :two]
        sorted_names_two = [:one, :three, :two]
        @test names(sorted.variable_values[:P_ThermalStandard]) == sorted_names
        @test names(sorted_two.variable_values[:P_ThermalStandard]) == sorted_names_two
    end

    @testset "test bar plot" begin
        results =
            PSG.Results(res.variable_values, res.total_cost, res.optimizer_log, res.time_stamp)
        for name in keys(results.variable_values)
            variable_bar = PSG.get_bar_plot_data(results, string(name))
            sort = sort!(names(results.variable_values[name]))
            sorted_results = res.variable_values[name][:, sort]
            for i in 1:length(sort)
                @test isapprox(
                    variable_bar.bar_data[i],
                    sum(sorted_results[:, i]),
                    atol = 1.0e-4,
                )
            end
            @test typeof(variable_bar) == PSG.BarPlot
        end
        bar_gen = PSG.get_bar_gen_data(results)
        @test typeof(bar_gen) == PSG.BarGeneration
    end

    @testset "testing size of stack plot data" begin
        results =
            PSG.Results(res.variable_values, res.total_cost, res.optimizer_log, res.time_stamp)
        for name in keys(results.variable_values)
            variable_stack = PSG.get_stacked_plot_data(results, string(name))
            data = variable_stack.data_matrix
            legend = variable_stack.labels
            @test size(data) == size(res.variable_values[name])
            @test length(legend) == size(data, 2)
            @test typeof(variable_stack) == PSG.StackedArea
        end
        gen_stack = PSG.get_stacked_generation_data(results)
        @test typeof(gen_stack) == PSG.StackedGeneration
    end

    @testset "testing plot production" begin
        PSG.bar_plot(res; save = file_path, display = false)
        PSG.stack_plot(res; save = file_path, display = false)
        PSG.fuel_plot(res, generators; save = file_path, display = false)
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
        PSG.bar_plot([res; res]; save = file_path, display = false)
        PSG.stack_plot([res; res]; save = file_path, display = false)
        PSG.fuel_plot([res; res], generators; save = file_path, display = false)
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
end
try
    test_plots(path)
finally
    @info("removing test files")
    rm(path, recursive = true)
end
