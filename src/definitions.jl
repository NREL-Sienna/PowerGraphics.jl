
# Color Definitions
PALETTE_FILE = joinpath(
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

function get_palette(file = nothing)
    file = isnothing(file) ? PALETTE_FILE : file
    palette_config = YAML.load_file(file)
    palette_colors = []
    for (k, v) in palette_config
        push!(palette_colors, PaletteColor(k, v["RGB"], v["order"]))
    end
    sort!(palette_colors, by = x -> x.order)
    return palette_colors
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

GR_DEFAULT = getfield.(get_default_palette(), :color)'
FUEL_DEFAULT = getfield.(get_palette(), :color)
PLOTLY_DEFAULT = getfield.(get_default_palette(), :RGB)
PLOTLY_FUEL_DEFAULT = getfield.(get_palette(), :RGB)
CATEGORY_DEFAULT = getfield.(get_palette(), :category)

VARIABLE_TYPES = ["P", "Spin", "Reg", "Flex"]

SUPPORTEDGENPARAMS = [
    "RenewableDispatch",
    "RenewableFix",
    "HydroDispatch",
    "HydroEnergyReservoir",
    "ThermalStandard",
]

SUPPORTEDLOADPARAMS = ["PowerLoad"]

SUPPORTEDSERVICEPARAMS = [
    "VariableReserve_ReserveUp",
    "VariableReserve_ReserveDown",
    "StaticReserve_ReserveUp",
    "StaticReserve_ReserveDown",
]

UP_RESERVES = ["VariableReserve_ReserveUp", "StaticReserve_ReserveUp"]

DOWN_RESERVES = ["VariableReserve_ReserveDown", "StaticReserve_ReserveDown"]

OVERGENERATION_VARIABLE = :γ⁻__P
UNSERVEDENERGY_VARIABLE = :γ⁺__P

GENERATOR_MAPPING_FILE = joinpath(
    dirname(dirname(pathof(PowerGraphics))),
    "report_templates",
    "generator_mapping.yaml",
)

function match_fuel_colors(
    stack::StackedGeneration,
    bar::BarGeneration,
    backend::Any,
    default::Array,
)
    if backend == Plots.PlotlyJSBackend()
        color_range = PLOTLY_FUEL_DEFAULT
    else
        color_range = FUEL_DEFAULT
    end
    color_fuel = DataFrames.DataFrame(fuels = CATEGORY_DEFAULT, colors = color_range)
    default =
        [(color_fuel[findall(in(["$(bar.labels[1])"]), color_fuel.fuels), :][:, :colors])[1]]
    for i in 2:length(bar.labels)
        specific_color =
            (color_fuel[findall(in(["$(bar.labels[i])"]), color_fuel.fuels), :][
                :,
                :colors,
            ])[1]
        default = hcat(default, specific_color)
    end
    return default
end
