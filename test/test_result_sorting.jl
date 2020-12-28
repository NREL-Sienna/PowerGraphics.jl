@testset "test results sorting" begin
    namez = collect(names(IS.get_variables(res)[:P__ThermalStandard]))
    Variabless = Dict(:P__ThermalStandard => [namez[1], namez[2]])
    sorted = PG.sort_data(res; Variables = Variabless)
    sorted_two = PG.sort_data(res)
    sorted_names = [namez[1], namez[2]]
    @test names(IS.get_variables(sorted)[:P__ThermalStandard]) == sorted_names
    @test names(IS.get_variables(sorted_two)[:P__ThermalStandard]) == sort(namez)
end

(results_uc, results_ed) = run_test_sim(TEST_RESULT_DIR)

@testset "test filter results" begin
    (results_uc, results_ed) = run_test_sim(TEST_RESULT_DIR)

    result = PG._filter_results(results_uc, names = Vector{Symbol}(), load = true)
    @test isempty(IS.get_variables(result))
    @test collect(keys(IS.get_parameters(result))) == [PG.LOAD_PARAMETER]

    result = PG._filter_results(results_ed, names = Vector{Symbol}(), load = true)
    @test collect(keys(IS.get_variables(result))) == [PG.ILOAD_VARIABLE]
    @test isempty(symdiff(
        collect(keys(IS.get_parameters(result))),
        [PG.LOAD_PARAMETER, PG.ILOAD_PARAMETER],
    ))
end
