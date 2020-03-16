path = joinpath(pwd(), "plots")
!isdir(path) && mkdir(path)

function test_reports(file_path::String)
    include("test_data.jl")
    @testset "testing report production" begin
        report_path = joinpath(dirname(file_path), "test_report.pdf")
        PG.report(res, report_path, generic_template)
        @test isfile(report_path)
    end
end

try
    test_reports(path)
finally
    @info("removing test files")
    rm(path, recursive = true)
end
