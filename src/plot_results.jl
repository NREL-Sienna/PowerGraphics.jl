mutable struct Results <: IS.Results
    base_power::Float64
    variable_values::Dict{Symbol, DataFrames.DataFrame}
    total_cost::Dict
    optimizer_log::Dict
    time_stamp::DataFrames.DataFrame
    dual_values::Dict{Symbol, Any}
    parameter_values::Dict{Symbol, DataFrames.DataFrame}
end

IS.get_variables(r::Results) = r.variable_values
IS.get_total_cost(r::Results) = r.total_cost
IS.get_optimizer_log(r::Results) = r.optimizer_log
IS.get_time_stamp(r::Results) = r.time_stamp
IS.get_base_power(r::Results) = r.base_power
IS.get_parameters(r::Results) = r.parameter_values

struct StackedArea
    time_range::Array
    data_matrix::Matrix
    labels::Array
end

struct BarPlot
    time_range::Array
    bar_data::Matrix
    labels::Array
end

struct StackedGeneration
    time_range::Array
    data_matrix::Matrix
    parameters::Union{Matrix, Nothing}
    labels::Array
    p_labels::Array
end

struct BarGeneration
    time_range::Array
    bar_data::Matrix
    parameters::Union{Matrix, Nothing}
    labels::Array
    p_labels::Array
end
#=
"""
    variable = get_stacked_plot_data(res::IS.Results, variable::String)

This function takes in results and uses a dataframe from whichever variable name was given and converts it to type StackedArea.
StackedArea is the type of struct that signals the plot() function to use the StackedArea plot recipe method.

# Arguments
- `res::IS.Results`: results
- `variable::String`: the variable to be plotted

#Example
```julia
ThermalStandard = get_stacked_plot_data(res, "P_ThermalStandard")
plot(ThermalStandard)

"""

function get_stacked_plot_data(res::IS.Results, variable::String; kwargs...)

    time_range = IS.get_time_stamp(res)[!, :Range]
    variable = IS.get_variables(res)[Symbol(variable)]
    data_matrix = convert(Matrix, variable)
    labels = collect(names(variable))
    legend = [string.(names(variable)[1])]
    for name in 2:length(labels)
        legend = hcat(legend, string.(labels[name]))
    end

    return StackedArea(time_range, data_matrix, legend)

end

"""
    variable = get_bar_plot_data(res::IS.Results, variable::String)

This function takes in results and uses a dataframe from whichever variable name was given and converts it to type BarPlot.
StackedGeneration is the type of struct that signals the plot() function to use the StackedGeneration plot recipe method.

# Arguments
- `res::IS.Results`: results
- `variable::String`: the variable to be plotted

#Example
```julia
ThermalStandard = get_bar_plot_data(res, "P_ThermalStandard")
plot(ThermalStandard)
```

# Accepted Key Words
- `sort::Array`: the array of generators to be plotted, in the order to be plotted
"""

function get_bar_plot_data(res::IS.Results, variable::String; kwargs...)

    time_range = IS.get_time_stamp(res)[!, :Range]
    variable = IS.get_variables(res)[Symbol(variable)]
    alphabetical = sort!(names(variable))
    data = convert(Matrix, variable)
    bar_data = sum(data, dims = 1)
    labels = collect(names(variable))
    legend = [string.(names(variable)[1])]
    for name in 2:length(labels)
        legend = hcat(legend, string.(labels[name]))
    end

    return BarPlot(time_range, bar_data, legend)
end

"""
    variable = get_stacked_gen_data(res::IS.Results)

This function takes in results and stacks the variables given.
StackedGeneration is the type of struct that signals the plot() function to use the StackedGeneration plot recipe method.

# Arguments
- `res::IS.Results`: results

#Example
```julia
stack = get_stacked_gen_data(res)
plot(stack)
```

# Accepted Key Words
- `sort::Array`: the array of generators to be plotted, in the order to be plotted
"""

function get_stacked_generation_data(res::IS.Results; kwargs...)

    time_range = IS.get_time_stamp(res)[!, :Range]
    labels = collect(keys(IS.get_variables(res)))
    variable = IS.get_variables(res)[Symbol(labels[1])]
    data_matrix = sum(convert(Matrix, variable), dims = 2)
    legend = [string.(labels[1])]

    for i in 2:length(labels)
        variable = IS.get_variables(res)[Symbol(labels[i])]
        legend = hcat(legend, string.(labels[i]))
        data_matrix = hcat(data_matrix, sum(convert(Matrix, variable), dims = 2))
    end
    p_labels = collect(keys(res.parameter_values))
    if !isempty(p_labels)
        parameter = res.parameter_values[Symbol(p_labels[1])]
        parameters = abs.(sum(convert(Matrix, parameter), dims = 2))
        p_legend = [string.(p_labels[1])]

        for i in 1:length(p_labels)
            if i !== 1
                parameter = res.parameter_values[Symbol(p_labels[i])]
                p_legend = hcat(p_legend, string.(p_labels[i]))
                parameters = hcat(parameters, abs.(sum(convert(Matrix, parameter), dims = 2)))
            end
        end
    else
        p_legend = []
        parameters = nothing
    end

    return StackedGeneration(time_range, data_matrix, parameters, legend, p_legend)

end

"""
    variable = get_bar_gen_data(res::IS.Results)

This function takes in results and stacks the variables given.
StackedGeneration is the type of struct that signals the plot() function to use the StackedGeneration plot recipe method.

# Arguments
- `res::IS.Results`: results

#Example
```julia
stack = get_stacked_gen_data(res)
plot(stack)
```

# Accepted Key Words
- `sort::Array`: the array of generators to be plotted, in the order to be plotted
"""

function get_bar_gen_data(res::IS.Results)

    time_range = IS.get_time_stamp(res)[!, :Range]
    labels = collect(keys(IS.get_variables(res)))
    variable = IS.get_variables(res)[Symbol(labels[1])]
    data_matrix = sum(convert(Matrix, variable), dims = 2)
    legend = [string.(labels[1])]
    for i in 2:length(labels)
        variable = IS.get_variables(res)[Symbol(labels[i])]
        legend = vcat(legend, string.(labels[i]))
        data_matrix = hcat(data_matrix, sum(convert(Matrix, variable), dims = 2))
    end
    bar_data = sum(data_matrix, dims = 1)

    p_labels = collect(keys(res.parameter_values))
    if !isempty(p_labels)
        parameter = res.parameter_values[p_labels[1]]
        parameters = sum(convert(Matrix, parameter), dims = 2)
        p_legend = [string.(p_labels[1])]
        for i in 2:length(p_labels)
            parameter = res.parameter_values[Symbol(p_labels[i])]
            p_legend = vcat(p_legend, string.(p_labels[i]))
            parameters = hcat(parameters, sum(convert(Matrix, parameter), dims = 2))
        end
        p_bar_data = abs.(sum(parameters, dims = 1))
    else
        p_bar_data = nothing
        p_legend = []
    end
    return BarGeneration(time_range, bar_data, p_bar_data, legend, p_legend)

end
=#
"""
    sort_data(results::IS.Results)

This function takes in struct Results, sorts the generators in each variable, and outputs the sorted
results. The generic function sorts the generators alphabetically.

# Arguments
- `results::Results`: the results of the simulation

# Key Words
- `Variables::Dict{Symbol, Array{Symbol}`: the desired variables and their generator order

#Examples
```julia
Variables = Dict(:ON_ThermalStandard => [:Brighton, :Solitude])
sorted_results = sort_data(res_UC; Variables = Variables)
```
***Note:*** only the generators included in key word 'Variables' will be in the
results, and consequently, only these will be plotted.
"""
function sort_data(res::IS.Results; kwargs...)
    order = get(kwargs, :Variables, Dict())
    if !isempty(order)
        labels = collect(keys(order))
    else
        labels = sort!(collect(keys(IS.get_variables(res))))
    end
    sorted_variables = Dict()
    for label in labels
        sorted_variables[label] = IS.get_variables(res)[label]
    end
    for (k, variable) in sorted_variables
        if !isempty(order)
            variable = variable[:, order[k]]
        else
            alphabetical = sort!(names(variable))
            variable = variable[:, alphabetical]
        end
        sorted_variables[k] = variable
    end
    return Results(
        IS.get_base_power(res),
        sorted_variables,
        IS.get_optimizer_log(res),
        IS.get_total_cost(res),
        IS.get_time_stamp(res),
        res.dual_values,
        res.parameter_values,
    )
end

function plot_variable(res::IS.Results, variable_name::Symbol; kwargs...)
    return plot_dataframe(res.variable_values[variable_name], variable_name; kwargs...)
end
