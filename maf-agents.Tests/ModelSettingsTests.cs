using maf_agents;

namespace maf_agents.Tests;

public class ModelSettingsTests
{
    [Theory]
    [InlineData(null, "test-deployment")]
    [InlineData(" ", "test-deployment")]
    [InlineData("https://example.openai.azure.com", null)]
    [InlineData("https://example.openai.azure.com", " ")]
    public void GivenMissingSetting_WhenCreatingSettings_ThrowsActionableError(
        string? endpoint, string? deployment)
    {
        var exception = Assert.Throws<InvalidOperationException>(
            () => new ModelSettings(endpoint, deployment));

        Assert.Contains("AZURE_OPENAI_", exception.Message);
        Assert.DoesNotContain("AZURE_OPENAI_API_KEY", exception.Message);
    }

    [Theory]
    [InlineData("not-a-url")]
    [InlineData("http://example.openai.azure.com")]
    [InlineData("https://example.services.ai.azure.com/api/projects/test")]
    [InlineData("https://example.openai.azure.com/openai/v1")]
    [InlineData("https://example.openai.azure.com/?secret=value")]
    [InlineData("https://user:password@example.openai.azure.com")]
    public void GivenInvalidEndpoint_WhenCreatingSettings_ThrowsWithoutEchoingInput(string endpoint)
    {
        var exception = Assert.Throws<InvalidOperationException>(
            () => new ModelSettings(endpoint, "test-deployment"));

        Assert.Contains("HTTPS resource root", exception.Message);
        Assert.DoesNotContain(endpoint, exception.Message);
    }

    [Theory]
    [InlineData("https://example.openai.azure.com")]
    [InlineData("https://example.services.ai.azure.com/")]
    public void GivenResourceRoot_WhenCreatingSettings_AppendsV1EndpointWithoutApiKey(string endpoint)
    {
        var settings = new ModelSettings($" {endpoint} ", " test-deployment ");

        Assert.Equal($"{endpoint.TrimEnd('/')}/openai/v1/", settings.ApiEndpoint.AbsoluteUri);
        Assert.Equal("test-deployment", settings.DeploymentName);
    }
}
