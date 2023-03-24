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

    fx = RenewableFix(
        "RoofTopSolar",
        true,
        get_component(Bus, sys, "bus5"),
        0.0,
        0.0,
        1.100,
        PrimeMovers.PVe,
        1.0,
        10.0,
    )
    add_component!(sys, fx)
    copy_time_series!(fx, get_component(PowerLoad, sys, "bus2"))

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

    batt = GenericBattery(
        "test_batt",
        true,
        get_component(Bus, sys, "bus4"),
        PrimeMovers.BA,
        0.0,
        (min = 0.0, max = 1.0),
        1.0,
        0.0,
        (min = 0.0, max = 1.0),
        (min = 0.0, max = 1.0),
        (in = 1.0, out = 1.0),
        0.0,
        nothing,
        10.0,
    )
    add_component!(sys, batt)
end

function run_test_sim(result_dir::String)
    sim_name = "results_sim"
    sim_path = joinpath(result_dir, sim_name)

    if ispath(sim_path)
        @info "Reading UC system from" sim_path
        c_sys5_hy_uc = System(
            joinpath(sim_path, "..", "c_sys5_hy_uc.json"),
            time_series_read_only = true,
        )
        @info "Reading ED system from" sim_path
        c_sys5_hy_ed = System(
            joinpath(sim_path, "..", "c_sys5_hy_ed.json"),
            time_series_read_only = true,
        )
        executions = tryparse.(Int, readdir(sim_path))
        sim = joinpath(sim_path, string(maximum(executions)))
        @info "Reading results from last execution" sim
    else
        @info "Building UC system from"
        c_sys5_hy_uc = PSB.build_system(PSB.PSISystems, "5_bus_hydro_uc_sys")
        @info "Building ED system from"
        c_sys5_hy_ed = PSB.build_system(PSB.PSISystems, "5_bus_hydro_ed_sys")

        @info "Adding extra RE"
        add_re!(c_sys5_hy_uc)
        add_re!(c_sys5_hy_ed)
        to_json(c_sys5_hy_uc, joinpath(sim_path, "..", "c_sys5_hy_uc.json"), force = true)
        to_json(c_sys5_hy_ed, joinpath(sim_path, "..", "c_sys5_hy_ed.json"), force = true)

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
        set_device_model!(template_hydro_st_uc, GenericBattery, BookKeeping)

        template_hydro_st_ed = template_economic_dispatch(
            network = CopperPlatePowerModel,
            use_slacks = true,
            duals = [CopperPlateBalanceConstraint],
        )
        set_device_model!(template_hydro_st_ed, HydroDispatch, FixedOutput)
        set_device_model!(
            template_hydro_st_ed,
            HydroEnergyReservoir,
            HydroDispatchReservoirStorage,
        )
        set_device_model!(template_hydro_st_ed, GenericBattery, BookKeeping)
        template_hydro_st_ed.services = Dict() #remove ed services
        models = SimulationModels(
            decision_models = [
                DecisionModel(
                    template_hydro_st_uc,
                    c_sys5_hy_uc,
                    optimizer = GLPK_optimizer,
                    name = "UC",
                    system_to_file = false,
                ),
                DecisionModel(
                    template_hydro_st_ed,
                    c_sys5_hy_ed,
                    optimizer = GLPK_optimizer,
                    name = "ED",
                    system_to_file = false,
                ),
            ],
        )

        sequence = SimulationSequence(
            models = models,
            feedforwards = feedforward = Dict(
                "ED" => [
                    SemiContinuousFeedforward(
                        component_type = ThermalStandard,
                        source = OnVariable,
                        affected_values = [ActivePowerVariable],
                    ),
                    EnergyLimitFeedforward(
                        component_type = HydroEnergyReservoir,
                        source = ActivePowerVariable,
                        affected_values = [ActivePowerVariable],
                        number_of_periods = 12,
                    ),
                ],
            ),
            ini_cond_chronology = InterProblemChronology(),
        )
        sim = Simulation(
            name = "results_sim",
            steps = 2,
            models = models,
            sequence = sequence,
            simulation_folder = result_dir,
        )
        build!(sim)
        execute!(sim)
    end

    results = SimulationResults(sim)
    results_uc = get_decision_problem_results(results, "UC")
    set_system!(results_uc, c_sys5_hy_uc)
    results_ed = get_decision_problem_results(results, "ED")
    set_system!(results_ed, c_sys5_hy_ed)

    return results_uc, results_ed
end

function run_test_prob()
    c_sys5_hy_uc = PSB.build_system(PSB.PSISystems, "5_bus_hydro_uc_sys")
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

    prob = DecisionModel(
        template_hydro_st_uc,
        c_sys5_hy_uc,
        optimizer = GLPK_optimizer,
        horizon = 12,
    )
    build!(prob, output_dir = mktempdir())
    solve!(prob)
    res = ProblemResults(prob)
    return res
end
