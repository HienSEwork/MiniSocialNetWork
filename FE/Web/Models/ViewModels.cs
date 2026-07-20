namespace MiniSocialNetwork.Web.Models;

public sealed class ComposerModel
{
    public Guid? GroupId { get; set; }
    public bool LockGroup { get; set; }
    public List<GroupResponse> Groups { get; set; } = new();
    public string ReturnUrl { get; set; } = "/";
}

public sealed class FeedViewModel
{
    public PagedResult<PostResponse> Feed { get; set; } = new();
    public List<GroupResponse> MyGroups { get; set; } = new();
    public List<GroupResponse> SuggestedGroups { get; set; } = new();
    public int Page { get; set; } = 1;
}

public sealed class PostDetailsViewModel
{
    public PostResponse Post { get; set; } = new();
    public List<CommentResponse> Comments { get; set; } = new();
}

public sealed class GroupDetailsViewModel
{
    public GroupResponse Group { get; set; } = new();
    public PagedResult<PostResponse> Feed { get; set; } = new();
    public bool IsMember { get; set; }
    public bool IsOwner { get; set; }
}

public sealed class GroupsIndexViewModel
{
    public List<GroupResponse> MyGroups { get; set; } = new();
    public List<GroupResponse> AllGroups { get; set; } = new();
}

public sealed class ProfileViewModel
{
    public UserProfile Profile { get; set; } = new();
    public bool IsMe { get; set; }
}

public sealed class ChatViewModel
{
    public List<ChatUser> Users { get; set; } = new();
    public List<GroupResponse> Groups { get; set; } = new();
    public string HubUrl { get; set; } = "";
    public string Token { get; set; } = "";
}

public sealed class AdminViewModel
{
    public DashboardStats Stats { get; set; } = new();
    public List<PostsPerDayItem> PostsPerDay { get; set; } = new();
    public PagedResult<AdminUser> Users { get; set; } = new();
    public string? Keyword { get; set; }
}
