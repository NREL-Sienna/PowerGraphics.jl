function plot_dataframe(df, title; kwargs...)
    labels = names(df)
    p = Plots.plot()
    for (ix, c) in enumerate(eachcol(df))
        Plots.plot!(c, title = title, label = labels[ix]; kwargs...)
    end
    Plots.display(p)
    return p
end
