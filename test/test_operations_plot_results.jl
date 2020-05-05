path = joinpath(pwd(), "plots")
!isdir(path) && mkdir(path)

function test_plots(file_path::String)
    include("test_data.jl")

    @testset "test results sorting" begin
        Variables = Dict(:P__ThermalStandard => [:one, :two])
        sorted = PG.sort_data(res; Variables = Variables)
        sorted_two = PG.sort_data(res)
        sorted_names = [:one, :two]
        sorted_names_two = [:one, :three, :two]
        @test names(IS.get_variables(sorted)[:P__ThermalStandard]) == sorted_names
        @test names(IS.get_variables(sorted_two)[:P__ThermalStandard]) == sorted_names_two
    end

    @testset "test plot production" begin
        path = mkdir(joinpath(file_path, "plots"))
        PG.bar_plot(res; save = path, display = false, title = "Title_Bar")
        PG.stack_plot(res; save = path, display = false, title = "Title_Stack")
        PG.stair_plot(res; save = path, display = false, title = "Title_Stair")
        PG.fuel_plot(res, generators; save = path, display = false)
        PG.fuel_plot(res, generators; save = path, stair = true, display = false)
        list = readdir(path)
        @test list == [
            "Fuel_Bar.png",
            "Fuel_Stack.png",
            "Fuel_Stair.png",
            "P__RenewableDispatch_Bar.png",
            "P__RenewableDispatch_Stack.png",
            "P__RenewableDispatch_Stair.png",
            "P__ThermalStandard_Bar.png",
            "P__ThermalStandard_Stack.png",
            "P__ThermalStandard_Stair.png",
            "Title_Bar.png",
            "Title_Stack.png",
            "Title_Stair.png",
        ]
    end

    @testset "test fewer variable plot production" begin
        path = mkdir(joinpath(file_path, "variables"))
        variables = [:P_ThermalStandard]
        PG.bar_plot(res, variables; save = path, display = false, title = "Title_Bar")
        PG.stack_plot(res, variables; save = path, display = false, title = "Title_Stack")
        PG.stair_plot(res, variables; save = path, display = false, title = "Title_Stair")
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
            "P__ThermalStandard_Bar.png",
            "P__ThermalStandard_Stack.png",
            "P__ThermalStandard_Stair.png",
            "Title_Bar.png",
            "Title_Stack.png",
            "Title_Stair.png",
            "Title_fuel_Bar.png",
            "Title_fuel_Stack.png",
        ]
    end

    @testset "test multi-plot production" begin
        path = mkdir(joinpath(file_path, "multi-plots"))
        PG.bar_plot([res; res]; save = path, display = false, title = "Title_Bar")
        PG.stack_plot([res; res]; save = path, display = false, title = "Title_Stack")
        PG.stair_plot([res; res]; save = path, display = false, title = "Title_Stair")
        PG.fuel_plot(
            [res; res],
            generators;
            save = path,
            display = false,
            title = "Title_fuel",
        )
        list = readdir(path)
        @test list == [
            "P__RenewableDispatch_Bar.png",
            "P__RenewableDispatch_Stack.png",
            "P__RenewableDispatch_Stair.png",
            "P__ThermalStandard_Bar.png",
            "P__ThermalStandard_Stack.png",
            "P__ThermalStandard_Stair.png",
            "Title_Bar.png",
            "Title_Stack.png",
            "Title_Stair.png",
            "Title_fuel_Bar.png",
            "Title_fuel_Stack.png",
        ]
    end

    @testset "test multi-plot variable production" begin
        path = mkdir(joinpath(file_path, "multi-plots-variables"))
        variables = [:P_ThermalStandard]
        PG.bar_plot(
            [res, res],
            variables;
            save = path,
            display = false,
            title = "Title_Bar",
        )
        PG.stack_plot(
            [res, res],
            variables;
            save = path,
            display = false,
            title = "Title_Stack",
        )
        PG.stair_plot(
            [res, res],
            variables;
            save = path,
            display = false,
            title = "Title_Stair",
        )
        PG.fuel_plot(
            [res; res],
            variables,
            generators;
            save = path,
            display = false,
            title = "Title_fuel",
        )
        PG.fuel_plot(
            [res; res],
            variables,
            generators;
            save = path,
            display = false,
            title = "Title_fuel",
            stair = true,
        )
        list = readdir(path)
        @test list == [
            "P__ThermalStandard_Bar.png",
            "P__ThermalStandard_Stack.png",
            "P__ThermalStandard_Stair.png",
            "Title_Bar.png",
            "Title_Stack.png",
            "Title_Stair.png",
            "Title_fuel_Bar.png",
            "Title_fuel_Stack.png",
            "Title_fuel_Stair.png",
        ]
    end
    @testset "Test Demand Plots" begin
        path = mkdir(joinpath(file_path, "demand"))
        PG.demand_plot(res; title = "Plot", save = path)
        PG.demand_plot([res, res]; title = "Multi-Plot", save = path)
        PG.demand_plot(res; title = "Plot_Stair", stair = true, save = path)
        PG.demand_plot([res, res]; title = "Multi-Plot_Stair", stair = true, save = path)
        list = readdir(path)
        @test list ==
              ["Multi-Plot.png", "Multi-Plot_Stair.png", "Plot.png", "Plot_Stair.png"]
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
        PG.stair_plot(
            res;
            save = path,
            display = false,
            title = "Title_Stair",
            format = "png",
        )
        PG.fuel_plot(res, generators; save = path, display = false, format = "png")
        PG.fuel_plot(
            res,
            generators;
            save = path,
            stair = true,
            display = false,
            format = "png",
        )
        list = readdir(path)
        @test list == [
            "Fuel_Bar.png",
            "Fuel_Stack.png",
            "Fuel_Stair.png",
            "P__RenewableDispatch_Bar.png",
            "P__RenewableDispatch_Stack.png",
            "P__RenewableDispatch_Stair.png",
            "P__ThermalStandard_Bar.png",
            "P__ThermalStandard_Stack.png",
            "P__ThermalStandard_Stair.png",
            "Title_Bar.png",
            "Title_Stack.png",
            "Title_Stair.png",
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
        PG.stair_plot(
            res,
            variables;
            save = path,
            display = false,
            title = "Title_Stair",
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
        PG.fuel_plot(
            res,
            variables,
            generators;
            save = path,
            display = false,
            stair = true,
            title = "Title_fuel",
            format = "png",
        )
        list = readdir(path)
        @test list == [
            "P__ThermalStandard_Bar.png",
            "P__ThermalStandard_Stack.png",
            "P__ThermalStandard_Stair.png",
            "Title_Bar.png",
            "Title_Stack.png",
            "Title_Stair.png",
            "Title_fuel_Bar.png",
            "Title_fuel_Stack.png",
            "Title_fuel_Stair.png",
        ]
    end

    @testset "test multi-plotlyjs production" begin
        path = mkdir(joinpath(file_path, "multi-plotlyjs"))
        PG.bar_plot(
            [res; res];
            save = path,
            display = false,
            title = "Title_Bar",
            format = "png",
        )
        PG.stack_plot(
            [res; res];
            save = path,
            display = false,
            title = "Title_Stack",
            format = "png",
        )
        PG.stair_plot(
            [res; res];
            save = path,
            display = false,
            title = "Title_Stair",
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
        PG.fuel_plot(
            [res; res],
            generators;
            save = path,
            display = false,
            stair = true,
            title = "Title_fuel",
            format = "png",
        )
        list = readdir(path)
        @test list == [
            "P__RenewableDispatch_Bar.png",
            "P__RenewableDispatch_Stack.png",
            "P__RenewableDispatch_Stair.png",
            "P__ThermalStandard_Bar.png",
            "P__ThermalStandard_Stack.png",
            "P__ThermalStandard_Stair.png",
            "Title_Bar.png",
            "Title_Stack.png",
            "Title_Stair.png",
            "Title_fuel_Bar.png",
            "Title_fuel_Stack.png",
            "Title_fuel_Stair.png",
        ]
    end

    @testset "test multi-plotlyjs variable production" begin
        path = mkdir(joinpath(file_path, "multi-plotlyjs-variables"))
        variables = [:P_ThermalStandard]
        PG.bar_plot(
            [res, res],
            variables;
            save = path,
            display = false,
            title = "Title_Bar",
            format = "png",
        )
        PG.stack_plot(
            [res; res],
            variables;
            save = path,
            display = false,
            title = "Title_Stack",
            format = "png",
        )
        PG.stair_plot(
            [res; res],
            variables;
            save = path,
            display = false,
            title = "Title_Stair",
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
            "P__ThermalStandard_Bar.png",
            "P__ThermalStandard_Stack.png",
            "P__ThermalStandard_Stair.png",
            "Title_Bar.png",
            "Title_Stack.png",
            "Title_Stair.png",
            "Title_fuel_Bar.png",
            "Title_fuel_Stack.png",
        ]
    end

    @testset "Test PlotlyJS Demand Plots" begin
        path = mkdir(joinpath(file_path, "plotly-multi-plots"))
        PG.demand_plot(res; title = "PlotlyJS", save = path, format = "png")
        PG.demand_plot([res, res]; title = "multi-PlotlyJS", save = path, format = "png")
        PG.demand_plot(
            res;
            title = "PlotlyJS_Stair",
            stair = true,
            save = path,
            format = "png",
        )
        PG.demand_plot(
            [res, res];
            title = "multi-PlotlyJS_Stair",
            stair = true,
            save = path,
            format = "png",
        )
        list = readdir(path)
        @test list == [
            "PlotlyJS.png",
            "PlotlyJS_Stair.png",
            "multi-PlotlyJS.png",
            "multi-PlotlyJS_Stair.png",
        ]
    end

end
try
    test_plots(path)
finally
    @info("removing test files")
    rm(path, recursive = true)
end
