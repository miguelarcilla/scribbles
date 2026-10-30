namespace maf_agents;

internal sealed class ModelSettings
{
    internal ModelSettings(string? endpoint, string? deploymentName)
    {
        if (string.IsNullOrWhiteSpace(endpoint)
            || string.IsNullOrWhiteSpace(deploymentName))
        {
            throw new InvalidOperationException(
                "Set AZURE_OPENAI_ENDPOINT and AZURE_OPENAI_DEPLOYMENT_NAME in maf-agents\\.env or your environment.");
        }

        if (!Uri.TryCreate(endpoint.Trim(), UriKind.Absolute, out var resourceEndpoint)
            || resourceEndpoint.Scheme != Uri.UriSchemeHttps
            || resourceEndpoint.AbsolutePath != "/"
            || resourceEndpoint.Query.Length != 0
            || resourceEndpoint.Fragment.Length != 0
            || resourceEndpoint.UserInfo.Length != 0)
        {
            throw new InvalidOperationException(
                "AZURE_OPENAI_ENDPOINT must be an HTTPS resource root, for example https://your-resource.openai.azure.com (not a project or deployment URL).");
        }

        ApiEndpoint = new Uri(resourceEndpoint, "openai/v1/");
        DeploymentName = deploymentName.Trim();
    }

    internal Uri ApiEndpoint { get; }

    internal string DeploymentName { get; }
}
