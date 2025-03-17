# Change Backends

`PowerGraphics.jl` relies on [`Plots.jl`](https://docs.juliaplots.org/stable/) to enable
plotting via different backends. See the `Plots.jl` section on [backends](@extref Plots)
for more details. Currently, two backends are supported in `PowerGraphics.jl`:

  - [GR](@extref Plots [GR](https://github.com/jheinen/GR.jl)) (default): creates static
    plots - run the `gr()` command to load
  - [PlotlyJS](@extref Plots [Plotly-/-PlotlyJS](https://github.com/spencerlyon2/PlotlyJS.jl)):
    creates interactive plots - run the `plotlyjs()` command to load

If you run neither command, `PowerGraphics.jl` will default to using GR.
