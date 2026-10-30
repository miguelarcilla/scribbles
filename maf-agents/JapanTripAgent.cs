using Microsoft.Agents.AI;
using Microsoft.Extensions.AI;

namespace maf_agents;

internal static class JapanTripAgent
{
    internal const string DefaultTask = """
        Plan a seven-day first-time trip to Japan for two adults in spring.
        Visit Tokyo and Kyoto, starting in Tokyo and departing from Osaka.
        We enjoy Japanese food, culture, gardens, and a relaxed pace.
        Our budget is JPY 300,000 total for two, excluding international flights.
        Provide a day-by-day itinerary, transport suggestions, an estimated
        budget breakdown, and a short preparation checklist.
        """;

    internal static HarnessAgent Create(IChatClient chatClient) =>
        new(chatClient, new HarnessAgentOptions
        {
            Name = "JapanTripPlanner",
            Description = "Plans practical Japan itineraries with explicit assumptions and estimated costs.",
            MaximumIterationsPerRequest = 12,
            DisableWebSearch = true,
            DisableFileMemory = true,
            DisableAgentSkillsProvider = true,
            ChatOptions = new ChatOptions
            {
                Instructions = """
                    You are a Japan travel-planning assistant.
                    Use the harness planning and todo tools to organize the request.
                    Give concise progress summaries, not private reasoning.
                    Produce the requested itinerary rather than only describing a plan.
                    Make reasonable assumptions for missing details and state them.
                    Group nearby sights, allow travel and rest time, and respect the budget.
                    Include daily activities, intercity transport, accommodation areas,
                    estimated costs in JPY, and a preparation checklist.
                    Label prices and journey times as estimates. You have no live search
                    or booking tools: do not claim to verify availability, current fares,
                    opening hours, weather, visa eligibility, or reservations.
                    Remind travelers to confirm current official travel requirements.
                    Mark the planning todos complete when the itinerary is ready.
                    """
            }
        });
}
