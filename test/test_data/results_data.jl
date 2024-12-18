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
        RenewableGenerationCost(CostCurve(LinearCurve(22.0))),
        100.0,
    )
    add_component!(sys, re)
    copy_time_series!(re, get_component(PowerLoad, sys, "bus2"))

    fx = RenewableNonDispatch(
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
        smc = StorageCost(;
            charge_variable_cost = CostCurve(LinearCurve(0.1)),
            discharge_variable_cost = CostCurve(LinearCurve(0.2)),
            energy_shortage_cost = 10.0,
            energy_surplus_cost = 10.0,
        )
        set_operation_cost!(g, smc)
    end

    batt = EnergyReservoirStorage(;
        name = "test_batt",
        available = true,
        bus = get_component(Bus, sys, "bus4"),
        prime_mover_type = PrimeMovers.BA,
        storage_technology_type = StorageTech.OTHER_CHEM,
        storage_capacity = 2.0,
        storage_level_limits = (min = 0.0, max = 1.0),
        initial_storage_capacity_level = 0.7,
        rating = 1.0,
        active_power = 0.1,
        input_active_power_limits = (min = 0.0, max = 1.0),
        output_active_power_limits = (min = 0.0, max = 1.0),
        efficiency = (in = 0.9, out = 0.9),
        reactive_power = 0.0,
        reactive_power_limits = (min = -1.0, max = 1.0),
        base_power = 15.0,
        operation_cost = StorageCost(;
            charge_variable_cost = CostCurve(LinearCurve(0.1)),
            discharge_variable_cost = CostCurve(LinearCurve(0.2)),
        ),
        conversion_factor = 1,
        storage_target = 0.0,
        cycle_limits = 5000,
    )
    add_component!(sys, batt)
end

function run_test_sim(result_dir::String)
    sim_name = "results_sim"
    sim_path = joinpath(result_dir, sim_name)

    if ispath(sim_path)
        @info "Reading UC system from" sim_path
        c_sys5_hy_uc = System(
            joinpath(sim_path, "..", "c_sys5_hy_uc.json");
            time_series_read_only = true,
        )
        @info "Reading ED system from" sim_path
        c_sys5_hy_ed = System(
            joinpath(sim_path, "..", "c_sys5_hy_ed.json");
            time_series_read_only = true,
        )
        results_folders = filter!(x -> occursin("results_sim", x), readdir(result_dir))
        sim = joinpath(result_dir, last(results_folders))
        @info "Reading results from last execution" last(results_folders)
    else
        @info "Building UC system from"
        c_sys5_hy_uc = PSB.build_system(PSB.PSISystems, "5_bus_hydro_uc_sys")
        @info "Building ED system from"
        c_sys5_hy_ed = PSB.build_system(PSB.PSISystems, "5_bus_hydro_ed_sys")
        transform_single_time_series!(c_sys5_hy_ed, Hour(1), Hour(1))

        @info "Adding extra RE"
        add_re!(c_sys5_hy_uc)
        add_re!(c_sys5_hy_ed)
        to_json(c_sys5_hy_uc, joinpath(sim_path, "..", "c_sys5_hy_uc.json"); force = true)
        to_json(c_sys5_hy_ed, joinpath(sim_path, "..", "c_sys5_hy_ed.json"); force = true)

        mkpath(result_dir)
        HiGHS_optimizer =
            optimizer_with_attributes(HiGHS.Optimizer)

        template_hydro_st_uc = template_unit_commitment()
        set_device_model!(template_hydro_st_uc, HydroDispatch, FixedOutput)
        set_device_model!(
            template_hydro_st_uc,
            HydroEnergyReservoir,
            HydroDispatchReservoirStorage,
        )
        set_device_model!(
            template_hydro_st_uc,
            EnergyReservoirStorage,
            StorageDispatchWithReserves,
        )

        template_hydro_st_ed = template_economic_dispatch(;
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
        set_device_model!(
            template_hydro_st_ed,
            EnergyReservoirStorage,
            StorageDispatchWithReserves,
        )
        template_hydro_st_ed.services = Dict() #remove ed services
        models = SimulationModels(;
            decision_models = [
                DecisionModel(
                    template_hydro_st_uc,
                    c_sys5_hy_uc;
                    optimizer = HiGHS_optimizer,
                    name = "UC",
                    system_to_file = false,
                    calculate_conflict = true,
                ),
                DecisionModel(
                    template_hydro_st_ed,
                    c_sys5_hy_ed;
                    optimizer = HiGHS_optimizer,
                    name = "ED",
                    system_to_file = false,
                    calculate_conflict = true,
                ),
            ],
        )

        sequence = SimulationSequence(;
            models = models,
            feedforwards = feedforward = Dict(
                "ED" => [
                    SemiContinuousFeedforward(;
                        component_type = ThermalStandard,
                        source = OnVariable,
                        affected_values = [ActivePowerVariable],
                    ),
                ],
            ),
            ini_cond_chronology = InterProblemChronology(),
        )
        sim = Simulation(;
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
    HiGHS_optimizer =
        optimizer_with_attributes(HiGHS.Optimizer)

    template_hydro_st_uc = template_unit_commitment()
    set_device_model!(template_hydro_st_uc, HydroDispatch, FixedOutput)
    set_device_model!(
        template_hydro_st_uc,
        HydroEnergyReservoir,
        HydroDispatchReservoirStorage,
    )

    prob = DecisionModel(
        template_hydro_st_uc,
        c_sys5_hy_uc;
        optimizer = HiGHS_optimizer,
        horizon = Hour(12),
    )
    build!(prob; output_dir = mktempdir())
    solve!(prob)
    res = OptimizationProblemResults(prob)
    return res
end
