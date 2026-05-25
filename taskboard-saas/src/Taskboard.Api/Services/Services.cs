using Taskboard.Api.Models;
using Taskboard.Api.Repositories;
using Taskboard.Shared.DTOs;

namespace Taskboard.Api.Services;

public interface IBoardService
{
    Task<IReadOnlyList<BoardDto>> ListBoardsAsync(string tenantId, CancellationToken ct = default);
    Task<BoardDto?> GetBoardAsync(string tenantId, string boardId, CancellationToken ct = default);
    Task<BoardDto> CreateBoardAsync(string tenantId, string userId, CreateBoardRequest request, CancellationToken ct = default);
    Task<BoardDto?> UpdateBoardAsync(string tenantId, string boardId, UpdateBoardRequest request, CancellationToken ct = default);
    Task<bool> DeleteBoardAsync(string tenantId, string boardId, CancellationToken ct = default);
}

public class BoardService(IBoardRepository repo) : IBoardService
{
    public async Task<IReadOnlyList<BoardDto>> ListBoardsAsync(string tenantId, CancellationToken ct = default)
    {
        var boards = await repo.ListByTenantAsync(tenantId, ct);
        return boards.Select(ToDto).ToList();
    }

    public async Task<BoardDto?> GetBoardAsync(string tenantId, string boardId, CancellationToken ct = default)
    {
        var board = await repo.GetByIdAsync(tenantId, boardId, ct);
        return board is null ? null : ToDto(board);
    }

    public async Task<BoardDto> CreateBoardAsync(string tenantId, string userId, CreateBoardRequest request, CancellationToken ct = default)
    {
        var board = new BoardDocument
        {
            TenantId = tenantId,
            Name = request.Name,
            Description = request.Description,
            CreatedBy = userId,
            MemberIds = request.MemberIds?.ToList() ?? []
        };
        var created = await repo.CreateAsync(board, ct);
        return ToDto(created);
    }

    public async Task<BoardDto?> UpdateBoardAsync(string tenantId, string boardId, UpdateBoardRequest request, CancellationToken ct = default)
    {
        var board = await repo.GetByIdAsync(tenantId, boardId, ct);
        if (board is null) return null;

        board.Name = request.Name;
        board.Description = request.Description;
        if (request.MemberIds is not null) board.MemberIds = request.MemberIds.ToList();

        var updated = await repo.UpdateAsync(board, ct);
        return ToDto(updated);
    }

    public async Task<bool> DeleteBoardAsync(string tenantId, string boardId, CancellationToken ct = default)
    {
        var board = await repo.GetByIdAsync(tenantId, boardId, ct);
        if (board is null) return false;
        board.IsArchived = true;
        await repo.UpdateAsync(board, ct);
        return true;
    }

    private static BoardDto ToDto(BoardDocument b) => new(
        b.Id, b.TenantId, b.Name, b.Description, b.CreatedBy,
        b.CreatedAt, b.UpdatedAt, b.IsArchived, b.MemberIds);
}

public interface ITaskService
{
    Task<IReadOnlyList<TaskDto>> ListTasksAsync(string tenantId, string boardId, CancellationToken ct = default);
    Task<TaskDto?> GetTaskAsync(string tenantId, string taskId, CancellationToken ct = default);
    Task<TaskDto> CreateTaskAsync(string tenantId, string boardId, string userId, CreateTaskRequest request, CancellationToken ct = default);
    Task<TaskDto?> UpdateTaskAsync(string tenantId, string taskId, UpdateTaskRequest request, CancellationToken ct = default);
    Task<TaskDto?> UpdateStatusAsync(string tenantId, string taskId, string status, CancellationToken ct = default);
    Task<TaskDto?> AssignTaskAsync(string tenantId, string taskId, string? assigneeId, CancellationToken ct = default);
    Task<bool> DeleteTaskAsync(string tenantId, string taskId, CancellationToken ct = default);
}

public class TaskService(ITaskRepository repo) : ITaskService
{
    public async Task<IReadOnlyList<TaskDto>> ListTasksAsync(string tenantId, string boardId, CancellationToken ct = default)
    {
        var tasks = await repo.ListByBoardAsync(tenantId, boardId, ct);
        return tasks.Select(ToDto).ToList();
    }

    public async Task<TaskDto?> GetTaskAsync(string tenantId, string taskId, CancellationToken ct = default)
    {
        var task = await repo.GetByIdAsync(tenantId, taskId, ct);
        return task is null ? null : ToDto(task);
    }

    public async Task<TaskDto> CreateTaskAsync(string tenantId, string boardId, string userId, CreateTaskRequest request, CancellationToken ct = default)
    {
        var task = new TaskDocument
        {
            TenantId = tenantId,
            BoardId = boardId,
            Title = request.Title,
            Description = request.Description,
            Priority = request.Priority,
            AssigneeId = request.AssigneeId,
            DueDate = request.DueDate,
            CreatedBy = userId,
            Tags = request.Tags?.ToList() ?? []
        };
        var created = await repo.CreateAsync(task, ct);
        return ToDto(created);
    }

    public async Task<TaskDto?> UpdateTaskAsync(string tenantId, string taskId, UpdateTaskRequest request, CancellationToken ct = default)
    {
        var task = await repo.GetByIdAsync(tenantId, taskId, ct);
        if (task is null) return null;

        task.Title = request.Title;
        task.Description = request.Description;
        task.Priority = request.Priority;
        task.AssigneeId = request.AssigneeId;
        task.DueDate = request.DueDate;
        if (request.Tags is not null) task.Tags = request.Tags.ToList();

        var updated = await repo.UpdateAsync(task, ct);
        return ToDto(updated);
    }

    public async Task<TaskDto?> UpdateStatusAsync(string tenantId, string taskId, string status, CancellationToken ct = default)
    {
        var task = await repo.GetByIdAsync(tenantId, taskId, ct);
        if (task is null) return null;
        task.Status = status;
        var updated = await repo.UpdateAsync(task, ct);
        return ToDto(updated);
    }

    public async Task<TaskDto?> AssignTaskAsync(string tenantId, string taskId, string? assigneeId, CancellationToken ct = default)
    {
        var task = await repo.GetByIdAsync(tenantId, taskId, ct);
        if (task is null) return null;
        task.AssigneeId = assigneeId;
        var updated = await repo.UpdateAsync(task, ct);
        return ToDto(updated);
    }

    public async Task<bool> DeleteTaskAsync(string tenantId, string taskId, CancellationToken ct = default)
    {
        var task = await repo.GetByIdAsync(tenantId, taskId, ct);
        if (task is null) return false;
        await repo.DeleteAsync(tenantId, taskId, ct);
        return true;
    }

    private static TaskDto ToDto(TaskDocument t) => new(
        t.Id, t.TenantId, t.BoardId, t.Title, t.Description, t.Status,
        t.Priority, t.AssigneeId, t.DueDate, t.CreatedBy, t.CreatedAt, t.UpdatedAt, t.Tags);
}

public interface ITenantService
{
    Task<TenantDto> ProvisionAsync(string tenantId, string displayName, CancellationToken ct = default);
    Task<TenantDto?> GetTenantAsync(string tenantId, CancellationToken ct = default);
    Task<TenantDto?> UpdateSettingsAsync(string tenantId, TenantSettingsDto settings, CancellationToken ct = default);
}

public class TenantService(ITenantRepository repo) : ITenantService
{
    public async Task<TenantDto> ProvisionAsync(string tenantId, string displayName, CancellationToken ct = default)
    {
        var existing = await repo.GetByIdAsync(tenantId, ct);
        if (existing is not null) return ToDto(existing);

        var tenant = new TenantDocument { Id = tenantId, TenantId = tenantId, DisplayName = displayName };
        var created = await repo.UpsertAsync(tenant, ct);
        return ToDto(created);
    }

    public async Task<TenantDto?> GetTenantAsync(string tenantId, CancellationToken ct = default)
    {
        var tenant = await repo.GetByIdAsync(tenantId, ct);
        return tenant is null ? null : ToDto(tenant);
    }

    public async Task<TenantDto?> UpdateSettingsAsync(string tenantId, TenantSettingsDto settings, CancellationToken ct = default)
    {
        var tenant = await repo.GetByIdAsync(tenantId, ct);
        if (tenant is null) return null;
        tenant.Settings.AllowGuestUsers = settings.AllowGuestUsers;
        tenant.Settings.MaxBoardsPerTenant = settings.MaxBoardsPerTenant;
        var updated = await repo.UpdateAsync(tenant, ct);
        return ToDto(updated);
    }

    private static TenantDto ToDto(TenantDocument t) => new(
        t.Id, t.DisplayName, t.ProvisionedAt,
        new TenantSettingsDto(t.Settings.AllowGuestUsers, t.Settings.MaxBoardsPerTenant));
}

public interface IUserService
{
    Task<UserDto> UpsertUserAsync(string tenantId, string userId, string displayName, string email, CancellationToken ct = default);
    Task<IReadOnlyList<UserDto>> ListUsersAsync(string tenantId, CancellationToken ct = default);
    Task<UserDto?> GetUserAsync(string tenantId, string userId, CancellationToken ct = default);
    Task<UserDto?> UpdateRoleAsync(string tenantId, string userId, string role, CancellationToken ct = default);
}

public class UserService(IUserRepository repo) : IUserService
{
    public async Task<UserDto> UpsertUserAsync(string tenantId, string userId, string displayName, string email, CancellationToken ct = default)
    {
        var existing = await repo.GetByIdAsync(tenantId, userId, ct);
        var user = existing ?? new UserDocument { Id = userId, TenantId = tenantId };
        user.DisplayName = displayName;
        user.Email = email;
        user.LastSeenAt = DateTimeOffset.UtcNow;
        var upserted = await repo.UpsertAsync(user, ct);
        return ToDto(upserted);
    }

    public async Task<IReadOnlyList<UserDto>> ListUsersAsync(string tenantId, CancellationToken ct = default)
    {
        var users = await repo.ListByTenantAsync(tenantId, ct);
        return users.Select(ToDto).ToList();
    }

    public async Task<UserDto?> GetUserAsync(string tenantId, string userId, CancellationToken ct = default)
    {
        var user = await repo.GetByIdAsync(tenantId, userId, ct);
        return user is null ? null : ToDto(user);
    }

    public async Task<UserDto?> UpdateRoleAsync(string tenantId, string userId, string role, CancellationToken ct = default)
    {
        var user = await repo.GetByIdAsync(tenantId, userId, ct);
        if (user is null) return null;
        user.Role = role;
        var updated = await repo.UpsertAsync(user, ct);
        return ToDto(updated);
    }

    private static UserDto ToDto(UserDocument u) => new(
        u.Id, u.TenantId, u.DisplayName, u.Email, u.Role, u.LastSeenAt);
}
