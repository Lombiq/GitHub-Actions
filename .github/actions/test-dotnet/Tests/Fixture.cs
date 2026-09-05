using System;
using Xunit;

namespace TestDotnet;

public class ActionFixture(ITestOutputHelper output)
{
    [Fact]
    public void PassingTest() => output.WriteLine("Passing test output is preserved.");

    [Theory]
    [InlineData("spaces & punctuation")]
    [InlineData("second case")]
    public void TheoryTest(string value) => Assert.NotEmpty(value);

    [Fact]
    public void ControlledFailure()
    {
        // A success-looking log line must not override the process exit code.
        output.WriteLine("Test Run Successful.");
        Assert.NotEqual("true", Environment.GetEnvironmentVariable("LGHA_TEST_FAILURE"));
    }
}
