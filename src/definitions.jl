
# Color Definitions
DEFAULT_PALETTE_FILE = joinpath(
    dirname(dirname(pathof(PowerGraphics))),
    "report_templates",
    "color-palette.yaml",
)

struct PaletteColor
    category::AbstractString
    RGB::AbstractString
    color::RGBA{Float64}
    order::Int64
end

function PaletteColor(category::String, RGB::String, order::Int64)
    rgba =
        parse.(Int64, strip.(split(strip(RGB, ['r', 'g', 'b', 'a', '(', ')', ' ']), ",")))
    color = Colors.RGBA(rgba[1] / 288, rgba[2] / 288, rgba[3] / 288, rgba[4])
    return PaletteColor(category, RGB, color, order)
end

function load_palette()
    if haskey(ENV, "PG_PALETTE")
        load_palette(ENV["PG_PALETTE"])
    else
        load_palette(DEFAULT_PALETTE_FILE)
    end
end

function load_palette(file)
    palette_config = YAML.load_file(file)
    palette_colors = []
    for (k, v) in palette_config
        push!(palette_colors, PaletteColor(k, v["RGB"], v["order"]))
    end
    sort!(palette_colors, by = x -> x.order)
    return palette_colors
end

_palette = load_palette()

function get_palette()
    global _palette
    return _palette
end

function with_palette(f, palette_file::AbstractString)
    with_palette(f, load_palette(palette_file))
end

function with_palette(f, palette_colors)
    global _palette
    old = _palette
    try
        _palette = palette_colors
        f()
    finally
        _palette = old
    end
end

function get_default_palette()
    default_palette = []
    palette = get_palette()
    default_order = [6, 52, 14, 1, 32, 7, 18, 20, 27, 53, 17] # the default order from the color palette #
    for i in default_order
        for p in palette
            if p.order == i
                push!(default_palette, p)
            end
        end
    end
    return default_palette
end

# Recursively find all subtypes: useful for categorizing variables
function all_subtypes(t::Type)
    st = [t]
    for t in st
        union!(st, InteractiveUtils.subtypes(t))
    end
    return [split(string(s), ".")[end] for s in st]
end

function get_palette_gr()
    permutedims(getfield.(get_palette(), :color))
end

function get_palette_fuel()
    getfield.(get_palette(), :color)
end

function get_palette_plotly()
    getfield.(get_default_palette(), :RGB)
end

function get_palette_plotly_fuel()
    getfield.(get_palette(), :RGB)
end

function get_palette_category()
    getfield.(get_palette(), :category)
end

function get_default_seriescolor()
    backend = Plots.backend()
    return get_default_seriescolor(backend)
end

function get_default_seriescolor(backend)
    return get_palette_gr()
end

function get_default_seriescolor(backend::Plots.PlotlyJSBackend)
    return get_palette_plotly()
end

SUPPORTED_EXTRA_PLOT_KWARGS = [:linestyle, :linewidth]
SUPPORTED_PLOTLY_SAVE_KWARGS =
    [:autoplay, :post_script, :full_html, :animation_opts, :default_width, :default_height]

function match_fuel_colors(data::DataFrames.DataFrame, backend)
    if backend == Plots.PlotlyJSBackend()
        color_range = get_palette_plotly_fuel()
    else
        color_range = get_palette_fuel()
    end
    color_fuel = DataFrames.DataFrame(fuels = get_palette_category(), colors = color_range)
    names = DataFrames.names(data)
    default =
        [(color_fuel[findall(in(["$(names[1])"]), color_fuel.fuels), :][:, :colors])[1]]
    for i in 2:length(names)
        @debug names[i] (color_fuel[findall(in(["$(names[i])"]), color_fuel.fuels), :][
            :,
            :colors,
        ])
        specific_color =
            (color_fuel[findall(in(["$(names[i])"]), color_fuel.fuels), :][:, :colors])[1]
        default = hcat(default, specific_color)
    end
    return default
end
