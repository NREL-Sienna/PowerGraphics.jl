# Change Backends

`PowerGraphics.jl` relies on [`Plots.jl`](https://docs.juliaplots.org/stable/) to enable
plotting via different backends. Currently, two backends are supported:

  - GR (default): creates static plots - run the `gr()` command to load
  - PlotlyJS: creates interactive plots - run the `plotlyjs()` command to load
