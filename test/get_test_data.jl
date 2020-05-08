time_steps = 1:24

base_dir = string(dirname(dirname(pathof(PowerGraphics))))
DATA_DIR = joinpath(base_dir, "test")
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

nodes = nodes5()
c_sys5_ml = System(
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
    for (ix, l) in enumerate(get_components(PowerLoad, c_sys5_ml))
        add_forecast!(
            c_sys5_ml,
            l,
            Deterministic("get_maxactivepower", load_timeseries_DA[t][ix]),
        )
    end
end
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
GLPK_optimizer = JuMP.optimizer_with_attributes(GLPK.Optimizer, "msg_lev" => GLPK.MSG_OFF)
res = PSI.run_economic_dispatch(c_sys5; optimizer = GLPK_optimizer)
