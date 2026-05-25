namespace Taskboard.Shared;

public static class TaskStatus
{
    public const string Todo = "Todo";
    public const string InProgress = "InProgress";
    public const string InReview = "InReview";
    public const string Done = "Done";
    public const string Cancelled = "Cancelled";

    public static readonly IReadOnlyList<string> All = [Todo, InProgress, InReview, Done, Cancelled];
}

public static class TaskPriority
{
    public const string Low = "Low";
    public const string Medium = "Medium";
    public const string High = "High";
    public const string Critical = "Critical";
}

public static class UserRole
{
    public const string Owner = "Owner";
    public const string Admin = "Admin";
    public const string Member = "Member";
    public const string Viewer = "Viewer";
}
