
# Color Definitions
PALETTE_FILE = joinpath(dirname(dirname(pathof(PowerGraphics))), "report_templates", "color-palette.yaml")

struct PaletteColor
    category::AbstractString
    RGB::AbstractString
    color::RGBA{Float64}
    order::Int64
end

function PaletteColor(category::String, RGB::String, order::Int64)
    rgba = parse.(Int64, strip.(split(strip(RGB, ['r', 'b', 'g', 'a', '(', ')', ' ']), ",")))
    color = Colors.RGBA(rgba[1]/288, rgba[2]/288, rgba[3]/288, rgba[4])
    return PaletteColor(category, RGB, color, order)
end

function get_palette(file = nothing)
    file = isnothing(file) ? PALETTE_FILE : file
    palette_config = YAML.load_file(file)
    palette_colors =  []
    for (k,v) in palette_config
        push!(palette_colors, PaletteColor(k, v["RGB"], v["order"]))
    end
    sort!(palette_colors,  by=x->x.order)
    return palette_colors
end
#=
# to define or change the RGB based on a 288 scale, divide by 288 for each rgb and set A = 1
NUCLEAR = Colors.RGBA(0.5098, 0.000, 0.000, 1)
COAL = Colors.RGBA(0.1333, 0.1333, 0.1333, 1)
HYDRO = Colors.RGBA(0.0941, 0.498, 0.580, 1)
GAS_CC = Colors.RGBA(0.322, 0.522, 0.420, 1)
GAS_CT = Colors.RGBA(0.761, 0.631, 0.859, 1)
STORAGE = Colors.RGBA(1, 0.290, 0.533, 1)
OIL_ST = Colors.RGBA(0.522, 0.239, 0.396, 1) # petroleum
OIL_CT = Colors.RGBA(0.522, 0.239, 0.396, 1) # petroleum
SYNC_COND = Colors.RGBA(0.522, 0.239, 0.396, 1) # petroleum
WIND = Colors.RGBA(0.000, 0.714, 0.937, 1)
SOLAR = Colors.RGBA(1, 0.788, 0.012, 1)
CSP = Colors.RGBA(0.989, 0.463, 0.102, 1)
CURTAILMENT = Colors.RGBA(0.357, 0.384, 0.447, 1)

# Out of a 288 rgba scale
NUCLEAR_288 = "rgba(130, 0, 0, 1)"
COAL_288 = "rgba(34, 34, 34, 1)"
HYDRO_288 = "rgba(24, 127, 148, 1)"
GAS_CC_288 = "rgba(82, 133, 107, 1)"
GAS_CT_288 = "rgba(194, 161, 219, 1)"
GAS_ST_288 = "rgba(61, 51, 118, 1)"
GAS_288 = "rgba(82, 33, 107, 1)"
STORAGE_288 = "rgba(255, 74, 136, 1)"
OIL_ST_288 = "rgba(133, 61, 101, 1)" # petroleum
OIL_CT_288 = "rgba(133, 61, 101, 1)" # petroleum
SYNC_COND_288 = "rgba(133, 61, 101, 1)" # petroleum
WIND_288 = "rgba(0, 182, 239, 1)"
SOLAR_288 = "rgba(255, 201, 3, 1)"
CSP_288 = "rgba(252, 118, 26, 1)"
CURTAILMENT_288 = "rgba(91, 98, 114, 1)"
=#

GR_DEFAULT = getfield.(get_palette(), :color)'
#=hcat(
    NUCLEAR,
    COAL,
    HYDRO,
    GAS_CC,
    GAS_CT,
    STORAGE,
    OIL_ST,
    OIL_CT,
    SYNC_COND,
    WIND,
    SOLAR,
    CSP,
    CURTAILMENT,
)=#

FUEL_DEFAULT = getfield.(get_palette(), :color)
#=vcat(
    NUCLEAR,
    COAL,
    HYDRO,
    GAS_CC,
    GAS_CT,
    STORAGE,
    OIL_ST,
    OIL_CT,
    SYNC_COND,
    WIND,
    SOLAR,
    CSP,
    CURTAILMENT,
)
=#
PLOTLY_DEFAULT = getfield.(get_palette(), :RGB)
CATEGORY_DEFAULT = getfield.(get_palette(), :category)

#=vcat(
    NUCLEAR_288,
    COAL_288,
    HYDRO_288,
    GAS_CC_288,
    GAS_CT_288,
    STORAGE_288,
    OIL_ST_288,
    OIL_CT_288,
    SYNC_COND_288,
    WIND_288,
    SOLAR_288,
    CSP_288,
    CURTAILMENT_288,
)
=#
VARIABLE_TYPES = ["P", "Spin", "Reg", "Flex"]

GENERATOR_MAPPING_FILE = joinpath(dirname(dirname(pathof(PowerGraphics))), "report_templates", "generator_mapping.yaml")

function match_fuel_colors(
    stack::StackedGeneration,
    bar::BarGeneration,
    backend::Any,
    default::Array,
)
    if backend == Plots.PlotlyJSBackend()
        color_range = PLOTLY_DEFAULT
    else
        color_range = FUEL_DEFAULT
    end
    fuels = CATEGORY_DEFAULT
    #=[
        "Nuclear",
        "Coal",
        "Hydro",
        "Gas_CC",
        "Gas_CT",
        "Storage",
        "Oil_ST",
        "Oil_CT",
        "Sync_Cond",
        "Wind",
        "Solar",
        "CSP",
        "curtailment",
    ]=#
    color_fuel = DataFrames.DataFrame(fuels = fuels, colors = color_range)
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
