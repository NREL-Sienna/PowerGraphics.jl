variables = Dict{Symbol, DataFrames.DataFrame}()
variables[:P__ThermalStandard] = DataFrames.DataFrame(
    :one => [1, 2, 3, 2, 1],
    :two => [3, 2, 1, 2, 3],
    :three => [1, 2, 3, 2, 1],
)
variables[:P__RenewableDispatch] = DataFrames.DataFrame(
    :one => [3, 2, 3, 2, 3],
    :two => [1, 2, 1, 2, 1],
    :three => [3, 2, 3, 2, 3],
)

parameters = Dict{Symbol, DataFrames.DataFrame}()
parameters[:parameter_P_FixedGeneration] = DataFrames.DataFrame(
    :one => [2, 2, 1, 2, 2],
    :two => [3, 4, 1, 2, 2],
    :three => [3, 2, 3, 1, 1],
)

parameters[:parameter_P_PowerLoad] = DataFrames.DataFrame(
    :one => [3, 1, 3, 2, 1],
    :two => [1, 2, 1, 1, 1],
    :three => [3, 3, 3, 2, 3],
)
optimizer_log = Dict()
objective_value = Dict()
dual_values = Dict{Symbol, Any}()
base_power = 100.0
right_now = round(Dates.now(), Dates.Hour)
timestamp =
    DataFrames.DataFrame(:Range => right_now:Dates.Hour(1):(right_now + Dates.Hour(4)))
res = PG.Results(
    base_power,
    variables,
    optimizer_log,
    objective_value,
    timestamp,
    dual_values,
    parameters,
)

generators = Dict("Coal" => [:one; :two], "Wind" => [:three])

function run_test_sim(result_dir::String)
    sim_name = "results_sim"
    sim_path = joinpath(result_dir, sim_name)
    if ispath(sim_path)
        executions = tryparse.(Int, readdir(sim_path))
        sim = joinpath(sim_path, string(maximum(executions)))
        @info "Reading results from last execution" sim
    else
        mkpath(result_dir)
        GLPK_optimizer =
            optimizer_with_attributes(GLPK.Optimizer, "msg_lev" => GLPK.GLP_MSG_OFF)
        c_sys5_hy_uc = build_system("c_sys5_hy_uc")
        c_sys5_hy_ed = build_system("c_sys5_hy_ed")

        branches = Dict()
        services = Dict()
        devices = Dict(
            :Generators => DeviceModel(ThermalStandard, ThermalStandardUnitCommitment),
            :Ren => DeviceModel(RenewableDispatch, RenewableFullDispatch),
            :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
            :ILoads => DeviceModel(InterruptibleLoad, DispatchablePowerLoad),
            :HydroEnergyReservoir =>
                DeviceModel(HydroEnergyReservoir, HydroDispatchReservoirStorage),
            :HydroROR => DeviceModel(HydroDispatch, FixedOutput),
        )
        template_hydro_st_uc =
            OperationsProblemTemplate(CopperPlatePowerModel, devices, branches, services)

        devices = Dict(
            :Generators => DeviceModel(ThermalStandard, ThermalDispatch),
            :Ren => DeviceModel(RenewableDispatch, RenewableFullDispatch),
            :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
            :ILoads => DeviceModel(InterruptibleLoad, DispatchablePowerLoad),
            :HydroEnergyReservoir =>
                DeviceModel(HydroEnergyReservoir, HydroDispatchReservoirStorage),
            :HydroROR => DeviceModel(HydroDispatch, FixedOutput),
        )
        template_hydro_st_ed =
            OperationsProblemTemplate(CopperPlatePowerModel, devices, branches, services)
        stages_definition = Dict(
            "UC" => Stage(
                GenericOpProblem,
                template_hydro_st_uc,
                c_sys5_hy_uc,
                GLPK_optimizer,
            ),
            "ED" => Stage(
                GenericOpProblem,
                template_hydro_st_ed,
                c_sys5_hy_ed,
                GLPK_optimizer,
                constraint_duals = [:CopperPlateBalance],
            ),
        )

        sequence_cache = SimulationSequence(
            step_resolution = Hour(24),
            order = Dict(1 => "UC", 2 => "ED"),
            feedforward_chronologies = Dict(("UC" => "ED") => Synchronize(periods = 24)),
            horizons = Dict("UC" => 24, "ED" => 12),
            intervals = Dict(
                "UC" => (Hour(24), Consecutive()),
                "ED" => (Hour(1), Consecutive()),
            ),
            feedforward = Dict(
                ("ED", :devices, :Generators) => SemiContinuousFF(
                    binary_source_stage = PSI.ON,
                    affected_variables = [PSI.ACTIVE_POWER],
                ),
                ("ED", :devices, :HydroEnergyReservoir) => IntegralLimitFF(
                    variable_source_stage = PSI.ACTIVE_POWER,
                    affected_variables = [PSI.ACTIVE_POWER],
                ),
            ),
            cache = Dict(
                ("UC",) => TimeStatusChange(PSY.ThermalStandard, PSI.ON),
                ("UC", "ED") => StoredEnergy(PSY.HydroEnergyReservoir, PSI.ENERGY),
            ),
            ini_cond_chronology = InterStageChronology(),
        )
        sim = Simulation(
            name = "results_sim",
            steps = 2,
            stages = stages_definition,
            stages_sequence = sequence_cache,
            simulation_folder = result_dir,
        )
        build!(sim)
        execute!(sim)
    end

    results = SimulationResults(sim)
    results_uc = get_stage_results(results, "UC")
    results_ed = get_stage_results(results, "ED")

    return results_uc, results_ed
end
