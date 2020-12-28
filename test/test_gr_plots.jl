file_path = TEST_OUTPUTS

function test_gr_plots(file_path::String)
    (results_uc, results_ed) = run_test_sim(TEST_RESULT_DIR)

    @testset "test GR plot production" begin
        path = joinpath(file_path, "plots")
        !isdir(path) && mkdir(path)
        PG.bar_plot(
            results_uc;
            save = path,
            display = false,
            title = "Title_Bar",
            load = true,
            curtailment = true,
        )
        PG.stack_plot(
            results_uc;
            save = path,
            display = false,
            title = "Title_Stack",
            load = true,
            curtailment = true,
        )
        PG.stack_plot(
            [results_uc];
            save = path,
            display = false,
            title = "Title_Stair",
            stair = true,
            load = true,
            curtailment = true,
        )
        PG.fuel_plot(
            results_uc;
            save = path,
            display = false,
            title = "Fuel_stack",
            load = true,
            curtailment = true,
        )
        PG.fuel_plot(
            [results_ed];
            save = path,
            stair = true,
            display = false,
            title = "Fuel_stair",
            load = true,
            curtailment = true,
        )
        list = readdir(path)
        expected_files = [
            "Fuel_stack_Bar.png",
            "Fuel_stack_Stack.png",
            "Fuel_stair_Bar.png",
            "Fuel_stair_Stair.png",
            "P__RenewableDispatch_Bar.png",
            "P__RenewableDispatch_Stack.png",
            "P__RenewableDispatch_Stair.png",
            "P__HydroDispatch_Bar.png",
            "P__HydroDispatch_Stack.png",
            "P__HydroDispatch_Stair.png",
            "P__ThermalStandard_Bar.png",
            "P__ThermalStandard_Stack.png",
            "P__ThermalStandard_Stair.png",
            "P__HydroEnergyReservoir_Bar.png",
            "P__HydroEnergyReservoir_Stack.png",
            "P__HydroEnergyReservoir_Stair.png",
            "Title_Bar.png",
            "Title_Stack.png",
            "Title_Stair.png",
            "Curtailment_Bar.png",
            "Curtailment_Stack.png",
            "Curtailment_Stair.png",
        ]
        # expected results not created
        @test isempty(setdiff(expected_files, list))
        # extra results created
        @test isempty(setdiff(list, expected_files))
    end

    @testset "test fewer variable GR plot production" begin
        path = joinpath(file_path, "variables")
        !isdir(path) && mkdir(path)
        variables = [:P__ThermalStandard]
        PG.bar_plot(
            results_uc;
            names = variables,
            save = path,
            display = false,
            title = "Title_Bar",
        )
        PG.stack_plot(
            results_uc;
            names = variables,
            save = path,
            display = false,
            title = "Title_Stack",
            load = true,
        )
        PG.stack_plot(
            results_uc;
            names = variables,
            save = path,
            display = false,
            stair = true,
            title = "Title_Stair",
        )
        PG.fuel_plot(
            results_uc;
            names = variables,
            save = path,
            display = false,
            title = "Title_fuel",
        )
        list = readdir(path)
        expected_files = [
            "P__ThermalStandard_Bar.png",
            "P__ThermalStandard_Stack.png",
            "P__ThermalStandard_Stair.png",
            "Title_Bar.png",
            "Title_Stack.png",
            "Title_Stair.png",
            "Title_fuel_Bar.png",
            "Title_fuel_Stack.png",
        ]
        # expected results not created
        @test isempty(setdiff(expected_files, list))
        # extra results created
        @test isempty(setdiff(list, expected_files))
    end

    @testset "test multi GR plot production" begin
        path = joinpath(file_path, "multi-plots")
        !isdir(path) && mkdir(path)
        PG.bar_plot(
            [results_uc; results_uc];
            save = path,
            display = false,
            title = "Title_Bar",
        )
        PG.stack_plot(
            [results_ed; results_ed];
            save = path,
            load = true,
            curtailment = true,
            display = false,
            title = "Title_Stack",
        )
        PG.fuel_plot(
            [results_uc; results_uc],
            save = path,
            display = false,
            title = "Title_fuel",
        )
        list = readdir(path)
        expected_files = [
            "Curtailment_Stack.png",
            "P__HydroDispatch_Bar.png",
            "P__HydroDispatch_Stack.png",
            "P__HydroEnergyReservoir_Bar.png",
            "P__HydroEnergyReservoir_Stack.png",
            "P__InterruptibleLoad_Stack.png",
            "P__RenewableDispatch_Bar.png",
            "P__RenewableDispatch_Stack.png",
            "P__ThermalStandard_Bar.png",
            "P__ThermalStandard_Stack.png",
            "Title_Bar.png",
            "Title_Stack.png",
            "Title_fuel_Bar.png",
            "Title_fuel_Stack.png",
        ]

        # expected results not created
        @test isempty(setdiff(expected_files, list))
        # extra results created
        @test isempty(setdiff(list, expected_files))
    end

    @testset "Test demand GR plot production" begin
        path = joinpath(file_path, "demand")
        !isdir(path) && mkdir(path)

        PG.plot_demand(results_ed; title = "Plot", save = path)
        PG.plot_demand([results_uc, results_ed]; title = "Multi-Plot", save = path)
        PG.plot_demand(results_ed; title = "Plot_Stair", stair = true, save = path)
        PG.plot_demand(
            results_ed;
            title = "Plot_Shorten",
            save = path,
            horizon = 6,
            initial_time = Dates.DateTime(2024, 1, 1, 2, 0, 0),
        )

        test_sys = get_system(results_uc)
        PG.plot_demand(test_sys; title = "System", save = path)
        PG.plot_demand([test_sys, test_sys]; title = "Systems", save = path)
        PG.plot_demand(
            test_sys;
            title = "System_Shorten",
            save = path,
            horizon = 6,
            initial_time = Dates.DateTime(2024, 1, 2, 0, 0, 0),
        )
        list = readdir(path)
        expected_files = [
            "Multi-Plot.png",
            "Plot.png",
            "Plot_Shorten.png",
            "Plot_Stair.png",
            "System.png",
            "System_Shorten.png",
            "Systems.png",
        ]
        # expected results not created
        @test isempty(setdiff(expected_files, list))
        # extra results created
        @test isempty(setdiff(list, expected_files))
    end
end
try
    test_gr_plots(file_path)
finally
    @info("removing test files")
    rm(file_path, recursive = true)
end
