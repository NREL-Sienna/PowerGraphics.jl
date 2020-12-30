#=
@testset "test results sorting" begin
    namez = collect(names(IS.get_variables(res)[:P__ThermalStandard]))
    Variabless = Dict(:P__ThermalStandard => [namez[1], namez[2]])
    sorted = PG.sort_data(res; Variables = Variabless)
    sorted_two = PG.sort_data(res)
    sorted_names = [namez[1], namez[2]]
    @test names(IS.get_variables(sorted)[:P__ThermalStandard]) == sorted_names
    @test names(IS.get_variables(sorted_two)[:P__ThermalStandard]) == sort(namez)
end
=#
(results_uc, results_ed) = run_test_sim(TEST_RESULT_DIR)

@testset "test filter results" begin
    gen = PG.get_generation_data(results_uc, curtailment = false)
    @test length(gen.data) == 4
    @test length(gen.time) == 48

    gen = PG.get_generation_data(
        results_uc,
        names = [
            :P__ThermalStandard,
            :P__RenewableDispatch,
            :P__max_active_power__RenewableDispatch,
        ],
        initial_time = Dates.DateTime("2024-01-02T02:00:00"),
        len = 3,
    )
    @test length(gen.data) == 3
    @test length(gen.time) == 3

    load = PG.get_load_data(results_ed)
    @test length(load.data) == 2
    @test length(load.time) == 576

    load = PG.get_load_data(
        results_ed,
        names = [:P__max_active_power__PowerLoad],
        initial_time = Dates.DateTime("2024-01-02T02:00:00"),
        len = 3,
    )
    @test length(load.data) == 1
    @test length(load.time) == 3

    srv = PG.get_service_data(results_ed)
    @test length(srv.data) == 0

    srv = PG.get_service_data(
        results_uc,
        names = [:Reserve11__VariableReserve_ReserveUp],
        initial_time = Dates.DateTime("2024-01-02T02:00:00"),
        len = 5,
    )
    @test length(srv.data) == 1
    @test length(srv.time) == 5
end

@testset "test data aggregation" begin
    gen = PG.get_generation_data(results_uc)

    cat = PG.make_fuel_dictionary(results_uc.system)
    @test isempty(symdiff(keys(cat), ["Coal", "Wind", "Hydropower"]))

    fuel = PG.categorize_data(gen.data, cat)
    @test length(fuel) == 4

    fuel_agg = PG.combine_categories(fuel)
    @test size(fuel_agg) == (48, 4)
end
