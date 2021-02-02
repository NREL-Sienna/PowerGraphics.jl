# PowerGraphics

[![codecov](https://codecov.io/gh/nrel-siip/PowerGraphics.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/nrel-siip/PowerGraphics.jl)

PowerGraphics.jl is a Julia package for plotting results from [PowerSimulations.jl](https://github.com/NREL/PowerSimulations.jl).

## Installation

```julia
julia> ]
(v1.3) pkg> add PowerGraphics
```
## Usage

`PowerGraphics.jl` uses [PowerSystems.jl](https://github.com/NREL/PowerSystems.jl) and [PowerSimulations.jl](https://github.com/NREL/PowerSimulations.jl) to handle the data and execution power system simulations.

```julia
using PowerGraphics
# where "res" is a PowerSimulations.SimulationResults object
gen = get_generation_data(res)
plot_pgdata(gen)
```

`PowerGraphics.jl` creates figures using a number of optional backends using `Plots.jl`. For interactive figures, it is recommended to use the `PlotlyJS.jl` backend, which requires the `PlotlyJS.jl`:

```julia
using Pkg
Pkg.add("PlotlyJS")
```

When using `PowerGraphics.jl` within a jupyter notebook, `WebIO.jl` is also required (*and depending on the local configuration of nbextensions, some [additional steps](https://juliagizmos.github.io/WebIO.jl/latest/troubleshooting/not-detected/) may be required):

```julia
Pkg.add("WebIO")
```

An additional command (`plotlyjs()`) to startup the `PlotlyJS` backend from `Plots` is required:

```julia
using PowerGraphics
plotlyjs()
# where "res" is a PowerSimulations.SimulationResults object
plot_fuel(res)
```

## Development

Contributions to the development and enahancement of PowerGraphics is welcome. Please see [CONTRIBUTING.md](https://github.com/NREL-SIIP/PowerGraphics.jl/blob/master/CONTRIBUTING.md) for code contribution guidelines.

## License

PowerGraphics is released under a BSD [license](https://github.com/nrel-siip/PowerGraphics.jl/blob/master/LICENSE). PowerGraphics has been developed as part of the Scalable Integrated Infrastructure Planning (SIIP)
initiative at the U.S. Department of Energy's National Renewable Energy Laboratory ([NREL](https://www.nrel.gov/))
