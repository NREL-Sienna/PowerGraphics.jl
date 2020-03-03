# PowerGraphics

[![Build Status](https://img.shields.io/travis/com/nrel-siip/PowerGraphics.jl/master.svg)](https://travis-ci.com/nrel-siip/PowerGraphics.jl)
[![codecov](https://codecov.io/gh/nrel-siip/PowerGraphics.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/nrel-siip/PowerGraphics.jl)

PowerGraphics.jl is a Julia package for plotting results from [PowerSimulations.jl](https://github.com/NREL/PowerSimulations.jl).

## Installation

```julia
julia> ]
(v1.3) pkg> add PowerGraphics.jl
```
## Usage

`PowerGraphics.jl` uses [PowerSystems.jl](https://github.com/NREL/PowerSystems.jl) and [PowerSimulations.jl](https://github.com/NREL/PowerSimulations.jl) to handle the data and execution power system simulations.

```julia
using PowerGraphics
# where "res" is a PowerSimulations.SimulationResults object
stack_plot(res)
```

`PowerGraphics.jl` creates figures using a number of optional backends using `Plots.jl`. For interactive figures, it is recommended to use the `PlotlyJS.jl` backend, which requires the `PlotlyJS.jl` and `ORCA.jl` packages:

```julia
using Pkg
Pkg.add("PlotlyJS")
Pkg.add("ORCA")
```

An additional command (`plotlyjs()`) to startup the `PlotlyJS` backend from `Plots` is required:

```julia
using PowerGraphics
PowerGraphics.Plots.plotlyjs()
# where "res" is a PowerSimulations.SimulationResults object,
# and "sys" is a PowerSystems.System object
fuel_plot(res, sys)
```

## Development

Contributions to the development and enahancement of PowerGraphics is welcome. Please see [CONTRIBUTING.md](https://github.com/NREL-SIIP/PowerGraphics.jl/blob/master/CONTRIBUTING.md) for code contribution guidelines.

## License

PowerGraphics is released under a BSD [license](https://github.com/nrel-siip/PowerGraphics.jl/blob/master/LICENSE). PowerGraphics has been developed as part of the Scalable Integrated Infrastructure Planning (SIIP)
initiative at the U.S. Department of Energy's National Renewable Energy Laboratory ([NREL](https://www.nrel.gov/))
