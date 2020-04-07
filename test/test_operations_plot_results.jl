path = joinpath(pwd(), "plots")
!isdir(path) && mkdir(path)

function test_plots(file_path::String)
    include("test_data.jl")

    @testset "test results sorting" begin
        Variables = Dict(:P_ThermalStandard => [:one, :two])
        sorted = PG.sort_data(res; Variables = Variables)
        sorted_two = PG.sort_data(res)
        sorted_names = [:one, :two]
        sorted_names_two = [:one, :three, :two]
        @test names(IS.get_variables(sorted)[:P_ThermalStandard]) == sorted_names
        @test names(IS.get_variables(sorted_two)[:P_ThermalStandard]) == sorted_names_two
    end

    @testset "test bar plot" begin
        results = res
        for name in keys(IS.get_variables(results))
            variable_bar = PG.get_bar_plot_data(results, string(name))
            sort = sort!(names(IS.get_variables(results)[name]))
            sorted_results = IS.get_variables(res)[name][:, sort]
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

    @testset "test size of stack plot data" begin
        results = res
        for name in keys(IS.get_variables(results))
            variable_stack = PG.get_stacked_plot_data(results, string(name))
            data = variable_stack.data_matrix
            legend = variable_stack.labels
            @test size(data) == size(IS.get_variables(res)[name])
            @test length(legend) == size(data, 2)
            @test typeof(variable_stack) == PG.StackedArea
        end
        gen_stack = PG.get_stacked_generation_data(results)
        @test typeof(gen_stack) == PG.StackedGeneration
    end
    @testset "test plot production" begin
        path = mkdir(joinpath(file_path, "plots"))
        PG.bar_plot(res; save = path, display = false, title = "Title_Bar")
        PG.stack_plot(res; save = path, display = false, title = "Title_Stack")
        PG.fuel_plot(res, generators; save = path, display = false)
        list = readdir(path)
        @test list == [
            "Fuel_Bar.png",
            "Fuel_Stack.png",
            "P_RenewableDispatch_Bar.png",
            "P_RenewableDispatch_Stack.png",
            "P_ThermalStandard_Bar.png",
            "P_ThermalStandard_Stack.png",
            "Title_Bar.png",
            "Title_Stack.png",
        ]
    end

    @testset "test fewer variable plot production" begin
        path = mkdir(joinpath(file_path, "variables"))
        variables = [:P_ThermalStandard]
        PG.bar_plot(res, variables; save = path, display = false, title = "Title_Bar")
        PG.stack_plot(res, variables; save = path, display = false, title = "Title_Stack")
        PG.fuel_plot(
            res,
            variables,
            generators;
            save = path,
            display = false,
            title = "Title_fuel",
        )
        list = readdir(path)
        @test list == [
            "P_ThermalStandard_Bar.png",
            "P_ThermalStandard_Stack.png",
            "Title_Bar.png",
            "Title_Stack.png",
            "Title_fuel_Bar.png",
            "Title_fuel_Stack.png",
        ]
    end

    @testset "test multi-plot production" begin
        path = mkdir(joinpath(file_path, "multi-plots"))
        PG.bar_plot([res; res]; save = path, display = false, title = "Title_Stack")
        PG.stack_plot([res; res]; save = path, display = false, title = "Title_Bar")
        PG.fuel_plot(
            [res; res],
            generators;
            save = path,
            display = false,
            title = "Title_fuel",
        )
        list = readdir(path)
        @test list == [
            "P_RenewableDispatch_Bar.png",
            "P_RenewableDispatch_Stack.png",
            "P_ThermalStandard_Bar.png",
            "P_ThermalStandard_Stack.png",
            "Title_Bar.png",
            "Title_Stack.png",
            "Title_fuel_Bar.png",
            "Title_fuel_Stack.png",
        ]
    end

    @testset "test multi-plot variable production" begin
        path = mkdir(joinpath(file_path, "multi-plots-variables"))
        variables = [:P_ThermalStandard]
        PG.bar_plot(
            [res; res],
            variables;
            save = path,
            display = false,
            title = "Title_Stack",
        )
        PG.stack_plot(
            [res; res],
            variables;
            save = path,
            display = false,
            title = "Title_Bar",
        )
        PG.fuel_plot(
            [res; res],
            variables,
            generators;
            save = path,
            display = false,
            title = "Title_fuel",
        )
        list = readdir(path)
        @test list == [
            "P_ThermalStandard_Bar.png",
            "P_ThermalStandard_Stack.png",
            "Title_Bar.png",
            "Title_Stack.png",
            "Title_fuel_Bar.png",
            "Title_fuel_Stack.png",
        ]
    end

    Plots.plotlyjs()
    @testset "test plotlyjs production" begin
        path = mkdir(joinpath(file_path, "jsplots"))
        PG.bar_plot(res; save = path, display = false, title = "Title_Bar", format = "png")
        PG.stack_plot(
            res;
            save = path,
            display = false,
            title = "Title_Stack",
            format = "png",
        )
        PG.fuel_plot(res, generators; save = path, display = false, format = "png")
        list = readdir(path)
        @test list == [
            "Fuel_Bar.png",
            "Fuel_Stack.png",
            "P_RenewableDispatch_Bar.png",
            "P_RenewableDispatch_Stack.png",
            "P_ThermalStandard_Bar.png",
            "P_ThermalStandard_Stack.png",
            "Title_Bar.png",
            "Title_Stack.png",
        ]
    end

    @testset "test fewer variable plotlyjs production" begin
        path = mkdir(joinpath(file_path, "variables_plotlyjs"))
        variables = [:P_ThermalStandard]
        PG.bar_plot(
            res,
            variables;
            save = path,
            display = false,
            title = "Title_Bar",
            format = "png",
        )
        PG.stack_plot(
            res,
            variables;
            save = path,
            display = false,
            title = "Title_Stack",
            format = "png",
        )
        PG.fuel_plot(
            res,
            variables,
            generators;
            save = path,
            display = false,
            title = "Title_fuel",
            format = "png",
        )
        list = readdir(path)
        @test list == [
            "P_ThermalStandard_Bar.png",
            "P_ThermalStandard_Stack.png",
            "Title_Bar.png",
            "Title_Stack.png",
            "Title_fuel_Bar.png",
            "Title_fuel_Stack.png",
        ]
    end

    @testset "test multi-plotlyjs production" begin
        path = mkdir(joinpath(file_path, "multi-plotlyjs"))
        PG.bar_plot(
            [res; res];
            save = path,
            display = false,
            title = "Title_Stack",
            format = "png",
        )
        PG.stack_plot(
            [res; res];
            save = path,
            display = false,
            title = "Title_Bar",
            format = "png",
        )
        PG.fuel_plot(
            [res; res],
            generators;
            save = path,
            display = false,
            title = "Title_fuel",
            format = "png",
        )
        list = readdir(path)
        @test list == [
            "P_RenewableDispatch_Bar.png",
            "P_RenewableDispatch_Stack.png",
            "P_ThermalStandard_Bar.png",
            "P_ThermalStandard_Stack.png",
            "Title_Bar.png",
            "Title_Stack.png",
            "Title_fuel_Bar.png",
            "Title_fuel_Stack.png",
        ]
    end

    @testset "test multi-plotlyjs variable production" begin
        path = mkdir(joinpath(file_path, "multi-plotlyjs-variables"))
        variables = [:P_ThermalStandard]
        PG.bar_plot(
            [res; res],
            variables;
            save = path,
            display = false,
            title = "Title_Stack",
            format = "png",
        )
        PG.stack_plot(
            [res; res],
            variables;
            save = path,
            display = false,
            title = "Title_Bar",
            format = "png",
        )
        PG.fuel_plot(
            [res; res],
            variables,
            generators;
            save = path,
            display = false,
            title = "Title_fuel",
            format = "png",
        )
        list = readdir(path)
        @test list == [
            "P_ThermalStandard_Bar.png",
            "P_ThermalStandard_Stack.png",
            "Title_Bar.png",
            "Title_Stack.png",
            "Title_fuel_Bar.png",
            "Title_fuel_Stack.png",
        ]
    end

end
try
    test_plots(path)
finally
    @info("removing test files")
    rm(path, recursive = true)
end
