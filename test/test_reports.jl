file_path = TEST_OUTPUTS

function test_reports(file_path::String; backend_pkg::String = "gr")
    if backend_pkg == "gr"
        backend = Plots.gr()
    elseif backend_pkg == "plotlyjs"
        backend = Plots.plotlyjs()
    else
        throw(error("$backend_pkg backend_pkg not supported"))
    end

    @testset "testing $backend_pkg report production" begin
        path = joinpath(file_path, backend_pkg * "_reports")
        !isdir(path) && mkpath(path)
        report_path = joinpath(path, "test_report.html")
        PG.report(results_uc, report_path, generic_template; doctype = "md2html", backend = backend)
        @test isfile(joinpath(path, "generic_report_template.html")) # report_path) not sure why weave doesn't output the report name

        @info("removing test files")
        rm(path, recursive = true)
    end
end

try
    test_reports(file_path, backend_pkg = "gr")
    test_reports(file_path, backend_pkg = "plotlyjs")
finally
    nothing
end
