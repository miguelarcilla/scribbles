using maf_agents;
using Microsoft.Extensions.AI;
using NSubstitute;

namespace maf_agents.Tests;

public class JapanTripAgentTests
{
    [Fact]
    public async Task GivenDefaultTask_WhenRunningHarness_PassesTaskAndReturnsItinerary()
    {
        using var chatClient = Substitute.For<IChatClient>();
        var expected = "Day 1: Tokyo. Day 2: Kyoto. Estimated budget: JPY 300,000.";
        chatClient.GetResponseAsync(
                Arg.Any<IEnumerable<ChatMessage>>(),
                Arg.Any<ChatOptions>(),
                Arg.Any<CancellationToken>())
            .Returns(new ChatResponse(new ChatMessage(ChatRole.Assistant, expected)));

        var agent = JapanTripAgent.Create(chatClient);
        var session = await agent.CreateSessionAsync();
        var response = await agent.RunAsync(JapanTripAgent.DefaultTask, session);

        Assert.Equal(expected, response.Text);
        await chatClient.Received(1).GetResponseAsync(
            Arg.Is<IEnumerable<ChatMessage>>(messages =>
                messages.Any(message => message.Role == ChatRole.User
                    && message.Text == JapanTripAgent.DefaultTask)),
            Arg.Is<ChatOptions>(options =>
                options.Tools != null && options.Tools.Count > 0
                && options.Tools.All(tool => tool is AIFunction)),
            Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task GivenPlanningToolCall_WhenRunningHarness_InvokesToolAndContinues()
    {
        using var chatClient = Substitute.For<IChatClient>();
        var requests = 0;
        FunctionResultContent? toolResult = null;
        chatClient.GetResponseAsync(
                Arg.Any<IEnumerable<ChatMessage>>(),
                Arg.Any<ChatOptions>(),
                Arg.Any<CancellationToken>())
            .Returns(call =>
            {
                requests++;
                if (requests == 1)
                {
                    var options = call.ArgAt<ChatOptions>(1);
                    var todoTool = options.Tools!.OfType<AIFunction>().First(function =>
                        function.Name.Contains("todo", StringComparison.OrdinalIgnoreCase)
                        && (!function.JsonSchema.TryGetProperty("required", out var required)
                            || required.GetArrayLength() == 0));
                    return new ChatResponse(new ChatMessage(ChatRole.Assistant,
                        [new FunctionCallContent("todo-call", todoTool.Name, new Dictionary<string, object?>())]))
                    {
                        FinishReason = ChatFinishReason.ToolCalls
                    };
                }

                toolResult = call.ArgAt<IEnumerable<ChatMessage>>(0)
                    .SelectMany(message => message.Contents)
                    .OfType<FunctionResultContent>()
                    .Single(result => result.CallId == "todo-call");
                return new ChatResponse(new ChatMessage(ChatRole.Assistant, "Day 1: Explore Tokyo."));
            });

        var agent = JapanTripAgent.Create(chatClient);
        var session = await agent.CreateSessionAsync();
        var response = await agent.RunAsync(JapanTripAgent.DefaultTask, session);

        Assert.Equal(2, requests);
        Assert.NotNull(toolResult);
        Assert.Null(toolResult.Exception);
        Assert.Equal("Day 1: Explore Tokyo.", response.Text);
    }
}
