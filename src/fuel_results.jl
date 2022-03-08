order = CATEGORY_DEFAULT # TODO: move inside function

"""Return a dict where keys are a tuple of input parameters (fuel, unit_type) and values are
generator types."""
function get_generator_mapping(filename = nothing)
    if isnothing(filename)
        filename = GENERATOR_MAPPING_FILE
    end
    genmap = open(filename) do file
        YAML.load(file)
    end

    mappings = Dict{NamedTuple, String}()
    for (gen_type, vals) in genmap
        for val in vals
            pm =
                isnothing(val["primemover"]) ? nothing :
                uppercase(string(val["primemover"]))
            key = (fuel = val["fuel"], primemover = pm)
            if haskey(mappings, key)
                error(
                    "duplicate generator mappings: $gen_type $(key.fuel) $(key.primemover)",
                )
            end
            mappings[key] = gen_type
        end
    end

    return mappings
end

"""Return the generator category for this fuel and unit_type."""
function get_generator_category(fuel, primemover, mappings::Dict{NamedTuple, String})
    fuel = isnothing(fuel) ? nothing : uppercase(string(fuel))
    primemover = isnothing(primemover) ? nothing : uppercase(string(primemover))
    generator = nothing

    # Try to match the primemover if it's defined. If it's nothing then just match on fuel.
    for pm in (primemover, nothing), f in (fuel, nothing)
        key = (fuel = f, primemover = pm)
        if haskey(mappings, key)
            generator = mappings[key]
            break
        end
    end

    if isnothing(generator)
        @error "No mapping defined for generator fuel=$fuel primemover=$primemover"
    end

    return generator
end

"""
    generators = make_fuel_dictionary(system::PSY.System, mapping::Dict{NamedTuple, String})

This function makes a dictionary of fuel type and the generators associated.

# Arguments
- `sys::PSY.System`: the system that is used to create the results
- `results::IS.Results`: results

# Key Words
- `categories::Dict{String, NamedTuple}`: if stacking by a different category is desired

# Example
results = solve_op_model!(OpModel)
generators = make_fuel_dictionary(sys)

"""
function make_fuel_dictionary(sys::PSY.System, mapping::Dict{NamedTuple, String})
    generators = PSY.get_components(PSY.StaticInjection, sys, PSY.get_available)
    gen_categories = Dict()
    for category in unique(values(mapping))
        gen_categories["$category"] = []
    end
    gen_categories["Load"] = []

    for gen in generators
        if gen isa PSY.ElectricLoad
            category = "Load"
        else
            fuel = hasmethod(PSY.get_fuel, Tuple{typeof(gen)}) ? PSY.get_fuel(gen) : nothing
            pm =
                hasmethod(PSY.get_prime_mover, Tuple{typeof(gen)}) ?
                PSY.get_prime_mover(gen) : nothing
            category = get_generator_category(fuel, pm, mapping)
        end
        push!(gen_categories["$category"], (string(typeof(gen)), (PSY.get_name(gen))))
    end
    [delete!(gen_categories, "$k") for (k, v) in gen_categories if isempty(v)]
    return gen_categories
end

function make_fuel_dictionary(sys::PSY.System; kwargs...)
    mapping = get_generator_mapping(get(kwargs, :generator_mapping_file, nothing))
    return make_fuel_dictionary(sys, mapping)
end
