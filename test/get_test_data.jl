time_steps = 1:24

base_dir = string(dirname(dirname(pathof(PowerGraphics))))
DATA_DIR = joinpath(base_dir, "test/")
include(joinpath(DATA_DIR, "data_5bus_pu.jl"))

#Base Systems
nodes = nodes5()
c_sys5 = System(
    nodes,
    thermal_generators5(nodes),
    loads5(nodes),
    branches5(nodes),
    nothing,
    100.0,
    nothing,
    nothing,
)
for t in 1:2
    for (ix, l) in enumerate(get_components(PowerLoad, c_sys5))
        add_forecast!(
            c_sys5,
            l,
            Deterministic("get_maxactivepower", load_timeseries_DA[t][ix]),
        )
    end
end


PTDF5 = PTDF(c_sys5);

#System with Renewable Energy
nodes = nodes5()
c_sys5_re = System(
    nodes,
    vcat(thermal_generators5(nodes), renewable_generators5(nodes)),
    loads5(nodes),
    branches5(nodes),
    nothing,
    100.0,
    nothing,
    nothing,
)
for t in 1:2
    for (ix, l) in enumerate(get_components(PowerLoad, c_sys5_re))
        add_forecast!(
            c_sys5_re,
            l,
            Deterministic("get_maxactivepower", load_timeseries_DA[t][ix]),
        )
    end
    for (ix, r) in enumerate(get_components(RenewableGen, c_sys5_re))
        add_forecast!(c_sys5_re, r, Deterministic("get_rating", ren_timeseries_DA[t][ix]))
    end
end

nodes = nodes5()
c_sys5_re_only = System(
    nodes,
    renewable_generators5(nodes),
    loads5(nodes),
    branches5(nodes),
    nothing,
    100.0,
    nothing,
    nothing,
)
for t in 1:2
    for (ix, l) in enumerate(get_components(PowerLoad, c_sys5_re_only))
        add_forecast!(
            c_sys5_re_only,
            l,
            Deterministic("get_maxactivepower", load_timeseries_DA[t][ix]),
        )
    end
    for (ix, r) in enumerate(get_components(RenewableGen, c_sys5_re_only))
        add_forecast!(
            c_sys5_re_only,
            r,
            Deterministic("get_rating", ren_timeseries_DA[t][ix]),
        )
    end
end

nodes = nodes5()
# System with HydroPower Energy
c_sys5_hy = System(
    nodes,
    vcat(thermal_generators5(nodes), hydro_generators5(nodes)[1]),
    loads5(nodes),
    branches5(nodes),
    nothing,
    100.0,
    nothing,
    nothing,
)
for t in 1:2
    for (ix, l) in enumerate(get_components(PowerLoad, c_sys5_hy))
        add_forecast!(
            c_sys5_hy,
            l,
            Deterministic("get_maxactivepower", load_timeseries_DA[t][ix]),
        )
    end
    for (ix, h) in enumerate(get_components(HydroGen, c_sys5_hy))
        add_forecast!(c_sys5_hy, h, Deterministic("get_rating", hydro_timeseries_DA[t][ix]))
    end
end

nodes = nodes5()
c_sys5_hyd = System(
    nodes,
    vcat(thermal_generators5(nodes), hydro_generators5(nodes)[2]),
    loads5(nodes),
    branches5(nodes),
    nothing,
    100.0,
    nothing,
    nothing,
)
for t in 1:2
    for (ix, l) in enumerate(get_components(PowerLoad, c_sys5_hyd))
        add_forecast!(
            c_sys5_hyd,
            l,
            Deterministic("get_maxactivepower", load_timeseries_DA[t][ix]),
        )
    end
    for (ix, h) in enumerate(get_components(HydroGen, c_sys5_hyd))
        add_forecast!(
            c_sys5_hyd,
            h,
            Deterministic("get_rating", hydro_timeseries_DA[t][ix]),
        )
    end
    for (ix, h) in enumerate(get_components(HydroEnergyReservoir, c_sys5_hyd))
        add_forecast!(
            c_sys5_hyd,
            h,
            Deterministic("get_storage_capacity", hydro_timeseries_DA[t][ix]),
        )
    end
    for (ix, h) in enumerate(get_components(HydroEnergyReservoir, c_sys5_hyd))
        add_forecast!(
            c_sys5_hyd,
            h,
            Deterministic("get_inflow", hydro_timeseries_DA[t][ix] .* 0.8),
        )
    end
end

GLPK_optimizer = JuMP.optimizer_with_attributes(GLPK.Optimizer, "msg_lev" => GLPK.MSG_OFF)
ED = PSI.EconomicDispatchProblem(c_sys5; use_parameters = true)
res = PSI.solve!(ED; optimizer = GLPK_optimizer)
