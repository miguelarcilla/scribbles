using Microsoft.Azure.Cosmos;
using Microsoft.Azure.Cosmos.Linq;
using Taskboard.Api.Models;

namespace Taskboard.Api.Repositories;

public abstract class CosmosRepositoryBase(CosmosClient client, IConfiguration config)
{
    protected readonly string DatabaseName = config["CosmosDb:DatabaseName"] ?? "taskboard";
    protected readonly CosmosClient Client = client;

    protected Container GetContainer(string containerName) =>
        Client.GetContainer(DatabaseName, containerName);

    protected static async Task<IReadOnlyList<T>> ReadAllAsync<T>(FeedIterator<T> iterator, CancellationToken ct)
    {
        var results = new List<T>();
        while (iterator.HasMoreResults)
        {
            var page = await iterator.ReadNextAsync(ct);
            results.AddRange(page);
        }
        return results;
    }
}

public class CosmosBoardRepository(CosmosClient client, IConfiguration config)
    : CosmosRepositoryBase(client, config), IBoardRepository
{
    private Container Boards => GetContainer("boards");

    public async Task<BoardDocument?> GetByIdAsync(string tenantId, string boardId, CancellationToken ct = default)
    {
        try
        {
            var response = await Boards.ReadItemAsync<BoardDocument>(boardId, new PartitionKey(tenantId), cancellationToken: ct);
            return response.Resource;
        }
        catch (CosmosException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return null;
        }
    }

    public async Task<IReadOnlyList<BoardDocument>> ListByTenantAsync(string tenantId, CancellationToken ct = default)
    {
        var query = Boards.GetItemLinqQueryable<BoardDocument>()
            .Where(b => b.TenantId == tenantId && !b.IsArchived)
            .ToFeedIterator();
        return await ReadAllAsync(query, ct);
    }

    public async Task<BoardDocument> CreateAsync(BoardDocument board, CancellationToken ct = default)
    {
        var response = await Boards.CreateItemAsync(board, new PartitionKey(board.TenantId), cancellationToken: ct);
        return response.Resource;
    }

    public async Task<BoardDocument> UpdateAsync(BoardDocument board, CancellationToken ct = default)
    {
        board.UpdatedAt = DateTimeOffset.UtcNow;
        var response = await Boards.ReplaceItemAsync(board, board.Id, new PartitionKey(board.TenantId), cancellationToken: ct);
        return response.Resource;
    }

    public async Task DeleteAsync(string tenantId, string boardId, CancellationToken ct = default)
    {
        await Boards.DeleteItemAsync<BoardDocument>(boardId, new PartitionKey(tenantId), cancellationToken: ct);
    }
}

public class CosmosTaskRepository(CosmosClient client, IConfiguration config)
    : CosmosRepositoryBase(client, config), ITaskRepository
{
    private Container Tasks => GetContainer("tasks");

    public async Task<TaskDocument?> GetByIdAsync(string tenantId, string taskId, CancellationToken ct = default)
    {
        try
        {
            var response = await Tasks.ReadItemAsync<TaskDocument>(taskId, new PartitionKey(tenantId), cancellationToken: ct);
            return response.Resource;
        }
        catch (CosmosException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return null;
        }
    }

    public async Task<IReadOnlyList<TaskDocument>> ListByBoardAsync(string tenantId, string boardId, CancellationToken ct = default)
    {
        var query = Tasks.GetItemLinqQueryable<TaskDocument>()
            .Where(t => t.TenantId == tenantId && t.BoardId == boardId)
            .ToFeedIterator();
        return await ReadAllAsync(query, ct);
    }

    public async Task<TaskDocument> CreateAsync(TaskDocument task, CancellationToken ct = default)
    {
        var response = await Tasks.CreateItemAsync(task, new PartitionKey(task.TenantId), cancellationToken: ct);
        return response.Resource;
    }

    public async Task<TaskDocument> UpdateAsync(TaskDocument task, CancellationToken ct = default)
    {
        task.UpdatedAt = DateTimeOffset.UtcNow;
        var response = await Tasks.ReplaceItemAsync(task, task.Id, new PartitionKey(task.TenantId), cancellationToken: ct);
        return response.Resource;
    }

    public async Task DeleteAsync(string tenantId, string taskId, CancellationToken ct = default)
    {
        await Tasks.DeleteItemAsync<TaskDocument>(taskId, new PartitionKey(tenantId), cancellationToken: ct);
    }
}

public class CosmosUserRepository(CosmosClient client, IConfiguration config)
    : CosmosRepositoryBase(client, config), IUserRepository
{
    private Container Users => GetContainer("users");

    public async Task<UserDocument?> GetByIdAsync(string tenantId, string userId, CancellationToken ct = default)
    {
        try
        {
            var response = await Users.ReadItemAsync<UserDocument>(userId, new PartitionKey(tenantId), cancellationToken: ct);
            return response.Resource;
        }
        catch (CosmosException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return null;
        }
    }

    public async Task<IReadOnlyList<UserDocument>> ListByTenantAsync(string tenantId, CancellationToken ct = default)
    {
        var query = Users.GetItemLinqQueryable<UserDocument>()
            .Where(u => u.TenantId == tenantId)
            .ToFeedIterator();
        return await ReadAllAsync(query, ct);
    }

    public async Task<UserDocument> UpsertAsync(UserDocument user, CancellationToken ct = default)
    {
        var response = await Users.UpsertItemAsync(user, new PartitionKey(user.TenantId), cancellationToken: ct);
        return response.Resource;
    }
}

public class CosmosTenantRepository(CosmosClient client, IConfiguration config)
    : CosmosRepositoryBase(client, config), ITenantRepository
{
    private Container Tenants => GetContainer("tenants");

    public async Task<TenantDocument?> GetByIdAsync(string tenantId, CancellationToken ct = default)
    {
        try
        {
            var response = await Tenants.ReadItemAsync<TenantDocument>(tenantId, new PartitionKey(tenantId), cancellationToken: ct);
            return response.Resource;
        }
        catch (CosmosException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return null;
        }
    }

    public async Task<TenantDocument> UpsertAsync(TenantDocument tenant, CancellationToken ct = default)
    {
        var response = await Tenants.UpsertItemAsync(tenant, new PartitionKey(tenant.TenantId), cancellationToken: ct);
        return response.Resource;
    }

    public async Task<TenantDocument> UpdateAsync(TenantDocument tenant, CancellationToken ct = default)
    {
        var response = await Tenants.ReplaceItemAsync(tenant, tenant.Id, new PartitionKey(tenant.TenantId), cancellationToken: ct);
        return response.Resource;
    }
}
