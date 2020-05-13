path = joinpath(pwd(), "plots")
!isdir(path) && mkdir(path)

function test_plots(file_path::String)
    include("get_test_data.jl")
    variables = [:P__ThermalStandard]
    @testset "test results sorting" begin
        namez = collect(names(IS.get_variables(res)[:P__ThermalStandard]))
        Variabless = Dict(:P__ThermalStandard => [namez[1], namez[2]])
        sorted = PG.sort_data(res; Variables = Variabless)
        sorted_two = PG.sort_data(res)
        sorted_names = [namez[1], namez[2]]
        @test names(IS.get_variables(sorted)[:P__ThermalStandard]) == sorted_names
        @test names(IS.get_variables(sorted_two)[:P__ThermalStandard]) == sort(namez)
    end

    @testset "test plot production" begin
        path = mkdir(joinpath(file_path, "plots"))
        PG.bar_plot(res; save = path, display = false, title = "Title_Bar")
        PG.stack_plot(res; save = path, display = false, title = "Title_Stack")
        PG.stair_plot(res; save = path, display = false, title = "Title_Stair")
        PG.fuel_plot(res, c_sys5_re; save = path, display = false)
        PG.fuel_plot(res, c_sys5_re; save = path, stair = true, display = false)
        list = readdir(path)
        @test isempty(setdiff(
            list,
            [
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
                "P__FixedGeneration_Bar.png",
                "P__FixedGeneration_Stack.png",
                "P__FixedGeneration_Stair.png",
                "P__PowerLoad_Bar.png",
                "P__PowerLoad_Stack.png",
                "P__PowerLoad_Stair.png",
            ],
        ))
    end

    @testset "test fewer variable plot production" begin
        path = mkdir(joinpath(file_path, "variables"))
        variables = [:P__ThermalStandard]
        PG.bar_plot(res, variables; save = path, display = false, title = "Title_Bar")
        PG.stack_plot(res, variables; save = path, display = false, title = "Title_Stack")
        PG.stair_plot(res, variables; save = path, display = false, title = "Title_Stair")
        PG.fuel_plot(
            res,
            variables,
            c_sys5_re;
            save = path,
            display = false,
            title = "Title_fuel",
        )
        list = readdir(path)
        @test isempty(setdiff(
            list,
            [
                "P__ThermalStandard_Bar.png",
                "P__ThermalStandard_Stack.png",
                "P__ThermalStandard_Stair.png",
                "Title_Bar.png",
                "Title_Stack.png",
                "Title_Stair.png",
                "Title_fuel_Bar.png",
                "Title_fuel_Stack.png",
                "P__FixedGeneration_Bar.png",
                "P__FixedGeneration_Stack.png",
                "P__FixedGeneration_Stair.png",
                "P__PowerLoad_Bar.png",
                "P__PowerLoad_Stack.png",
                "P__PowerLoad_Stair.png",
            ],
        ))
    end

    @testset "test multi-plot production" begin
        path = mkdir(joinpath(file_path, "multi-plots"))
        PG.bar_plot([res; res]; save = path, display = false, title = "Title_Bar")
        PG.stack_plot([res; res]; save = path, display = false, title = "Title_Stack")
        PG.stair_plot([res; res]; save = path, display = false, title = "Title_Stair")
        PG.fuel_plot(
            [res; res],
            c_sys5_re;
            save = path,
            display = false,
            title = "Title_fuel",
        )
        list = readdir(path)
        @test isempty(setdiff(
            list,
            [
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
                "P__FixedGeneration_Bar.png",
                "P__FixedGeneration_Stack.png",
                "P__FixedGeneration_Stair.png",
                "P__PowerLoad_Bar.png",
                "P__PowerLoad_Stack.png",
                "P__PowerLoad_Stair.png",
            ],
        ))
    end

    @testset "test multi-plot variable production" begin
        path = mkdir(joinpath(file_path, "multi-plots-variables"))
        variables = [:P__ThermalStandard]
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
            c_sys5_re;
            save = path,
            display = false,
            title = "Title_fuel",
        )
        PG.fuel_plot(
            [res; res],
            variables,
            c_sys5_re;
            save = path,
            display = false,
            title = "Title_fuel",
            stair = true,
        )
        list = readdir(path)
        @test isempty(setdiff(
            list,
            [
                "P__ThermalStandard_Bar.png",
                "P__ThermalStandard_Stack.png",
                "P__ThermalStandard_Stair.png",
                "Title_Bar.png",
                "Title_Stack.png",
                "Title_Stair.png",
                "Title_fuel_Bar.png",
                "Title_fuel_Stack.png",
                "Title_fuel_Stair.png",
                "P__FixedGeneration_Bar.png",
                "P__FixedGeneration_Stack.png",
                "P__FixedGeneration_Stair.png",
                "P__PowerLoad_Bar.png",
                "P__PowerLoad_Stack.png",
                "P__PowerLoad_Stair.png",
            ],
        ))
    end
    @testset "Test Demand Plots" begin
        path = mkdir(joinpath(file_path, "demand"))
        PG.demand_plot(res; title = "Plot", save = path)
        PG.demand_plot([res, res]; title = "Multi-Plot", save = path)
        PG.demand_plot(res; title = "Plot_Stair", stair = true, save = path)
        PG.demand_plot(res; title = "Plot_Shorten", save = path, horizon = 6, initial_time = Dates.DateTime(2024, 1, 1, 2, 0, 0))
        PG.demand_plot([res, res]; title = "Multi-Plot_Stair", stair = true, save = path)
        PG.demand_plot(c_sys5; title = "System", save = path)
        PG.demand_plot([c_sys5, c_sys5]; title = "Systems", save = path)
        PG.demand_plot(c_sys5; title = "System_Shorten", save = path, horizon = 6, initial_time = Dates.DateTime(2024, 1, 1, 2, 0, 0))
        list = readdir(path)
        @test list == [
            "Multi-Plot.png",
            "Multi-Plot_Stair.png",
            "Plot.png",
            "Plot_Shorten.png",
            "Plot_Stair.png",
            "System.png",
            "System_Shorten.png",
            "Systems.png",
        ]
    end

    @testset "Test Fuel plot with system" begin
        path = mkdir(joinpath(file_path, "fuel"))
        PG.fuel_plot(res, c_sys5; title = "Fuel", save = path, format = "png")
        PG.fuel_plot(
            res,
            variables,
            c_sys5;
            title = "Fuel_var",
            save = path,
            format = "png",
        )
        PG.fuel_plot([res, res], c_sys5; title = "Fuels", save = path, format = "png")
        PG.fuel_plot(
            [res, res],
            variables,
            c_sys5;
            title = "Fuels_var",
            save = path,
            format = "png",
        )
        list = readdir(path)
        @test list == [
            "Fuel_Bar.png",
            "Fuel_Stack.png",
            "Fuel_var_Bar.png",
            "Fuel_var_Stack.png",
            "Fuels_Bar.png",
            "Fuels_Stack.png",
            "Fuels_var_Bar.png",
            "Fuels_var_Stack.png",
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
        PG.stair_plot(
            res;
            save = path,
            display = false,
            title = "Title_Stair",
            format = "png",
        )
        PG.fuel_plot(res, c_sys5_re; save = path, display = false, format = "png")
        PG.fuel_plot(
            res,
            c_sys5_re;
            save = path,
            stair = true,
            display = false,
            format = "png",
        )
        list = readdir(path)
        @test isempty(setdiff(
            list,
            [
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
                "P__FixedGeneration_Bar.png",
                "P__FixedGeneration_Stack.png",
                "P__FixedGeneration_Stair.png",
                "P__PowerLoad_Bar.png",
                "P__PowerLoad_Stack.png",
                "P__PowerLoad_Stair.png",
            ],
        ))
    end

    @testset "test fewer variable plotlyjs production" begin
        path = mkdir(joinpath(file_path, "variables_plotlyjs"))
        variables = [:P__ThermalStandard]
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
            c_sys5_re;
            save = path,
            display = false,
            title = "Title_fuel",
            format = "png",
        )
        PG.fuel_plot(
            res,
            variables,
            c_sys5_re;
            save = path,
            display = false,
            stair = true,
            title = "Title_fuel",
            format = "png",
        )
        list = readdir(path)
        @test isempty(setdiff(
            list,
            [
                "P__ThermalStandard_Bar.png",
                "P__ThermalStandard_Stack.png",
                "P__ThermalStandard_Stair.png",
                "Title_Bar.png",
                "Title_Stack.png",
                "Title_Stair.png",
                "Title_fuel_Bar.png",
                "Title_fuel_Stack.png",
                "Title_fuel_Stair.png",
                "P__FixedGeneration_Bar.png",
                "P__FixedGeneration_Stack.png",
                "P__FixedGeneration_Stair.png",
                "P__PowerLoad_Bar.png",
                "P__PowerLoad_Stack.png",
                "P__PowerLoad_Stair.png",
            ],
        ))
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
            c_sys5_re;
            save = path,
            display = false,
            title = "Title_fuel",
            format = "png",
        )
        PG.fuel_plot(
            [res; res],
            c_sys5_re;
            save = path,
            display = false,
            stair = true,
            title = "Title_fuel",
            format = "png",
        )
        list = readdir(path)
        @test isempty(setdiff(
            list,
            [
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
                "P__FixedGeneration_Bar.png",
                "P__FixedGeneration_Stack.png",
                "P__FixedGeneration_Stair.png",
                "P__PowerLoad_Bar.png",
                "P__PowerLoad_Stack.png",
                "P__PowerLoad_Stair.png",
            ],
        ))
    end

    @testset "test multi-plotlyjs variable production" begin
        path = mkdir(joinpath(file_path, "multi-plotlyjs-variables"))
        variables = [:P__ThermalStandard]
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
            c_sys5_re;
            save = path,
            display = false,
            title = "Title_fuel",
            format = "png",
        )
        list = readdir(path)
        @test isempty(setdiff(
            list,
            [
                "P__ThermalStandard_Bar.png",
                "P__ThermalStandard_Stack.png",
                "P__ThermalStandard_Stair.png",
                "Title_Bar.png",
                "Title_Stack.png",
                "Title_Stair.png",
                "Title_fuel_Bar.png",
                "Title_fuel_Stack.png",
                "P__FixedGeneration_Bar.png",
                "P__FixedGeneration_Stack.png",
                "P__FixedGeneration_Stair.png",
                "P__PowerLoad_Bar.png",
                "P__PowerLoad_Stack.png",
                "P__PowerLoad_Stair.png",
            ],
        ))
    end
    @testset "Test PlotlyJS Fuel plot with system" begin
        path = mkdir(joinpath(file_path, "plotly-fuel"))
        #    maps = PG.get_generator_mapping()
        #    generators = PG.make_fuel_dictionary()
        PG.fuel_plot(res, c_sys5; title = "Fuel", save = path, format = "png")
        PG.fuel_plot(
            res,
            variables,
            c_sys5;
            title = "Fuel_var",
            save = path,
            format = "png",
        )
        PG.fuel_plot([res, res], c_sys5; title = "Fuels", save = path, format = "png")
        PG.fuel_plot(
            [res, res],
            variables,
            c_sys5;
            title = "Fuels_var",
            save = path,
            format = "png",
        )
        list = readdir(path)
        @test list == [
            "Fuel_Bar.png",
            "Fuel_Stack.png",
            "Fuel_var_Bar.png",
            "Fuel_var_Stack.png",
            "Fuels_Bar.png",
            "Fuels_Stack.png",
            "Fuels_var_Bar.png",
            "Fuels_var_Stack.png",
        ]
    end
    @testset "Test PlotlyJS Demand Plots" begin
        path = mkdir(joinpath(file_path, "plotly-multi-plots"))
        PG.demand_plot(res; title = "PlotlyJS", save = path, format = "png")
        PG.demand_plot(res; title = "PlotlyJS_Shorten", save = path, horizon = 6, format = "png", initial_time = Dates.DateTime(2024, 1, 1, 2, 0, 0))
        PG.demand_plot([res, res]; title = "multi-PlotlyJS", save = path, format = "png")
        PG.demand_plot(c_sys5; title = "System", save = path, format = "png")
        PG.demand_plot([c_sys5, c_sys5]; title = "Systems", save = path, format = "png")
        PG.demand_plot(c_sys5; title = "System_Shorten", save = path, horizon = 6, format = "png", initial_time = Dates.DateTime(2024, 1, 1, 2, 0, 0))
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
            "PlotlyJS_Shorten.png",
            "PlotlyJS_Stair.png",
            "System.png",
            "System_Shorten.png",
            "Systems.png",
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
