function add_re!(sys)
    re = RenewableDispatch(
        "WindBusA",
        true,
        get_component(Bus, sys, "bus5"),
        0.0,
        0.0,
        1.200,
        PrimeMovers.WT,
        (min = 0.0, max = 0.0),
        1.0,
        TwoPartCost(0.220, 0.0),
        100.0,
    )
    add_component!(sys, re)
    copy_time_series!(re, get_component(PowerLoad, sys, "bus2"))

    for g in get_components(HydroEnergyReservoir, sys)
        tpc = get_operation_cost(g)
        smc = StorageManagementCost(
            variable = get_variable(tpc),
            fixed = get_fixed(tpc),
            start_up = 0.0,
            shut_down = 0.0,
            energy_shortage_cost = 10.0,
            energy_surplus_cost = 10.0,
        )
        set_operation_cost!(g, smc)
    end
end

function run_test_sim(result_dir::String)
    sim_name = "results_sim"
    sim_path = joinpath(result_dir, sim_name)

    if ispath(sim_path)
        c_sys5_hy_uc = System(joinpath(sim_path, "..", "c_sys5_hy_uc.json"))
        c_sys5_hy_ed = System(joinpath(sim_path, "..", "c_sys5_hy_ed.json"))
        executions = tryparse.(Int, readdir(sim_path))
        sim = joinpath(sim_path, string(maximum(executions)))
        @info "Reading results from last execution" sim
    else
        c_sys5_hy_uc = PSB.build_system(PSB.SIIPExampleSystems, "5_bus_hydro_uc_sys")
        c_sys5_hy_ed = PSB.build_system(PSB.SIIPExampleSystems, "5_bus_hydro_ed_sys")

        add_re!(c_sys5_hy_uc)
        add_re!(c_sys5_hy_ed)
        to_json(c_sys5_hy_uc, joinpath(sim_path, "..", "c_sys5_hy_uc.json"))
        to_json(c_sys5_hy_ed, joinpath(sim_path, "..", "c_sys5_hy_ed.json"))

        mkpath(result_dir)
        GLPK_optimizer =
            optimizer_with_attributes(GLPK.Optimizer, "msg_lev" => GLPK.GLP_MSG_OFF)

        template_hydro_st_uc = template_unit_commitment()
        set_device_model!(template_hydro_st_uc, HydroDispatch, FixedOutput)
        set_device_model!(
            template_hydro_st_uc,
            HydroEnergyReservoir,
            HydroDispatchReservoirStorage,
        )

        template_hydro_st_ed = template_economic_dispatch()
        set_device_model!(template_hydro_st_ed, HydroDispatch, FixedOutput)
        set_device_model!(
            template_hydro_st_ed,
            HydroEnergyReservoir,
            HydroDispatchReservoirStorage,
        )
        template_hydro_st_ed.services = Dict() #remove ed services

        problems = SimulationProblems(
            UC = OperationsProblem(
                template_hydro_st_uc,
                c_sys5_hy_uc,
                optimizer = GLPK_optimizer,
                system_to_file = false,
            ),
            ED = OperationsProblem(
                template_hydro_st_ed,
                c_sys5_hy_ed,
                optimizer = GLPK_optimizer,
                constraint_duals = [:CopperPlateBalance],
                system_to_file = false,
                balance_slack_variables = true,
            ),
        )

        sequence = SimulationSequence(
            problems = problems,
            feedforward_chronologies = Dict(("UC" => "ED") => Synchronize(periods = 24)),
            intervals = Dict(
                "UC" => (Hour(24), Consecutive()),
                "ED" => (Hour(1), Consecutive()),
            ),
            feedforward = Dict(
                ("ED", :devices, :ThermalStandard) => SemiContinuousFF(
                    binary_source_problem = PSI.ON,
                    affected_variables = [PSI.ACTIVE_POWER],
                ),
                ("ED", :devices, :HydroEnergyReservoir) => IntegralLimitFF(
                    variable_source_problem = PSI.ACTIVE_POWER,
                    affected_variables = [PSI.ACTIVE_POWER],
                ),
            ),
            cache = Dict(
                ("UC",) => TimeStatusChange(PSY.ThermalStandard, PSI.ON),
                ("UC", "ED") => StoredEnergy(PSY.HydroEnergyReservoir, PSI.ENERGY),
            ),
            ini_cond_chronology = InterProblemChronology(),
        )
        sim = Simulation(
            name = "results_sim",
            steps = 2,
            problems = problems,
            sequence = sequence,
            simulation_folder = result_dir,
        )
        build!(sim)
        execute!(sim)
    end

    results = SimulationResults(sim)
    results_uc = get_problem_results(results, "UC")
    set_system!(results_uc, c_sys5_hy_uc)
    results_ed = get_problem_results(results, "ED")
    set_system!(results_ed, c_sys5_hy_ed)

    return results_uc, results_ed
end

function run_test_prob()
    c_sys5_hy_uc = PSB.build_system(PSB.SIIPExampleSystems, "5_bus_hydro_uc_sys")
    add_re!(c_sys5_hy_uc)
    GLPK_optimizer =
        optimizer_with_attributes(GLPK.Optimizer, "msg_lev" => GLPK.GLP_MSG_OFF)

    template_hydro_st_uc = template_unit_commitment()
    set_device_model!(template_hydro_st_uc, HydroDispatch, FixedOutput)
    set_device_model!(
        template_hydro_st_uc,
        HydroEnergyReservoir,
        HydroDispatchReservoirStorage,
    )

    prob = OperationsProblem(
        template_hydro_st_uc,
        c_sys5_hy_uc,
        optimizer = GLPK_optimizer,
        horizon = 12,
        use_parameters = true,
    )
    build!(prob, output_dir = mktempdir())
    solve!(prob)
    res = ProblemResults(prob)
    return res
end
