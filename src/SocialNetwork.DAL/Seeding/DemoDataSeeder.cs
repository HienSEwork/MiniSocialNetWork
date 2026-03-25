using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using SocialNetwork.DAL.Entities;
using SocialNetwork.DAL.Enums;

namespace SocialNetwork.DAL.Seeding;

public static class DemoDataSeeder
{
    public const string AdminUserId = "00000000-0000-0000-0000-000000000001";
    public const string AliceUserId = "00000000-0000-0000-0000-000000000002";
    public const string BobUserId = "00000000-0000-0000-0000-000000000003";
    public const string CarolUserId = "00000000-0000-0000-0000-000000000004";

    private static readonly Guid EngineeringGroupId = Guid.Parse("10000000-0000-0000-0000-000000000001");
    private static readonly Guid DesignGroupId = Guid.Parse("10000000-0000-0000-0000-000000000002");
    private static readonly Guid FrontendGroupId = Guid.Parse("10000000-0000-0000-0000-000000000003");

    private static readonly Guid WelcomePostId = Guid.Parse("20000000-0000-0000-0000-000000000001");
    private static readonly Guid FeaturePostId = Guid.Parse("20000000-0000-0000-0000-000000000002");
    private static readonly Guid EngineeringPostId = Guid.Parse("20000000-0000-0000-0000-000000000003");
    private static readonly Guid DesignPostId = Guid.Parse("20000000-0000-0000-0000-000000000004");
    private static readonly Guid CommunityPostId = Guid.Parse("20000000-0000-0000-0000-000000000005");

    private static readonly Guid WelcomeCommentId = Guid.Parse("30000000-0000-0000-0000-000000000001");
    private static readonly Guid FeatureCommentId = Guid.Parse("30000000-0000-0000-0000-000000000002");

    private static readonly Guid WelcomeReactionId = Guid.Parse("40000000-0000-0000-0000-000000000001");
    private static readonly Guid FeatureReactionId = Guid.Parse("40000000-0000-0000-0000-000000000002");
    private static readonly Guid EngineeringReactionId = Guid.Parse("40000000-0000-0000-0000-000000000003");

    private static readonly Guid AdminAliceFriendshipId = Guid.Parse("50000000-0000-0000-0000-000000000001");
    private static readonly Guid AdminBobFriendshipId = Guid.Parse("50000000-0000-0000-0000-000000000002");
    private static readonly Guid AliceBobFriendshipId = Guid.Parse("50000000-0000-0000-0000-000000000003");

    private static readonly Guid PrivateMessageId = Guid.Parse("60000000-0000-0000-0000-000000000001");
    private static readonly Guid GroupMessageId = Guid.Parse("60000000-0000-0000-0000-000000000002");
    private static readonly Guid DesignMessageId = Guid.Parse("60000000-0000-0000-0000-000000000003");
    private static readonly Guid CarolMessageId = Guid.Parse("60000000-0000-0000-0000-000000000004");

    private static readonly Guid WelcomeNotificationId = Guid.Parse("70000000-0000-0000-0000-000000000001");
    private static readonly Guid MessageNotificationId = Guid.Parse("70000000-0000-0000-0000-000000000002");
    private static readonly Guid GroupNotificationId = Guid.Parse("70000000-0000-0000-0000-000000000003");

    private static readonly Guid AdminSavedFeaturePostId = Guid.Parse("80000000-0000-0000-0000-000000000001");
    private static readonly Guid AliceSavedWelcomePostId = Guid.Parse("80000000-0000-0000-0000-000000000002");

    private const string MediaRoot = "/media/demo";

    public static async Task SeedAsync(IServiceProvider serviceProvider)
    {
        await using var scope = serviceProvider.CreateAsyncScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();

        var admin = await EnsureUserAsync(
            userManager,
            AdminUserId,
            "admin@minisocial.local",
            "Admin!123",
            "Admin Demo",
            "Quản trị viên theo dõi tiến độ và luồng hoạt động của hệ thống.",
            $"{MediaRoot}/avatars/admin.jpg");

        var alice = await EnsureUserAsync(
            userManager,
            AliceUserId,
            "alice@minisocial.local",
            "User!123",
            "Alice Nguyen",
            "Người dùng thường xuyên cập nhật giao diện và trải nghiệm.",
            $"{MediaRoot}/avatars/alice.jpg");

        var bob = await EnsureUserAsync(
            userManager,
            BobUserId,
            "bob@minisocial.local",
            "User!123",
            "Bob Tran",
            "Thành viên tập trung backend, hoạt động nhiều trong chat và nhóm.",
            $"{MediaRoot}/avatars/bob.jpg");

        var carol = await EnsureUserAsync(
            userManager,
            CarolUserId,
            "carol@minisocial.local",
            "User!123",
            "Carol Pham",
            "Thành viên mới chuyên theo dõi trải nghiệm người dùng và kiểm thử chức năng.",
            $"{MediaRoot}/avatars/guest.jpg");

        await EnsureRolesAsync(roleManager, userManager, admin, alice, bob, carol);
        await EnsureGroupsAsync(dbContext, admin.Id, alice.Id, bob.Id, carol.Id);
        await EnsureFriendshipsAsync(dbContext, admin.Id, alice.Id, bob.Id);
        await EnsurePostsAsync(dbContext, admin.Id, alice.Id, bob.Id, carol.Id);
        await EnsureCommentsAsync(dbContext, bob.Id, alice.Id);
        await EnsureReactionsAsync(dbContext, admin.Id, alice.Id, bob.Id);
        await EnsureMessagesAsync(dbContext, admin.Id, alice.Id, bob.Id, carol.Id);
        await EnsureNotificationsAsync(dbContext, admin.Id, alice.Id, bob.Id);
        await EnsureSavedPostsAsync(dbContext, admin.Id, alice.Id);

        await dbContext.SaveChangesAsync();
    }

    private static async Task EnsureRolesAsync(
        RoleManager<IdentityRole> roleManager,
        UserManager<ApplicationUser> userManager,
        ApplicationUser admin,
        ApplicationUser alice,
        ApplicationUser bob,
        ApplicationUser carol)
    {
        await EnsureRoleAsync(roleManager, "Admin");
        await EnsureRoleAsync(roleManager, "User");

        if (!await userManager.IsInRoleAsync(admin, "Admin"))
        {
            await userManager.AddToRoleAsync(admin, "Admin");
        }

        if (!await userManager.IsInRoleAsync(alice, "User"))
        {
            await userManager.AddToRoleAsync(alice, "User");
        }

        if (!await userManager.IsInRoleAsync(bob, "User"))
        {
            await userManager.AddToRoleAsync(bob, "User");
        }

        if (!await userManager.IsInRoleAsync(carol, "User"))
        {
            await userManager.AddToRoleAsync(carol, "User");
        }
    }

    private static async Task EnsureRoleAsync(RoleManager<IdentityRole> roleManager, string roleName)
    {
        if (await roleManager.RoleExistsAsync(roleName))
        {
            return;
        }

        var result = await roleManager.CreateAsync(new IdentityRole(roleName));
        if (!result.Succeeded)
        {
            throw new InvalidOperationException($"Unable to seed role '{roleName}': {string.Join(", ", result.Errors.Select(error => error.Description))}");
        }
    }

    private static async Task EnsureGroupsAsync(ApplicationDbContext dbContext, string adminId, string aliceId, string bobId, string carolId)
    {
        var engineering = await dbContext.Groups.IgnoreQueryFilters().SingleOrDefaultAsync(group => group.Id == EngineeringGroupId);
        if (engineering is null)
        {
            engineering = new Group { Id = EngineeringGroupId };
            dbContext.Groups.Add(engineering);
        }

        engineering.Name = "Engineering Circle";
        engineering.Description = "Thảo luận kỹ thuật, tiến độ xử lý và trao đổi triển khai.";
        engineering.OwnerId = adminId;
        engineering.IsDeleted = false;

        var design = await dbContext.Groups.IgnoreQueryFilters().SingleOrDefaultAsync(group => group.Id == DesignGroupId);
        if (design is null)
        {
            design = new Group { Id = DesignGroupId };
            dbContext.Groups.Add(design);
        }

        design.Name = "Design Lab";
        design.Description = "Tập trung định hướng giao diện, nội dung và góp ý thiết kế.";
        design.OwnerId = aliceId;
        design.IsDeleted = false;

        var frontend = await dbContext.Groups.IgnoreQueryFilters().SingleOrDefaultAsync(group => group.Id == FrontendGroupId);
        if (frontend is null)
        {
            frontend = new Group { Id = FrontendGroupId };
            dbContext.Groups.Add(frontend);
        }

        frontend.Name = "Frontend Guild";
        frontend.Description = "Chia sẻ review UI, bug hiển thị và checklist hoàn thiện trải nghiệm người dùng.";
        frontend.OwnerId = carolId;
        frontend.IsDeleted = false;

        await EnsureGroupMemberAsync(dbContext, EngineeringGroupId, adminId, GroupRole.Owner);
        await EnsureGroupMemberAsync(dbContext, EngineeringGroupId, aliceId, GroupRole.Member);
        await EnsureGroupMemberAsync(dbContext, EngineeringGroupId, bobId, GroupRole.Member);
        await EnsureGroupMemberAsync(dbContext, DesignGroupId, aliceId, GroupRole.Owner);
        await EnsureGroupMemberAsync(dbContext, DesignGroupId, adminId, GroupRole.Member);
        await EnsureGroupMemberAsync(dbContext, FrontendGroupId, carolId, GroupRole.Owner);
        await EnsureGroupMemberAsync(dbContext, FrontendGroupId, aliceId, GroupRole.Member);
    }

    private static async Task EnsureFriendshipsAsync(ApplicationDbContext dbContext, string adminId, string aliceId, string bobId)
    {
        await EnsureFriendshipAsync(dbContext, AdminAliceFriendshipId, adminId, aliceId, FriendshipStatus.Accepted);
        await EnsureFriendshipAsync(dbContext, AdminBobFriendshipId, adminId, bobId, FriendshipStatus.Accepted);
        await EnsureFriendshipAsync(dbContext, AliceBobFriendshipId, aliceId, bobId, FriendshipStatus.Accepted);
    }

    private static async Task EnsurePostsAsync(ApplicationDbContext dbContext, string adminId, string aliceId, string bobId, string carolId)
    {
        await EnsurePostAsync(
            dbContext,
            WelcomePostId,
            adminId,
            null,
            "Đã đăng bản cập nhật công việc tuần này. Mọi người xem nhanh trên bảng tin rồi tiếp tục thảo luận chi tiết trong nhóm.",
            $"{MediaRoot}/posts/feed-1.jpg",
            MediaType.Image);

        await EnsurePostAsync(
            dbContext,
            FeaturePostId,
            aliceId,
            null,
            "Giao diện header, khoảng cách và thẻ nội dung vừa được cập nhật. Nhờ mọi người kiểm tra lại trên desktop và mobile.",
            $"{MediaRoot}/posts/feed-2.jpg",
            MediaType.Image);

        await EnsurePostAsync(
            dbContext,
            EngineeringPostId,
            bobId,
            EngineeringGroupId,
            "API đã ổn định. Mọi ghi chú triển khai tiếp tục trao đổi trong nhóm kỹ thuật để dễ theo dõi.",
            $"{MediaRoot}/groups/engineering.jpg",
            MediaType.Image);

        await EnsurePostAsync(
            dbContext,
            DesignPostId,
            aliceId,
            DesignGroupId,
            "Moodboard cho theme xanh tương phản đã được cập nhật. Mọi người xem lại card, icon và chuyển động trước khi chốt.",
            $"{MediaRoot}/groups/design.jpg",
            MediaType.Image);

        await EnsurePostAsync(
            dbContext,
            CommunityPostId,
            carolId,
            null,
            "Mình vừa tổng hợp lại danh sách lỗi font, route và responsive để mọi người test nhanh trong vòng tiếp theo.",
            $"{MediaRoot}/posts/feed-3.jpg",
            MediaType.Image);
    }

    private static async Task EnsureCommentsAsync(ApplicationDbContext dbContext, string bobId, string aliceId)
    {
        await EnsureCommentAsync(
            dbContext,
            WelcomeCommentId,
            WelcomePostId,
            bobId,
            "Mình đã kiểm tra luồng chính. Feed và thông báo đang chạy ổn.");

        await EnsureCommentAsync(
            dbContext,
            FeatureCommentId,
            FeaturePostId,
            aliceId,
            "Nhờ kiểm tra lại màn đăng nhập sau lượt chỉnh giao diện mới nhất.");
    }

    private static async Task EnsureReactionsAsync(ApplicationDbContext dbContext, string adminId, string aliceId, string bobId)
    {
        await EnsureReactionAsync(dbContext, WelcomeReactionId, WelcomePostId, aliceId, ReactionType.Love);
        await EnsureReactionAsync(dbContext, FeatureReactionId, FeaturePostId, bobId, ReactionType.Like);
        await EnsureReactionAsync(dbContext, EngineeringReactionId, EngineeringPostId, adminId, ReactionType.Haha);
    }

    private static async Task EnsureMessagesAsync(ApplicationDbContext dbContext, string adminId, string aliceId, string bobId, string carolId)
    {
        await EnsureMessageAsync(
            dbContext,
            PrivateMessageId,
            aliceId,
            bobId,
            null,
            "Bạn xem giúp khoảng cách mới của feed trước giờ nghỉ trưa nhé?",
            false);

        await EnsureMessageAsync(
            dbContext,
            GroupMessageId,
            adminId,
            null,
            EngineeringGroupId,
            "Ghi chú triển khai được cập nhật trong luồng này. Nếu có blocker thì báo ngay tại đây.",
            true);

        await EnsureMessageAsync(
            dbContext,
            DesignMessageId,
            aliceId,
            null,
            DesignGroupId,
            "Mình vừa tải lên các phương án cover mới. Mọi người xem lại trước khi chốt.",
            true);

        await EnsureMessageAsync(
            dbContext,
            CarolMessageId,
            carolId,
            adminId,
            null,
            "Mình vừa rà lại checklist và sẽ test thêm flow lưu bài viết trong chiều nay.",
            false);
    }

    private static async Task EnsureNotificationsAsync(ApplicationDbContext dbContext, string adminId, string aliceId, string bobId)
    {
        await EnsureNotificationAsync(
            dbContext,
            WelcomeNotificationId,
            aliceId,
            adminId,
            NotificationType.NewPost,
            "Bài đăng mới",
            "Admin Demo vừa đăng một cập nhật trên bảng tin.",
            $"/posts/{WelcomePostId}",
            false);

        await EnsureNotificationAsync(
            dbContext,
            MessageNotificationId,
            bobId,
            aliceId,
            NotificationType.NewMessage,
            "Tin nhắn mới",
            "Alice vừa gửi cho bạn một tin nhắn riêng.",
            "/chat",
            false);

        await EnsureNotificationAsync(
            dbContext,
            GroupNotificationId,
            adminId,
            aliceId,
            NotificationType.NewPost,
            "Hoạt động nhóm",
            "Design Lab có cập nhật mới đang chờ bạn xem.",
            $"/groups/{DesignGroupId}",
            true);
    }

    private static async Task EnsureSavedPostsAsync(ApplicationDbContext dbContext, string adminId, string aliceId)
    {
        await EnsureSavedPostAsync(dbContext, AdminSavedFeaturePostId, adminId, FeaturePostId);
        await EnsureSavedPostAsync(dbContext, AliceSavedWelcomePostId, aliceId, WelcomePostId);
    }

    private static async Task<ApplicationUser> EnsureUserAsync(
        UserManager<ApplicationUser> userManager,
        string userId,
        string email,
        string password,
        string displayName,
        string bio,
        string avatarUrl)
    {
        var user = await userManager.Users.FirstOrDefaultAsync(existingUser => existingUser.Email == email);
        if (user is null)
        {
            user = new ApplicationUser
            {
                Id = userId,
                UserName = email,
                Email = email,
                EmailConfirmed = true
            };

            var result = await userManager.CreateAsync(user, password);
            if (!result.Succeeded)
            {
                throw new InvalidOperationException($"Unable to seed demo user '{email}': {string.Join(", ", result.Errors.Select(error => error.Description))}");
            }
        }

        user.DisplayName = displayName;
        user.Bio = bio;
        user.AvatarUrl = avatarUrl;
        user.EmailConfirmed = true;
        user.UserName = email;
        user.Email = email;

        var updateResult = await userManager.UpdateAsync(user);
        if (!updateResult.Succeeded)
        {
            throw new InvalidOperationException($"Unable to update demo user '{email}': {string.Join(", ", updateResult.Errors.Select(error => error.Description))}");
        }

        return user;
    }

    private static async Task EnsureGroupMemberAsync(ApplicationDbContext dbContext, Guid groupId, string userId, GroupRole role)
    {
        var member = await dbContext.GroupMembers.IgnoreQueryFilters()
            .SingleOrDefaultAsync(existingMember => existingMember.GroupId == groupId && existingMember.UserId == userId);

        if (member is null)
        {
            dbContext.GroupMembers.Add(new GroupMember
            {
                GroupId = groupId,
                UserId = userId,
                Role = role
            });
            return;
        }

        member.Role = role;
    }

    private static async Task EnsureFriendshipAsync(
        ApplicationDbContext dbContext,
        Guid friendshipId,
        string requesterId,
        string addresseeId,
        FriendshipStatus status)
    {
        var friendship = await dbContext.Friendships.SingleOrDefaultAsync(existingFriendship => existingFriendship.Id == friendshipId);
        if (friendship is null)
        {
            friendship = new Friendship { Id = friendshipId };
            dbContext.Friendships.Add(friendship);
        }

        friendship.RequesterId = requesterId;
        friendship.AddresseeId = addresseeId;
        friendship.Status = status;
    }

    private static async Task EnsurePostAsync(
        ApplicationDbContext dbContext,
        Guid postId,
        string userId,
        Guid? groupId,
        string content,
        string mediaUrl,
        MediaType mediaType)
    {
        var post = await dbContext.Posts.IgnoreQueryFilters().SingleOrDefaultAsync(existingPost => existingPost.Id == postId);
        if (post is null)
        {
            post = new Post { Id = postId };
            dbContext.Posts.Add(post);
        }

        post.UserId = userId;
        post.GroupId = groupId;
        post.Content = content;
        post.MediaUrl = mediaUrl;
        post.MediaType = mediaType;
        post.IsDeleted = false;
    }

    private static async Task EnsureCommentAsync(ApplicationDbContext dbContext, Guid commentId, Guid postId, string userId, string content)
    {
        var comment = await dbContext.Comments.IgnoreQueryFilters().SingleOrDefaultAsync(existingComment => existingComment.Id == commentId);
        if (comment is null)
        {
            comment = new Comment { Id = commentId };
            dbContext.Comments.Add(comment);
        }

        comment.PostId = postId;
        comment.UserId = userId;
        comment.Content = content;
        comment.IsDeleted = false;
    }

    private static async Task EnsureReactionAsync(ApplicationDbContext dbContext, Guid reactionId, Guid postId, string userId, ReactionType reactionType)
    {
        var reaction = await dbContext.Reactions.SingleOrDefaultAsync(existingReaction => existingReaction.Id == reactionId);
        if (reaction is null)
        {
            reaction = new Reaction { Id = reactionId };
            dbContext.Reactions.Add(reaction);
        }

        reaction.PostId = postId;
        reaction.UserId = userId;
        reaction.Type = reactionType;
    }

    private static async Task EnsureMessageAsync(
        ApplicationDbContext dbContext,
        Guid messageId,
        string senderId,
        string? receiverId,
        Guid? groupId,
        string content,
        bool isGroupMessage)
    {
        var message = await dbContext.Messages.SingleOrDefaultAsync(existingMessage => existingMessage.Id == messageId);
        if (message is null)
        {
            message = new Message { Id = messageId };
            dbContext.Messages.Add(message);
        }

        message.SenderId = senderId;
        message.ReceiverId = receiverId;
        message.GroupId = groupId;
        message.Content = content;
        message.IsGroupMessage = isGroupMessage;
    }

    private static async Task EnsureNotificationAsync(
        ApplicationDbContext dbContext,
        Guid notificationId,
        string userId,
        string actorId,
        NotificationType notificationType,
        string title,
        string messageText,
        string link,
        bool isRead)
    {
        var notification = await dbContext.Notifications.SingleOrDefaultAsync(existingNotification => existingNotification.Id == notificationId);
        if (notification is null)
        {
            notification = new Notification { Id = notificationId };
            dbContext.Notifications.Add(notification);
        }

        notification.UserId = userId;
        notification.ActorId = actorId;
        notification.Type = notificationType;
        notification.Title = title;
        notification.Message = messageText;
        notification.Link = link;
        notification.IsRead = isRead;
    }

    private static async Task EnsureSavedPostAsync(ApplicationDbContext dbContext, Guid savedPostId, string userId, Guid postId)
    {
        var savedPost = await dbContext.SavedPosts.SingleOrDefaultAsync(existingSavedPost => existingSavedPost.Id == savedPostId);
        if (savedPost is null)
        {
            savedPost = new SavedPost { Id = savedPostId };
            dbContext.SavedPosts.Add(savedPost);
        }

        savedPost.UserId = userId;
        savedPost.PostId = postId;
    }
}
