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
            display = display,
            title = "df_line",
            save = out_path,
        )
        plot_dataframe(
            gen_uc.data[:P__ThermalStandard],
            gen_uc.time,
            display = display,
            title = "df_stack",
            save = out_path,
            stack = true,
        )
        plot_dataframe(
            gen_uc.data[:P__ThermalStandard],
            gen_uc.time,
            display = display,
            title = "df_stair",
            save = out_path,
            stair = true,
        )

        plot_dataframe(
            gen_uc.data[:P__ThermalStandard],
            gen_uc.time,
            display = display,
            title = "df_bar",
            save = out_path,
            bar = true,
        )
        plot_dataframe(
            gen_uc.data[:P__ThermalStandard],
            gen_uc.time,
            display = display,
            title = "df_bar_stack",
            save = out_path,
            bar = true,
            stack = true,
        )

        p = plot_dataframe(
            gen_uc.data[:P__ThermalStandard],
            gen_uc.time,
            display = false,
            stack = true,
        )
        plot_dataframe(
            p,
            load_uc.data[:P__PowerLoad] .* -1,
            gen_uc.time,
            display = display,
            title = "df_gen_load",
            save = out_path,
        )

        # aggregate by something like fuel or region

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
        rm(out_path, recursive = true)
    end

    @testset "test $backend_pkg pgdata plot production" begin
        out_path = joinpath(file_path, backend_pkg * "_pgdata_plots")
        !isdir(out_path) && mkdir(out_path)

        PG.plot_pgdata(
            gen_uc,
            display = display,
            title = "pg_data",
            save = out_path,
            bar = false,
            stack = false,
        )
        PG.plot_pgdata(
            gen_uc,
            display = display,
            title = "pg_data_stack",
            save = out_path,
            bar = false,
            stack = true,
        )
        PG.plot_pgdata(
            gen_uc,
            display = display,
            title = "pg_data_bar",
            save = out_path,
            bar = true,
            stack = false,
        )
        PG.plot_pgdata(
            gen_uc,
            display = display,
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
        rm(out_path, recursive = true)
    end

    @testset "test $backend_pkg fuel plot production" begin
        out_path = joinpath(file_path, backend_pkg * "_fuel_plots")
        !isdir(out_path) && mkdir(out_path)

        PG.plot_fuel(
            results_uc,
            display = display,
            title = "fuel",
            save = out_path,
            bar = false,
            stack = false,
        )
        PG.plot_fuel(
            results_uc,
            display = display,
            title = "fuel_stack",
            save = out_path,
            bar = false,
            stack = true,
        )
        PG.plot_fuel(
            results_uc,
            display = display,
            title = "fuel_bar",
            save = out_path,
            bar = true,
            stack = false,
        )
        PG.plot_fuel(
            results_uc,
            display = display,
            title = "fuel_bar_stack",
            save = out_path,
            bar = true,
            stack = true,
        )

        list = readdir(out_path)
        expected_files =
            ["fuel.png", "fuel_stack.png", "fuel_bar.png", "fuel_bar_stack.png"]
        # expected results not created
        @test isempty(setdiff(expected_files, list))
        # extra results created
        @test isempty(setdiff(list, expected_files))

        @info("removing test files")
        rm(out_path, recursive = true)
    end
end
try
    test_plots(file_path, backend_pkg = "gr")
    #test_plots(file_path, backend_pkg = "plotlyjs")
finally
    nothing
end
