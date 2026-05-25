using Microsoft.Azure.Cosmos;
using Taskboard.Api.Models;

namespace Taskboard.Api.Repositories;

public interface IBoardRepository
{
    Task<BoardDocument?> GetByIdAsync(string tenantId, string boardId, CancellationToken ct = default);
    Task<IReadOnlyList<BoardDocument>> ListByTenantAsync(string tenantId, CancellationToken ct = default);
    Task<BoardDocument> CreateAsync(BoardDocument board, CancellationToken ct = default);
    Task<BoardDocument> UpdateAsync(BoardDocument board, CancellationToken ct = default);
    Task DeleteAsync(string tenantId, string boardId, CancellationToken ct = default);
}

public interface ITaskRepository
{
    Task<TaskDocument?> GetByIdAsync(string tenantId, string taskId, CancellationToken ct = default);
    Task<IReadOnlyList<TaskDocument>> ListByBoardAsync(string tenantId, string boardId, CancellationToken ct = default);
    Task<TaskDocument> CreateAsync(TaskDocument task, CancellationToken ct = default);
    Task<TaskDocument> UpdateAsync(TaskDocument task, CancellationToken ct = default);
    Task DeleteAsync(string tenantId, string taskId, CancellationToken ct = default);
}

public interface IUserRepository
{
    Task<UserDocument?> GetByIdAsync(string tenantId, string userId, CancellationToken ct = default);
    Task<IReadOnlyList<UserDocument>> ListByTenantAsync(string tenantId, CancellationToken ct = default);
    Task<UserDocument> UpsertAsync(UserDocument user, CancellationToken ct = default);
}

public interface ITenantRepository
{
    Task<TenantDocument?> GetByIdAsync(string tenantId, CancellationToken ct = default);
    Task<TenantDocument> UpsertAsync(TenantDocument tenant, CancellationToken ct = default);
    Task<TenantDocument> UpdateAsync(TenantDocument tenant, CancellationToken ct = default);
}
