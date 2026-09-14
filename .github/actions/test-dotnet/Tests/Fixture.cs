using System;
using Xunit;

namespace TestDotnet;

public class ActionFixture
{
    private readonly ITestOutputHelper _output;

    public ActionFixture(ITestOutputHelper output) => _output = output;

    [Fact]
    public void PassingTest() => _output.WriteLine("Passing test output is preserved.");

    [Theory]
    [InlineData("spaces & punctuation")]
    [InlineData("second case")]
    public void TheoryTest(string value) => Assert.NotEmpty(value);

    [Fact]
    public void ControlledFailure()
    {
        // A success-looking log line must not override the process exit code.
        _output.WriteLine("Test Run Successful.");
        Assert.NotEqual("true", Environment.GetEnvironmentVariable("LGHA_TEST_FAILURE"));
    }
}
