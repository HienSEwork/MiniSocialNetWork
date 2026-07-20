namespace MiniSocialNetwork.Web.Services;

/// <summary>Lightweight VI/EN localizer driven by a "lang" cookie (default: vi).</summary>
public static class Loc
{
    public const string CookieName = "lang";

    public static bool IsEnglish(HttpContext ctx) =>
        (ctx.Request.Cookies[CookieName] ?? "vi").Equals("en", StringComparison.OrdinalIgnoreCase);

    public static string Current(HttpContext ctx) => IsEnglish(ctx) ? "en" : "vi";

    public static string T(HttpContext ctx, string key)
    {
        var en = IsEnglish(ctx);
        return Map.TryGetValue(key, out var pair) ? (en ? pair.En : pair.Vi) : key;
    }

    // Razor-friendly extension helpers usable from any view via @Context.L("key") / Context.EN()
    public static string L(this HttpContext ctx, string key) => T(ctx, key);
    public static bool EN(this HttpContext ctx) => IsEnglish(ctx);

    private static readonly Dictionary<string, (string Vi, string En)> Map = new()
    {
        ["app.name"] = ("TechNet", "TechNet"),
        ["nav.home"] = ("Trang chủ", "Home"),
        ["nav.groups"] = ("Nhóm", "Groups"),
        ["nav.chat"] = ("Tin nhắn", "Messages"),
        ["nav.search"] = ("Tìm kiếm", "Search"),
        ["nav.admin"] = ("Quản trị", "Admin"),
        ["nav.profile"] = ("Trang cá nhân", "Profile"),
        ["nav.login"] = ("Đăng nhập", "Log in"),
        ["nav.register"] = ("Đăng ký", "Sign up"),
        ["nav.logout"] = ("Đăng xuất", "Log out"),
        ["search.placeholder"] = ("Tìm người dùng, nhóm, bài viết...", "Search people, groups, posts..."),

        ["composer.placeholder"] = ("Bạn đang nghĩ gì?", "What's on your mind?"),
        ["composer.photo"] = ("Ảnh/Video", "Photo/Video"),
        ["composer.post"] = ("Đăng", "Post"),
        ["composer.togroup"] = ("Đăng vào", "Post to"),
        ["composer.mywall"] = ("Trang chủ", "Home feed"),

        ["post.comments"] = ("bình luận", "comments"),
        ["post.comment"] = ("Bình luận", "Comment"),
        ["post.writeComment"] = ("Viết bình luận...", "Write a comment..."),
        ["post.edit"] = ("Sửa", "Edit"),
        ["post.delete"] = ("Xoá", "Delete"),
        ["post.deleteConfirm"] = ("Xoá bài viết này?", "Delete this post?"),
        ["post.send"] = ("Gửi", "Send"),
        ["post.noPosts"] = ("Chưa có bài viết nào.", "No posts yet."),
        ["feed.loadError"] = ("Không tải được bảng tin. Vui lòng kiểm tra máy chủ và thử lại.", "Couldn't load the feed. Please check the server and try again."),
        ["post.loadMore"] = ("Xem thêm", "Load more"),
        ["post.mediaFailed"] = ("Không tải được ảnh", "Media failed to load"),
        ["post.save"] = ("Lưu", "Save"),
        ["post.cancel"] = ("Huỷ", "Cancel"),

        ["groups.title"] = ("Nhóm", "Groups"),
        ["groups.mine"] = ("Nhóm của tôi", "My groups"),
        ["groups.discover"] = ("Khám phá nhóm", "Discover groups"),
        ["groups.create"] = ("Tạo nhóm", "Create group"),
        ["groups.join"] = ("Tham gia", "Join"),
        ["groups.leave"] = ("Rời nhóm", "Leave"),
        ["groups.members"] = ("thành viên", "members"),
        ["groups.membersTitle"] = ("Thành viên", "Members"),
        ["groups.name"] = ("Tên nhóm", "Group name"),
        ["groups.description"] = ("Mô tả", "Description"),
        ["groups.avatar"] = ("Ảnh đại diện (URL)", "Avatar (URL)"),
        ["groups.avatarUpload"] = ("Ảnh đại diện (chọn từ thiết bị)", "Avatar (choose from device)"),
        ["groups.avatarUrlOptional"] = ("Hoặc dán URL ảnh", "Or paste an image URL"),
        ["groups.edit"] = ("Sửa nhóm", "Edit group"),
        ["groups.delete"] = ("Xoá nhóm", "Delete group"),
        ["groups.kick"] = ("Xoá khỏi nhóm", "Remove"),
        ["groups.setAdmin"] = ("Đặt làm Admin", "Make admin"),
        ["groups.setMember"] = ("Đặt làm Member", "Make member"),
        ["groups.suggested"] = ("Gợi ý cho bạn", "Suggested for you"),
        ["groups.empty"] = ("Bạn chưa tham gia nhóm nào.", "You haven't joined any group."),

        ["profile.edit"] = ("Chỉnh sửa hồ sơ", "Edit profile"),
        ["profile.displayName"] = ("Tên hiển thị", "Display name"),
        ["profile.bio"] = ("Tiểu sử", "Bio"),
        ["profile.avatar"] = ("Ảnh đại diện", "Avatar"),
        ["profile.member_since"] = ("Tham gia từ", "Member since"),
        ["profile.posts"] = ("Bài viết", "Posts"),

        ["chat.title"] = ("Tin nhắn", "Messages"),
        ["chat.people"] = ("Mọi người", "People"),
        ["chat.groups"] = ("Nhóm", "Groups"),
        ["chat.placeholder"] = ("Nhập tin nhắn...", "Type a message..."),
        ["chat.pick"] = ("Chọn một cuộc trò chuyện để bắt đầu", "Pick a conversation to start"),
        ["chat.online"] = ("Đang hoạt động", "Online"),

        ["auth.login"] = ("Đăng nhập", "Log in"),
        ["auth.register"] = ("Tạo tài khoản", "Create account"),
        ["auth.email"] = ("Email", "Email"),
        ["auth.password"] = ("Mật khẩu", "Password"),
        ["auth.displayName"] = ("Tên hiển thị", "Display name"),
        ["auth.forgot"] = ("Quên mật khẩu?", "Forgot password?"),
        ["auth.noAccount"] = ("Chưa có tài khoản?", "Don't have an account?"),
        ["auth.haveAccount"] = ("Đã có tài khoản?", "Already have an account?"),
        ["auth.newPassword"] = ("Mật khẩu mới", "New password"),
        ["auth.resetToken"] = ("Mã đặt lại", "Reset token"),
        ["auth.reset"] = ("Đặt lại mật khẩu", "Reset password"),
        ["auth.sendReset"] = ("Gửi yêu cầu", "Send request"),
        ["auth.tagline"] = ("Kết nối cộng đồng công nghệ.", "Connect the tech community."),

        ["search.results"] = ("Kết quả tìm kiếm", "Search results"),
        ["search.people"] = ("Mọi người", "People"),
        ["search.groups"] = ("Nhóm", "Groups"),
        ["search.posts"] = ("Bài viết", "Posts"),
        ["search.empty"] = ("Không tìm thấy kết quả.", "No results found."),

        ["admin.dashboard"] = ("Bảng điều khiển", "Dashboard"),
        ["admin.users"] = ("Người dùng", "Users"),
        ["admin.posts"] = ("Bài viết", "Posts"),
        ["admin.comments"] = ("Bình luận", "Comments"),
        ["admin.groups"] = ("Nhóm", "Groups"),
        ["admin.postsPerDay"] = ("Bài viết mỗi ngày", "Posts per day"),
        ["admin.manageUsers"] = ("Quản lý người dùng", "Manage users"),
        ["admin.deleteUser"] = ("Xoá người dùng này?", "Delete this user?"),
    };
}
