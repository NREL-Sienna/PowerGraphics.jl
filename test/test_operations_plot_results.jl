path = joinpath(pwd(), "plots")
!isdir(path) && mkdir(path)

function test_plots(file_path::String)
    include("test_data.jl")

    @testset "testing results sorting" begin
        Variables = Dict(:P_ThermalStandard => [:one, :two])
        sorted = PG.sort_data(res; Variables = Variables)
        sorted_two = PG.sort_data(res)
        sorted_names = [:one, :two]
        sorted_names_two = [:one, :three, :two]
        @test names(get_variables(sorted)[:P_ThermalStandard]) == sorted_names
        @test names(get_variables(sorted_two)[:P_ThermalStandard]) == sorted_names_two
    end

    @testset "testing bar plot" begin
        results =
            PG.Results(get_variables(res), res.total_cost, res.optimizer_log, res.time_stamp)
        for name in keys(get_variables(results))
            variable_bar = PG.get_bar_plot_data(results, string(name))
            sort = sort!(names(get_variables(results)[name]))
            sorted_results = get_variables(res)[name][:, sort]
            for i in 1:length(sort)
                @test isapprox(
                    variable_bar.bar_data[i],
                    sum(sorted_results[:, i]),
                    atol = 1.0e-4,
                )
            end
            @test typeof(variable_bar) == PG.BarPlot
        end
        bar_gen = PG.get_bar_gen_data(results)
        @test typeof(bar_gen) == PG.BarGeneration
    end

    @testset "testing size of stack plot data" begin
        results =
            PG.Results(get_variables(res), res.total_cost, res.optimizer_log, res.time_stamp)
        for name in keys(get_variables(results))
            variable_stack = PG.get_stacked_plot_data(results, string(name))
            data = variable_stack.data_matrix
            legend = variable_stack.labels
            @test size(data) == size(get_variables(res)[name])
            @test length(legend) == size(data, 2)
            @test typeof(variable_stack) == PG.StackedArea
        end
        gen_stack = PG.get_stacked_generation_data(results)
        @test typeof(gen_stack) == PG.StackedGeneration
    end

    @testset "testing plot production" begin
        PG.bar_plot(res; save = file_path, display = false)
        PG.stack_plot(res; save = file_path, display = false)
        PG.fuel_plot(res, generators; save = file_path, display = false)
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
        PG.bar_plot([res; res]; save = file_path, display = false)
        PG.stack_plot([res; res]; save = file_path, display = false)
        PG.fuel_plot([res; res], generators; save = file_path, display = false)
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
