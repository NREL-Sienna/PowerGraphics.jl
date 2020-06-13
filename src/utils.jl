function plot_dataframe(time, df, title; kwargs...)
    labels = DataFrames.names(df)
    p = Plots.plot()
    for (ix, c) in enumerate(DataFrames.eachcol(df))
        Plots.plot!(time[!,1], c, title = title, label = labels[ix]; kwargs...)
    end
    Plots.display(p)
    return p
end
