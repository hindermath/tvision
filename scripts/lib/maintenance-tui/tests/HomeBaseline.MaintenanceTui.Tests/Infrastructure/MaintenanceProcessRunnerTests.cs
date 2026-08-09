using HomeBaseline.MaintenanceTui.Infrastructure;
using System.Text.Json;

namespace HomeBaseline.MaintenanceTui.Tests.Infrastructure;

[TestClass]
public sealed class MaintenanceProcessRunnerTests
{
    [TestMethod]
    public async Task DeterministicFinalReportIsLoadedWithoutCompletionEvent()
    {
        using var fixture = new ReportFixture();
        fixture.WriteReport(fixture.RunId, finalized: true);

        var result = await fixture.RunAsync();

        Assert.AreEqual(0, result.ExitCode);
        Assert.IsNotNull(result.Report);
        Assert.AreEqual(fixture.RunId, result.Report.RunId);
        Assert.AreEqual("PASSED", result.Report.OverallStatus);
        Assert.IsNull(result.CompletionEvent);
    }

    [TestMethod]
    public async Task UnfinishedReportIsRejected()
    {
        using var fixture = new ReportFixture();
        fixture.WriteReport(fixture.RunId, finalized: false);

        var result = await fixture.RunAsync();

        Assert.IsNotNull(result.Report);
        Assert.IsFalse(result.Report.Finalized);
        var reconciled = new RunResultReconciler().Reconcile(
            fixture.RunId,
            result.ExitCode,
            result.Report,
            result.CompletionEvent);
        Assert.AreEqual("RESULT_MISMATCH", reconciled.DisplayStatus);
        StringAssert.Contains(reconciled.MismatchReasons[0], "nicht finalisiert");
    }

    [TestMethod]
    public async Task ForeignRunReportIsRejected()
    {
        using var fixture = new ReportFixture();
        fixture.WriteReport(Guid.NewGuid(), finalized: true);

        var result = await fixture.RunAsync();

        Assert.IsNull(result.Report);
    }

    [TestMethod]
    public async Task MalformedReportIsRejected()
    {
        using var fixture = new ReportFixture();
        File.WriteAllText(fixture.ReportPath, "{not-json");

        var result = await fixture.RunAsync();

        Assert.IsNull(result.Report);
    }

    [TestMethod]
    public async Task MissingReportIsRejected()
    {
        using var fixture = new ReportFixture();

        var result = await fixture.RunAsync();

        Assert.IsNull(result.Report);
    }

    private sealed class ReportFixture : IDisposable
    {
        private readonly string _directory = Path.Combine(
            Path.GetTempPath(),
            $"home-baseline-tui-{Guid.NewGuid():N}");

        public ReportFixture()
        {
            Directory.CreateDirectory(_directory);
            ReportPath = Path.Combine(_directory, "report.json");
            EventPath = Path.Combine(_directory, "events.jsonl");
        }

        public Guid RunId { get; } = Guid.NewGuid();

        public string ReportPath { get; }

        private string EventPath { get; }

        public void WriteReport(Guid runId, bool finalized)
        {
            File.WriteAllText(
                ReportPath,
                JsonSerializer.Serialize(
                    new
                    {
                        runId,
                        finalized,
                        overallStatus = "PASSED",
                        exitCode = 0,
                        artifacts = new { logPath = Path.Combine(_directory, "run.log") },
                    }));
        }

        public Task<ProcessExecutionResult> RunAsync()
        {
            var invocation = new ProcessInvocation(
                "dotnet",
                ["--version"],
                "dotnet --version",
                EventPath,
                ReportPath,
                RunId);
            return new MaintenanceProcessRunner().RunAsync(invocation, CancellationToken.None);
        }

        public void Dispose()
        {
            Directory.Delete(_directory, recursive: true);
        }
    }
}
