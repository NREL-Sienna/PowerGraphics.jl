using Test
using TestSetExtensions
using Logging
using Dates
using DataFrames
import InfrastructureSystems
import InfrastructureSystems: Deterministic, Probabilistic, ScenarioBased, Forecast
using PowerSystems
using PowerGraphics
using PlotlyJS
using PowerSimulations
using GLPK
using Weave

const PG = PowerGraphics
const IS = InfrastructureSystems
const PSY = PowerSystems
const PSI = PowerSimulations
const LOG_FILE = "PowerGraphics-test.log"

base_dir = dirname(dirname(pathof(PowerGraphics)))
template_dir = joinpath(base_dir, "report_templates")
const generic_template = joinpath(template_dir, "generic_report_template.jmd")
const fuel_template = joinpath(template_dir, "fuel_report_template.jmd")

LOG_LEVELS = Dict(
    "Debug" => Logging.Debug,
    "Info" => Logging.Info,
    "Warn" => Logging.Warn,
    "Error" => Logging.Error,
)

macro includetests(testarg...)
    if length(testarg) == 0
        tests = []
    elseif length(testarg) == 1
        tests = testarg[1]
    else
        error("@includetests takes zero or one argument")
    end

    quote
        tests = $tests
        rootfile = @__FILE__
        if length(tests) == 0
            tests = readdir(dirname(rootfile))
            tests = filter(
                f ->
                    startswith(f, "test_") && endswith(f, ".jl") && f != basename(rootfile),
                tests,
            )
        else
            tests = map(f -> string(f, ".jl"), tests)
        end
        println()
        for test in tests
            print(splitext(test)[1], ": ")
            include(test)
            println()
        end
    end
end

function get_logging_level(env_name::String, default)
    level = get(ENV, env_name, default)
    log_level = get(LOG_LEVELS, level, nothing)
    if log_level == nothing
        error("Invalid log level $level: Supported levels: $(values(LOG_LEVELS))")
    end

    return log_level
end

function run_tests()
    include("get_test_data.jl")
    console_level = get_logging_level("PS_CONSOLE_LOG_LEVEL", "Error")
    console_logger = ConsoleLogger(stderr, console_level)
    file_level = get_logging_level("PS_LOG_LEVEL", "Info")

    IS.open_file_logger(LOG_FILE, file_level) do file_logger
        levels = (Logging.Info, Logging.Warn, Logging.Error)
        multi_logger =
            IS.MultiLogger([console_logger, file_logger], IS.LogEventTracker(levels))
        global_logger(multi_logger)

        # Testing Topological components of the schema
        @time @testset "Begin PowerGraphics tests" begin
            @includetests ARGS
        end

        # TODO: once all known error logs are fixed, add this test:
        #@test length(get_log_events(multi_logger.tracker, Logging.Error)) == 0

        @info IS.report_log_summary(multi_logger)
    end
end

logger = global_logger()

try
    run_tests()
finally
    # Guarantee that the global logger is reset.
    global_logger(logger)
    nothing
end
