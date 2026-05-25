namespace Taskboard.Shared.DTOs;

public record TenantDto(
    string Id,
    string DisplayName,
    DateTimeOffset ProvisionedAt,
    TenantSettingsDto Settings
);

public record TenantSettingsDto(
    bool AllowGuestUsers,
    int MaxBoardsPerTenant
);

public record UserDto(
    string Id,
    string TenantId,
    string DisplayName,
    string Email,
    string Role,
    DateTimeOffset LastSeenAt
);

public record BoardDto(
    string Id,
    string TenantId,
    string Name,
    string? Description,
    string CreatedBy,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt,
    bool IsArchived,
    IReadOnlyList<string> MemberIds
);

public record TaskDto(
    string Id,
    string TenantId,
    string BoardId,
    string Title,
    string? Description,
    string Status,
    string Priority,
    string? AssigneeId,
    DateTimeOffset? DueDate,
    string CreatedBy,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt,
    IReadOnlyList<string> Tags
);

public record CreateBoardRequest(
    string Name,
    string? Description,
    IReadOnlyList<string>? MemberIds
);

public record UpdateBoardRequest(
    string Name,
    string? Description,
    IReadOnlyList<string>? MemberIds
);

public record CreateTaskRequest(
    string Title,
    string? Description,
    string Priority,
    string? AssigneeId,
    DateTimeOffset? DueDate,
    IReadOnlyList<string>? Tags
);

public record UpdateTaskRequest(
    string Title,
    string? Description,
    string Priority,
    string? AssigneeId,
    DateTimeOffset? DueDate,
    IReadOnlyList<string>? Tags
);

public record UpdateTaskStatusRequest(string Status);

public record AssignTaskRequest(string? AssigneeId);
