using Documenter, PowerGraphics

makedocs(
    modules = [PowerGraphics],
    format = Documenter.HTML(),
    sitename = "PowerGraphics.jl",
    authors = "Clayton Barrows",
    pages = [
        "Home" => "index.md",
        "Examples" => "examples.md", # TODO: make examples page
        "Function Index" => "api.md",
    ],
)

Documenter.deploydocs(
    repo = "github.com/NREL-SIIP/PowerGraphics.jl.git",
    target = "build",
    branch = "gh-pages",
    devbranch = "master",
    devurl = "dev",
    push_preview = true,
    versions = ["stable" => "v^", "v#.#"],
)
