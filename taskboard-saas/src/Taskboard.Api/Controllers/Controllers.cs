using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Identity.Web.Resource;
using System.Security.Claims;
using Taskboard.Api.Services;
using Taskboard.Shared.DTOs;

namespace Taskboard.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/boards")]
[RequiredScope("access_as_user")]
public class BoardsController(IBoardService boardService, ITaskService taskService, ITenantService tenantService, IUserService userService) : ControllerBase
{
    private string TenantId => User.FindFirstValue("tid") ?? throw new UnauthorizedAccessException();
    private string UserId => User.FindFirstValue("oid") ?? throw new UnauthorizedAccessException();
    private string DisplayName => User.FindFirstValue("name") ?? User.Identity?.Name ?? "Unknown";
    private string Email => User.FindFirstValue("preferred_username") ?? "";

    private async Task EnsureUserProvisioned(CancellationToken ct)
    {
        var tenantName = User.FindFirstValue("tid") ?? TenantId;
        await tenantService.ProvisionAsync(TenantId, tenantName, ct);
        await userService.UpsertUserAsync(TenantId, UserId, DisplayName, Email, ct);
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<BoardDto>>> List(CancellationToken ct)
    {
        await EnsureUserProvisioned(ct);
        return Ok(await boardService.ListBoardsAsync(TenantId, ct));
    }

    [HttpGet("{boardId}")]
    public async Task<ActionResult<BoardDto>> Get(string boardId, CancellationToken ct)
    {
        var board = await boardService.GetBoardAsync(TenantId, boardId, ct);
        return board is null ? NotFound() : Ok(board);
    }

    [HttpPost]
    public async Task<ActionResult<BoardDto>> Create([FromBody] CreateBoardRequest request, CancellationToken ct)
    {
        await EnsureUserProvisioned(ct);
        var board = await boardService.CreateBoardAsync(TenantId, UserId, request, ct);
        return CreatedAtAction(nameof(Get), new { boardId = board.Id }, board);
    }

    [HttpPut("{boardId}")]
    public async Task<ActionResult<BoardDto>> Update(string boardId, [FromBody] UpdateBoardRequest request, CancellationToken ct)
    {
        var board = await boardService.UpdateBoardAsync(TenantId, boardId, request, ct);
        return board is null ? NotFound() : Ok(board);
    }

    [HttpDelete("{boardId}")]
    public async Task<IActionResult> Delete(string boardId, CancellationToken ct)
    {
        var deleted = await boardService.DeleteBoardAsync(TenantId, boardId, ct);
        return deleted ? NoContent() : NotFound();
    }

    [HttpGet("{boardId}/tasks")]
    public async Task<ActionResult<IReadOnlyList<TaskDto>>> ListTasks(string boardId, CancellationToken ct)
    {
        return Ok(await taskService.ListTasksAsync(TenantId, boardId, ct));
    }

    [HttpPost("{boardId}/tasks")]
    public async Task<ActionResult<TaskDto>> CreateTask(string boardId, [FromBody] CreateTaskRequest request, CancellationToken ct)
    {
        var task = await taskService.CreateTaskAsync(TenantId, boardId, UserId, request, ct);
        return CreatedAtAction("GetTask", "Tasks", new { taskId = task.Id }, task);
    }
}

[ApiController]
[Authorize]
[Route("api/v1/tasks")]
[RequiredScope("access_as_user")]
public class TasksController(ITaskService taskService) : ControllerBase
{
    private string TenantId => User.FindFirstValue("tid") ?? throw new UnauthorizedAccessException();

    [HttpGet("{taskId}")]
    public async Task<ActionResult<TaskDto>> GetTask(string taskId, CancellationToken ct)
    {
        var task = await taskService.GetTaskAsync(TenantId, taskId, ct);
        return task is null ? NotFound() : Ok(task);
    }

    [HttpPut("{taskId}")]
    public async Task<ActionResult<TaskDto>> Update(string taskId, [FromBody] UpdateTaskRequest request, CancellationToken ct)
    {
        var task = await taskService.UpdateTaskAsync(TenantId, taskId, request, ct);
        return task is null ? NotFound() : Ok(task);
    }

    [HttpPatch("{taskId}/status")]
    public async Task<ActionResult<TaskDto>> UpdateStatus(string taskId, [FromBody] UpdateTaskStatusRequest request, CancellationToken ct)
    {
        var task = await taskService.UpdateStatusAsync(TenantId, taskId, request.Status, ct);
        return task is null ? NotFound() : Ok(task);
    }

    [HttpPatch("{taskId}/assign")]
    public async Task<ActionResult<TaskDto>> Assign(string taskId, [FromBody] AssignTaskRequest request, CancellationToken ct)
    {
        var task = await taskService.AssignTaskAsync(TenantId, taskId, request.AssigneeId, ct);
        return task is null ? NotFound() : Ok(task);
    }

    [HttpDelete("{taskId}")]
    public async Task<IActionResult> Delete(string taskId, CancellationToken ct)
    {
        var deleted = await taskService.DeleteTaskAsync(TenantId, taskId, ct);
        return deleted ? NoContent() : NotFound();
    }
}

[ApiController]
[Authorize]
[Route("api/v1/tenant")]
[RequiredScope("access_as_user")]
public class TenantController(ITenantService tenantService) : ControllerBase
{
    private string TenantId => User.FindFirstValue("tid") ?? throw new UnauthorizedAccessException();

    [HttpGet]
    public async Task<ActionResult<TenantDto>> Get(CancellationToken ct)
    {
        var tenant = await tenantService.GetTenantAsync(TenantId, ct);
        return tenant is null ? NotFound() : Ok(tenant);
    }

    [HttpPut]
    public async Task<ActionResult<TenantDto>> Update([FromBody] TenantSettingsDto settings, CancellationToken ct)
    {
        var tenant = await tenantService.UpdateSettingsAsync(TenantId, settings, ct);
        return tenant is null ? NotFound() : Ok(tenant);
    }
}

[ApiController]
[Authorize]
[Route("api/v1/users")]
[RequiredScope("access_as_user")]
public class UsersController(IUserService userService) : ControllerBase
{
    private string TenantId => User.FindFirstValue("tid") ?? throw new UnauthorizedAccessException();
    private string UserId => User.FindFirstValue("oid") ?? throw new UnauthorizedAccessException();
    private string DisplayName => User.FindFirstValue("name") ?? User.Identity?.Name ?? "Unknown";
    private string Email => User.FindFirstValue("preferred_username") ?? "";

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<UserDto>>> List(CancellationToken ct) =>
        Ok(await userService.ListUsersAsync(TenantId, ct));

    [HttpGet("me")]
    public async Task<ActionResult<UserDto>> GetMe(CancellationToken ct)
    {
        var user = await userService.UpsertUserAsync(TenantId, UserId, DisplayName, Email, ct);
        return Ok(user);
    }

    [HttpPut("{userId}/role")]
    public async Task<ActionResult<UserDto>> UpdateRole(string userId, [FromBody] string role, CancellationToken ct)
    {
        var user = await userService.UpdateRoleAsync(TenantId, userId, role, ct);
        return user is null ? NotFound() : Ok(user);
    }
}
