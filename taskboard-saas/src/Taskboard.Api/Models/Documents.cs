using System.Text.Json.Serialization;

namespace Taskboard.Api.Models;

public class BoardDocument
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = Guid.NewGuid().ToString();

    [JsonPropertyName("tenantId")]
    public string TenantId { get; set; } = default!;

    [JsonPropertyName("name")]
    public string Name { get; set; } = default!;

    [JsonPropertyName("description")]
    public string? Description { get; set; }

    [JsonPropertyName("createdBy")]
    public string CreatedBy { get; set; } = default!;

    [JsonPropertyName("createdAt")]
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;

    [JsonPropertyName("updatedAt")]
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;

    [JsonPropertyName("memberIds")]
    public List<string> MemberIds { get; set; } = [];

    [JsonPropertyName("isArchived")]
    public bool IsArchived { get; set; }

    [JsonPropertyName("type")]
    public string Type { get; } = "board";
}

public class TaskDocument
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = Guid.NewGuid().ToString();

    [JsonPropertyName("tenantId")]
    public string TenantId { get; set; } = default!;

    [JsonPropertyName("boardId")]
    public string BoardId { get; set; } = default!;

    [JsonPropertyName("title")]
    public string Title { get; set; } = default!;

    [JsonPropertyName("description")]
    public string? Description { get; set; }

    [JsonPropertyName("status")]
    public string Status { get; set; } = Taskboard.Shared.TaskStatus.Todo;

    [JsonPropertyName("priority")]
    public string Priority { get; set; } = Taskboard.Shared.TaskPriority.Medium;

    [JsonPropertyName("assigneeId")]
    public string? AssigneeId { get; set; }

    [JsonPropertyName("dueDate")]
    public DateTimeOffset? DueDate { get; set; }

    [JsonPropertyName("createdBy")]
    public string CreatedBy { get; set; } = default!;

    [JsonPropertyName("createdAt")]
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;

    [JsonPropertyName("updatedAt")]
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;

    [JsonPropertyName("tags")]
    public List<string> Tags { get; set; } = [];

    [JsonPropertyName("type")]
    public string Type { get; } = "task";
}

public class UserDocument
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = default!;

    [JsonPropertyName("tenantId")]
    public string TenantId { get; set; } = default!;

    [JsonPropertyName("displayName")]
    public string DisplayName { get; set; } = default!;

    [JsonPropertyName("email")]
    public string Email { get; set; } = default!;

    [JsonPropertyName("role")]
    public string Role { get; set; } = Taskboard.Shared.UserRole.Member;

    [JsonPropertyName("lastSeenAt")]
    public DateTimeOffset LastSeenAt { get; set; } = DateTimeOffset.UtcNow;

    [JsonPropertyName("type")]
    public string Type { get; } = "user";
}

public class TenantDocument
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = default!;

    [JsonPropertyName("tenantId")]
    public string TenantId { get; set; } = default!;

    [JsonPropertyName("displayName")]
    public string DisplayName { get; set; } = default!;

    [JsonPropertyName("provisionedAt")]
    public DateTimeOffset ProvisionedAt { get; set; } = DateTimeOffset.UtcNow;

    [JsonPropertyName("settings")]
    public TenantSettings Settings { get; set; } = new();

    [JsonPropertyName("type")]
    public string Type { get; } = "tenant";
}

public class TenantSettings
{
    [JsonPropertyName("allowGuestUsers")]
    public bool AllowGuestUsers { get; set; }

    [JsonPropertyName("maxBoardsPerTenant")]
    public int MaxBoardsPerTenant { get; set; } = 100;
}
