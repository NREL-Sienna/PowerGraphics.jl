file_path = TEST_OUTPUTS

function test_plots(file_path::String; backend_pkg::String = "gr")
    if backend_pkg == "gr"
        Plots.gr()
    elseif backend_pkg == "plotlyjs"
        Plots.plotlyjs()
    else
        throw(error("$backend_pkg backend_pkg not supported"))
    end
    display = false

    (results_uc, results_ed) = run_test_sim(TEST_RESULT_DIR)

    @testset "test $backend_pkg plot production" begin
        path = joinpath(file_path, backend_pkg * "_plots")
        !isdir(path) && mkdir(path)
        PG.bar_plot(
            results_uc;
            save = path,
            display = display,
            title = "Title_Bar",
            load = true,
            curtailment = true,
            reserves = true,
        )
        PG.stack_plot(
            results_uc;
            save = path,
            display = display,
            title = "Title_Stack",
            load = true,
            curtailment = true,
            reserves = true,
        )
        PG.stack_plot(
            [results_uc];
            save = path,
            display = display,
            title = "Title_Stair",
            stair = true,
            load = true,
            curtailment = true,
            reserves = true,
        )
        PG.fuel_plot(
            results_uc;
            save = path,
            display = display,
            title = "Fuel_stack",
            load = true,
            curtailment = true,
            reserves = true,
        )
        PG.fuel_plot(
            [results_ed];
            save = path,
            stair = true,
            display = display,
            title = "Fuel_stair",
            load = true,
            curtailment = true,
            reserves = true,
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
            "Down_Reserves.png",
            "Up_Reserves.png",
        ]
        # expected results not created
        @test isempty(setdiff(expected_files, list))
        # extra results created
        @test isempty(setdiff(list, expected_files))

        @info("removing test files")
        rm(path, recursive = true)
    end

    @testset "test fewer variable $backend_pkg plot production" begin
        path = joinpath(file_path, backend_pkg * "_select_vars")
        !isdir(path) && mkdir(path)
        variables = [:P__ThermalStandard]
        PG.bar_plot(
            results_uc;
            names = variables,
            save = path,
            display = display,
            title = "Title_Bar",
        )
        PG.stack_plot(
            results_uc;
            names = variables,
            save = path,
            display = display,
            title = "Title_Stack",
            load = true,
        )
        PG.stack_plot(
            results_uc;
            names = variables,
            save = path,
            display = display,
            stair = true,
            title = "Title_Stair",
        )
        PG.fuel_plot(
            results_uc;
            names = variables,
            save = path,
            display = display,
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

        @info("removing test files")
        rm(path, recursive = true)
    end

    @testset "test multi $backend_pkg plot production" begin
        path = joinpath(file_path, backend_pkg * "_multi-plots")
        !isdir(path) && mkdir(path)
        PG.bar_plot(
            [results_uc; results_uc];
            save = path,
            display = display,
            title = "Title_Bar",
        )
        PG.stack_plot(
            [results_ed; results_ed];
            save = path,
            load = true,
            curtailment = true,
            display = display,
            title = "Title_Stack",
        )
        PG.fuel_plot(
            [results_uc; results_uc],
            save = path,
            display = display,
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

        @info("removing test files")
        rm(path, recursive = true)
    end

    @testset "Test demand $backend_pkg plot production" begin
        path = joinpath(file_path, backend_pkg * "_demand")
        !isdir(path) && mkdir(path)

        PG.plot_demand(results_ed; title = "Plot", save = path, display = display)
        # TODO: this should create two multi-plots
        PG.plot_demand(
            [results_uc, results_ed];
            title = "Multi-Plot",
            save = path,
            display = display,
        )
        PG.plot_demand(
            results_ed;
            title = "Plot_Stair",
            stair = true,
            save = path,
            display = display,
        )
        PG.plot_demand(
            results_ed;
            title = "Plot_Shorten",
            save = path,
            display = display,
            horizon = 6,
            initial_time = Dates.DateTime(2024, 1, 1, 2, 0, 0),
        )

        test_sys = get_system(results_uc)
        PG.plot_demand(test_sys; title = "System", save = path, display = display)
        PG.plot_demand(
            [test_sys, test_sys];
            title = "Systems",
            save = path,
            display = display,
        )
        PG.plot_demand(
            test_sys;
            title = "System_Shorten",
            save = path,
            display = display,
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

        @info("removing test files")
        rm(path, recursive = true)
    end

    @testset "Test variable $backend_pkg plot production" begin
        path = joinpath(file_path, backend_pkg * "_variable")
        !isdir(path) && mkdir(path)

        p = PG.plot_variable(
            results_ed,
            :P__ThermalStandard;
            title = "Plot",
            save = path,
            display = display,
        )
        PG.plot_variable(
            p,
            results_uc,
            :P__RenewableDispatch;
            title = "Plot-RE",
            save = path,
            display = display,
        )
        PG.plot_variable(
            results_uc,
            :P__HydroEnergyReservoir;
            initial_time = Dates.DateTime("2024-01-02T15:00:00"),
            title = "Plot-short",
            save = path,
            display = display,
        )

        list = readdir(path)
        expected_files = ["Plot-RE.png", "Plot.png", "Plot-short.png"]
        # expected results not created
        @test isempty(setdiff(expected_files, list))
        # extra results created
        @test isempty(setdiff(list, expected_files))

        @info("removing test files")
        rm(path, recursive = true)
    end

    @testset "Test dataframe $backend_pkg plot production" begin
        path = joinpath(file_path, backend_pkg * "_dataframe")
        !isdir(path) && mkdir(path)

        var_name = :P__ThermalStandard
        df = PSI.read_realized_variables(results_uc, names = [var_name])[var_name]
        time_range = PSI.get_realized_timestamps(results_uc)
        plot =
            plot_dataframe(df, time_range; title = "Plot", save = path, display = display)
        param_name = :In__inflow__HydroEnergyReservoir
        df = PSI.read_realized_parameters(results_uc, names = [param_name])[param_name]
        plot_dataframe(
            plot,
            df,
            time_range;
            title = "Plot-2",
            save = path,
            display = display,
        )
        list = readdir(path)
        expected_files = ["Plot-2.png", "Plot.png"]
        # expected results not created
        @test isempty(setdiff(expected_files, list))
        # extra results created
        @test isempty(setdiff(list, expected_files))

        @info("removing test files")
        rm(path, recursive = true)
    end
end
try
    test_plots(file_path, backend_pkg = "gr")
    test_plots(file_path, backend_pkg = "plotlyjs")
finally
    nothing
end
