file_path = TEST_OUTPUTS

function test_plots(file_path::String; backend_pkg::String = "gr")
    if backend_pkg == "gr"
        Plots.gr()
    elseif backend_pkg == "plotlyjs"
        Plots.plotlyjs()
    else
        throw(error("$backend_pkg backend_pkg not supported"))
    end
    set_display = false
    cleanup = true

    (results_uc, results_ed) = run_test_sim(TEST_RESULT_DIR)
    gen_uc = PG.get_generation_data(results_uc)
    gen_ed = PG.get_generation_data(results_ed)
    load_uc = PG.get_load_data(results_uc)
    load_ed = PG.get_load_data(results_ed)
    svc_uc = PG.get_service_data(results_uc)
    svc_ed = PG.get_service_data(results_ed)

    @testset "test $backend_pkg plot production" begin
        out_path = joinpath(file_path, backend_pkg * "_plots")
        !isdir(out_path) && mkdir(out_path)
        plot_dataframe(
            gen_uc.data[:P__ThermalStandard],
            gen_uc.time,
            set_display = set_display,
            title = "df_line",
            save = out_path,
        )
        plot_dataframe(
            gen_uc.data[:P__ThermalStandard],
            gen_uc.time,
            set_display = set_display,
            title = "df_stack",
            save = out_path,
            stack = true,
        )
        plot_dataframe(
            gen_uc.data[:P__ThermalStandard],
            gen_uc.time,
            set_display = set_display,
            title = "df_stair",
            save = out_path,
            stair = true,
        )
        plot_dataframe(
            gen_uc.data[:P__ThermalStandard],
            gen_uc.time,
            set_display = set_display,
            title = "df_bar",
            save = out_path,
            bar = true,
        )
        plot_dataframe(
            gen_uc.data[:P__ThermalStandard],
            gen_uc.time,
            set_display = set_display,
            title = "df_bar_stack",
            save = out_path,
            bar = true,
            stack = true,
        )

        plot_dataframe(
            plot_dataframe(
                gen_uc.data[:P__ThermalStandard],
                gen_uc.time,
                set_display = set_display,
                stack = true,
            ),
            load_uc.data[:P__PowerLoad] .* -1,
            gen_uc.time,
            set_display = set_display,
            title = "df_gen_load",
            save = out_path,
        )

        list = readdir(out_path)
        expected_files = [
            "df_line.png",
            "df_stack.png",
            "df_stair.png",
            "df_bar.png",
            "df_bar_stack.png",
            "df_gen_load.png",
        ]
        # expected results not created
        @test isempty(setdiff(expected_files, list))
        # extra results created
        @test isempty(setdiff(list, expected_files))

        @info("removing test files")
        cleanup && rm(out_path, recursive = true)
    end

    @testset "test $backend_pkg pgdata plot production" begin
        out_path = joinpath(file_path, backend_pkg * "_pgdata_plots")
        !isdir(out_path) && mkdir(out_path)

        PG.plot_pgdata(
            gen_uc,
            set_display = set_display,
            title = "pg_data",
            save = out_path,
            bar = false,
            stack = false,
        )
        PG.plot_pgdata(
            gen_uc,
            set_display = set_display,
            title = "pg_data_stack",
            save = out_path,
            bar = false,
            stack = true,
        )
        PG.plot_pgdata(
            gen_uc,
            set_display = set_display,
            title = "pg_data_bar",
            save = out_path,
            bar = true,
            stack = false,
        )
        PG.plot_pgdata(
            gen_uc,
            set_display = set_display,
            title = "pg_data_bar_stack",
            save = out_path,
            bar = true,
            stack = true,
        )

        list = readdir(out_path)
        expected_files =
            ["pg_data.png", "pg_data_stack.png", "pg_data_bar.png", "pg_data_bar_stack.png"]
        # expected results not created
        @test isempty(setdiff(expected_files, list))
        # extra results created
        @test isempty(setdiff(list, expected_files))

        @info("removing test files")
        cleanup && rm(out_path, recursive = true)
    end

    @testset "test $backend_pkg demand plot production" begin
        out_path = joinpath(file_path, backend_pkg * "_demand_plots")
        !isdir(out_path) && mkdir(out_path)
        PG.plot_demand(
            results_uc,
            set_display = set_display,
            title = "demand",
            save = out_path,
            bar = false,
            stack = false,
            nofill = false,
        )
        PG.plot_demand(
            results_uc,
            set_display = set_display,
            title = "demand_stack",
            save = out_path,
            bar = false,
            stack = true,
            nofill = false,
        )
        PG.plot_demand(
            results_uc,
            set_display = set_display,
            title = "demand_bar",
            save = out_path,
            bar = true,
            stack = false,
            nofill = false,
        )
        PG.plot_demand(
            results_uc,
            set_display = set_display,
            title = "demand_bar_stack",
            save = out_path,
            bar = true,
            stack = true,
            nofill = false,
        )
        PG.plot_demand(
            results_uc,
            set_display = set_display,
            title = "demand_nofill",
            save = out_path,
            bar = false,
            stack = false,
            nofill = true,
        )
        PG.plot_demand(
            results_uc,
            set_display = set_display,
            title = "demand_nofill_stack",
            save = out_path,
            bar = false,
            stack = true,
            nofill = true,
        )
        PG.plot_demand(
            results_uc,
            set_display = set_display,
            title = "demand_nofill_bar",
            save = out_path,
            bar = true,
            stack = false,
            nofill = true,
        )
        PG.plot_demand(
            results_uc,
            set_display = set_display,
            title = "demand_nofill_bar_stack",
            save = out_path,
            bar = true,
            stack = true,
            nofill = true,
        )

        PG.plot_demands(
            [results_uc, results_ed],
            set_display = set_display,
            title = "demand_multi",
            save = out_path,
        )

        PG.plot_demand(
            results_uc.system,
            set_display = set_display,
            title = "sysdemand",
            save = out_path,
        )

        list = readdir(out_path)
        expected_files = [
            "demand.png",
            "demand_stack.png",
            "demand_bar.png",
            "demand_bar_stack.png",
            "demand_nofill.png",
            "demand_nofill_stack.png",
            "demand_nofill_bar.png",
            "demand_nofill_bar_stack.png",
            "sysdemand.png",
        ]
        # expected results not created
        @test isempty(setdiff(expected_files, list))
        # extra results created
        @test isempty(setdiff(list, expected_files))

        @info("removing test files")
        cleanup && rm(out_path, recursive = true)
    end

    @testset "test $backend_pkg fuel plot production" begin
        out_path = joinpath(file_path, backend_pkg * "_fuel_plots")
        !isdir(out_path) && mkdir(out_path)

        PG.plot_fuel(
            results_uc,
            set_display = set_display,
            title = "fuel",
            save = out_path,
            bar = false,
            stack = false,
        )
        PG.plot_fuel(
            results_uc,
            set_display = set_display,
            title = "fuel_stack",
            save = out_path,
            bar = false,
            stack = true,
        )
        PG.plot_fuel(
            results_uc,
            set_display = set_display,
            title = "fuel_bar",
            save = out_path,
            bar = true,
            stack = false,
        )
        PG.plot_fuel(
            results_uc,
            set_display = set_display,
            title = "fuel_bar_stack",
            save = out_path,
            bar = true,
            stack = true,
        )

        PG.plot_fuels(
            [results_uc, results_ed],
            set_display = set_display,
            title = "fuel_multi",
            save = out_path,
        )

        list = readdir(out_path)
        expected_files =
            ["fuel.png", "fuel_stack.png", "fuel_bar.png", "fuel_bar_stack.png"]
        # expected results not created
        @test isempty(setdiff(expected_files, list))
        # extra results created
        @test isempty(setdiff(list, expected_files))

        @info("removing test files")
        cleanup && rm(out_path, recursive = true)
    end
end
try
    test_plots(file_path, backend_pkg = "gr")
    test_plots(file_path, backend_pkg = "plotlyjs")
finally
    nothing
end
