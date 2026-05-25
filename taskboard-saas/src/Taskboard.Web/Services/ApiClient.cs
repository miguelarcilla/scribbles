using System.Net.Http.Json;
using Taskboard.Shared.DTOs;

namespace Taskboard.Web.Services;

public interface IApiClient
{
    // Boards
    Task<IReadOnlyList<BoardDto>?> GetBoardsAsync(CancellationToken ct = default);
    Task<BoardDto?> GetBoardAsync(string boardId, CancellationToken ct = default);
    Task<BoardDto?> CreateBoardAsync(CreateBoardRequest request, CancellationToken ct = default);
    Task<BoardDto?> UpdateBoardAsync(string boardId, UpdateBoardRequest request, CancellationToken ct = default);
    Task DeleteBoardAsync(string boardId, CancellationToken ct = default);
    // Tasks
    Task<IReadOnlyList<TaskDto>?> GetTasksAsync(string boardId, CancellationToken ct = default);
    Task<TaskDto?> CreateTaskAsync(string boardId, CreateTaskRequest request, CancellationToken ct = default);
    Task<TaskDto?> UpdateTaskAsync(string taskId, UpdateTaskRequest request, CancellationToken ct = default);
    Task<TaskDto?> UpdateTaskStatusAsync(string taskId, string status, CancellationToken ct = default);
    Task<TaskDto?> AssignTaskAsync(string taskId, string? assigneeId, CancellationToken ct = default);
    Task DeleteTaskAsync(string taskId, CancellationToken ct = default);
    // Tenant
    Task<TenantDto?> GetTenantAsync(CancellationToken ct = default);
    // Users
    Task<UserDto?> GetMeAsync(CancellationToken ct = default);
    Task<IReadOnlyList<UserDto>?> GetUsersAsync(CancellationToken ct = default);
}

public class ApiClient(HttpClient http) : IApiClient
{
    private const string Base = "api/v1";

    public Task<IReadOnlyList<BoardDto>?> GetBoardsAsync(CancellationToken ct = default) =>
        http.GetFromJsonAsync<IReadOnlyList<BoardDto>>($"{Base}/boards", ct);

    public Task<BoardDto?> GetBoardAsync(string boardId, CancellationToken ct = default) =>
        http.GetFromJsonAsync<BoardDto>($"{Base}/boards/{boardId}", ct);

    public async Task<BoardDto?> CreateBoardAsync(CreateBoardRequest request, CancellationToken ct = default)
    {
        var response = await http.PostAsJsonAsync($"{Base}/boards", request, ct);
        return response.IsSuccessStatusCode ? await response.Content.ReadFromJsonAsync<BoardDto>(ct) : null;
    }

    public async Task<BoardDto?> UpdateBoardAsync(string boardId, UpdateBoardRequest request, CancellationToken ct = default)
    {
        var response = await http.PutAsJsonAsync($"{Base}/boards/{boardId}", request, ct);
        return response.IsSuccessStatusCode ? await response.Content.ReadFromJsonAsync<BoardDto>(ct) : null;
    }

    public async Task DeleteBoardAsync(string boardId, CancellationToken ct = default) =>
        await http.DeleteAsync($"{Base}/boards/{boardId}", ct);

    public Task<IReadOnlyList<TaskDto>?> GetTasksAsync(string boardId, CancellationToken ct = default) =>
        http.GetFromJsonAsync<IReadOnlyList<TaskDto>>($"{Base}/boards/{boardId}/tasks", ct);

    public async Task<TaskDto?> CreateTaskAsync(string boardId, CreateTaskRequest request, CancellationToken ct = default)
    {
        var response = await http.PostAsJsonAsync($"{Base}/boards/{boardId}/tasks", request, ct);
        return response.IsSuccessStatusCode ? await response.Content.ReadFromJsonAsync<TaskDto>(ct) : null;
    }

    public async Task<TaskDto?> UpdateTaskAsync(string taskId, UpdateTaskRequest request, CancellationToken ct = default)
    {
        var response = await http.PutAsJsonAsync($"{Base}/tasks/{taskId}", request, ct);
        return response.IsSuccessStatusCode ? await response.Content.ReadFromJsonAsync<TaskDto>(ct) : null;
    }

    public async Task<TaskDto?> UpdateTaskStatusAsync(string taskId, string status, CancellationToken ct = default)
    {
        var response = await http.PatchAsJsonAsync($"{Base}/tasks/{taskId}/status", new UpdateTaskStatusRequest(status), ct);
        return response.IsSuccessStatusCode ? await response.Content.ReadFromJsonAsync<TaskDto>(ct) : null;
    }

    public async Task<TaskDto?> AssignTaskAsync(string taskId, string? assigneeId, CancellationToken ct = default)
    {
        var response = await http.PatchAsJsonAsync($"{Base}/tasks/{taskId}/assign", new AssignTaskRequest(assigneeId), ct);
        return response.IsSuccessStatusCode ? await response.Content.ReadFromJsonAsync<TaskDto>(ct) : null;
    }

    public async Task DeleteTaskAsync(string taskId, CancellationToken ct = default) =>
        await http.DeleteAsync($"{Base}/tasks/{taskId}", ct);

    public Task<TenantDto?> GetTenantAsync(CancellationToken ct = default) =>
        http.GetFromJsonAsync<TenantDto>($"{Base}/tenant", ct);

    public Task<UserDto?> GetMeAsync(CancellationToken ct = default) =>
        http.GetFromJsonAsync<UserDto>($"{Base}/users/me", ct);

    public Task<IReadOnlyList<UserDto>?> GetUsersAsync(CancellationToken ct = default) =>
        http.GetFromJsonAsync<IReadOnlyList<UserDto>>($"{Base}/users", ct);
}

public interface IBoardStateService
{
    event Action? OnChange;
    IReadOnlyList<BoardDto> Boards { get; }
    BoardDto? SelectedBoard { get; }
    IReadOnlyList<TaskDto> CurrentTasks { get; }
    Task LoadBoardsAsync();
    Task SelectBoardAsync(string boardId);
}

public class BoardStateService(IApiClient api) : IBoardStateService
{
    public event Action? OnChange;
    public IReadOnlyList<BoardDto> Boards { get; private set; } = [];
    public BoardDto? SelectedBoard { get; private set; }
    public IReadOnlyList<TaskDto> CurrentTasks { get; private set; } = [];

    public async Task LoadBoardsAsync()
    {
        Boards = await api.GetBoardsAsync() ?? [];
        OnChange?.Invoke();
    }

    public async Task SelectBoardAsync(string boardId)
    {
        SelectedBoard = Boards.FirstOrDefault(b => b.Id == boardId);
        CurrentTasks = await api.GetTasksAsync(boardId) ?? [];
        OnChange?.Invoke();
    }
}
