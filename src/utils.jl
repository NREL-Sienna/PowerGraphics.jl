function plot_dataframe(df, title; kwargs...)
    labels = DataFrames.names(df)
    p = Plots.plot()
    for (ix, c) in enumerate(DataFrames.eachcol(df))
        Plots.plot!(c, title = title, label = labels[ix]; kwargs...)
    end
    Plots.display(p)
    return p
end
