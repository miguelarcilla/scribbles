using System.ClientModel;
using System.ClientModel.Primitives;
using Azure.Identity;
using DotNetEnv;
using maf_agents;
using Microsoft.Extensions.AI;
using OpenAI;

if (args is ["--help"])
{
    Console.WriteLine("Usage: dotnet run --project .\\maf-agents [-- \"Your trip-planning request\"]");
    Console.WriteLine("Without a request, the agent plans a seven-day Japan trip.");
    return 0;
}

using var cancellation = new CancellationTokenSource(TimeSpan.FromMinutes(3));
var interrupted = false;
Console.CancelKeyPress += (_, eventArgs) =>
{
    eventArgs.Cancel = true;
    interrupted = true;
    cancellation.Cancel();
};

try
{
    var envPath = File.Exists(".env") ? ".env" : Path.Combine("maf-agents", ".env");
    if (File.Exists(envPath))
    {
        Env.NoClobber().Load(envPath);
    }

    var settings = new ModelSettings(
        Environment.GetEnvironmentVariable("AZURE_OPENAI_ENDPOINT"),
        Environment.GetEnvironmentVariable("AZURE_OPENAI_DEPLOYMENT_NAME"));

#pragma warning disable OPENAI001 // The OpenAI SDK currently marks its Entra authentication constructor as experimental.
    using var chatClient = new OpenAIClient(
        new BearerTokenPolicy(new DefaultAzureCredential(), "https://cognitiveservices.azure.com/.default"),
        new OpenAIClientOptions { Endpoint = settings.ApiEndpoint })
        .GetChatClient(settings.DeploymentName)
        .AsIChatClient();
#pragma warning restore OPENAI001

    var agent = JapanTripAgent.Create(chatClient);
    var session = await agent.CreateSessionAsync(cancellationToken: cancellation.Token);
    var task = args.Length == 0 ? JapanTripAgent.DefaultTask : string.Join(" ", args);
    if (string.IsNullOrWhiteSpace(task))
    {
        Console.Error.WriteLine("The trip-planning request cannot be empty.");
        return 1;
    }

    Console.WriteLine($"Task: {task}");
    Console.WriteLine("Planning with JapanTripPlanner (Ctrl+C to cancel)...");
    var response = await agent.RunAsync(task, session, cancellationToken: cancellation.Token);
    if (string.IsNullOrWhiteSpace(response.Text))
    {
        Console.Error.WriteLine("The model returned no itinerary. Check that the deployment supports chat and function calling.");
        return 1;
    }

    Console.WriteLine();
    Console.WriteLine(response.Text);
    return 0;
}
catch (AuthenticationFailedException)
{
    Console.Error.WriteLine(
        "Microsoft Entra authentication failed. Run 'az login' with an account in the resource's tenant, or configure a managed identity. The identity needs the Cognitive Services OpenAI User role on the resource.");
    return 1;
}
catch (InvalidOperationException exception)
{
    Console.Error.WriteLine(exception.Message);
    return 1;
}
catch (ClientResultException exception)
{
    Console.Error.WriteLine(
        $"Model request failed (HTTP {exception.Status}). Check the endpoint, deployment name, and model's function-calling support. For HTTP 401/403, check your Entra identity's tenant and Cognitive Services OpenAI User role on the resource.");
    return 1;
}
catch (HttpRequestException)
{
    Console.Error.WriteLine("Cannot reach the model endpoint. Check your network connection and AZURE_OPENAI_ENDPOINT.");
    return 1;
}
catch (OperationCanceledException) when (cancellation.IsCancellationRequested)
{
    Console.Error.WriteLine(interrupted ? "Agent run cancelled." : "Agent run exceeded the three-minute limit.");
    return interrupted ? 130 : 1;
}