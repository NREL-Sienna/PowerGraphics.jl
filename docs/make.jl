using Documenter
import DataStructures: OrderedDict
using PowerGraphics

pages = OrderedDict(
    "Welcome" => "index.md",
    ## TODO add additional pages here in the future and remove stubs
    "Tutorials" => Any[ "Examples" => "tutorials/examples.md"], # TODO: make examples page
    # "How to..." => Any["stub" => "how_to_guides/stub.md"],
    # "Explanation" => Any["stub" => "explanation/stub.md"],
    "Reference" => Any[ 
        "Public API" => "reference/public.md",
        "Developers" => ["Developer Guidelines" => "reference/developer_guidelines.md",
        "Internals" => "reference/internal.md"],
    ],
)


makedocs(;
    modules = [PowerGraphics],
    format = Documenter.HTML(
        prettyurls = haskey(ENV, "GITHUB_ACTIONS"),),
    sitename = "PowerGraphics.jl",
    authors = "Clayton Barrows",
    pages = Any[p for p in pages],
    draft = false,
)

Documenter.deploydocs(;
    repo = "github.com/NREL-Sienna/PowerGraphics.jl.git",
    target = "build",
    branch = "gh-pages",
    devbranch = "main",
    devurl = "dev",
    push_preview = true,
    versions = ["stable" => "v^", "v#.#"],
)
