"""
    report(res::IS.Results, out_path::String, design_template::String)

This function uses weave to either generate a LaTeX or HTML
file based on the report_design.jmd (julia markdown) file
that it reads. Out_path in the weave function dictates
where the created file gets exported.

# Arguments
- `results::IS.Results`: The results to be plotted
- `out_path::String`: folder path to the location the report should be generated
- `design_template::String = "file_path"`: directs the function to the julia markdown report design, the default

# Example
```julia
results = solve_op_problem!(OpModel)
out_path = "/Users/downloads"
report(results, out_path, template)
```

# Accepted Key Words
- `doctype::String = "md2html"`: create an HTML, default is PDF via latex
- `backend::Plots.backend() = plotlyjs()`: sets the plots backend, default is gr()
"""
function report(res::IS.Results, out_path::String, design_template::String; kwargs...)
    doctype = get(kwargs, :doctype, "md2pdf")
    backend = get(kwargs, :backend, Plots.gr())
    initial_time = get(kwargs, :initial_time, nothing)
    len = get(kwargs, :horizon, nothing)

    !isfile(design_template) &&
        throw(ArgumentError("The provided template file is invalid"))
    args = Dict(
        "res" => res,
        "gen" => res.system,
        "variables" =>
            PSI.read_realized_variables(res; initial_time = initial_time, len = len),
        "backend" => backend,
    )
    Weave.weave(
        design_template,
        out_path = out_path,
        latex_cmd = ["xelatex"],
        doctype = doctype,
        args = args,
    )
end
