using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using MiniSocialNetwork.Domain.Entities;
using MiniSocialNetwork.Domain.Enums;

namespace MiniSocialNetwork.Infrastructure.Persistence;

public static class DemoDataSeeder
{
    private const string Password = "Password123!";
    private const string EmailDomain = "minisocial.local";

    public static async Task SeedAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<AppUser>>();

        await context.Database.MigrateAsync();

        var users = await EnsureUsersAsync(userManager);
        await EnsureAchievementDefinitionsAsync(context);
        await EnsureGroupsAndPostsAsync(context, users);
        await EnsureChatMessagesAsync(context, users);
        await EnsureStoriesAsync(context, users);
        await EnsurePortfoliosAsync(context, users);
        await EnsureMarketplaceAsync(context, users);
    }

    private static async Task<List<AppUser>> EnsureUsersAsync(UserManager<AppUser> userManager)
    {
        var users = new List<AppUser>();
        for (var i = 1; i <= 30; i++)
        {
            var email = $"demo{i:00}@{EmailDomain}";
            var user = await userManager.FindByEmailAsync(email);
            if (user == null)
            {
                user = new AppUser
                {
                    UserName = email,
                    Email = email,
                    DisplayName = DemoNames[i - 1],
                    Bio = DemoBios[(i - 1) % DemoBios.Length],
                    AvatarUrl = $"https://api.dicebear.com/9.x/initials/png?seed={Uri.EscapeDataString(DemoNames[i - 1])}",
                    EmailConfirmed = true,
                    CreatedDate = DateTime.UtcNow.AddDays(-45 + i),
                    IsDeleted = false
                };

                var result = await userManager.CreateAsync(user, Password);
                if (!result.Succeeded)
                    throw new InvalidOperationException(string.Join("; ", result.Errors.Select(e => e.Description)));

                await userManager.AddToRoleAsync(user, "User");
            }
            else
            {
                user.DisplayName = DemoNames[i - 1];
                user.Bio = DemoBios[(i - 1) % DemoBios.Length];
                await userManager.UpdateAsync(user);
            }

            users.Add(user);
        }

        return users;
    }

    private static async Task EnsureAchievementDefinitionsAsync(AppDbContext context)
    {
        var definitions = new[]
        {
            new AchievementDefinition { Code = "first-post", Name = "Bài viết đầu tiên", Description = "Đăng bài đầu tiên trong cộng đồng.", Icon = "edit_note", SortOrder = 1, IsActive = true },
            new AchievementDefinition { Code = "first-story", Name = "Story đầu tiên", Description = "Chia sẻ story đầu tiên trên TechNet.", Icon = "auto_awesome", SortOrder = 2, IsActive = true },
            new AchievementDefinition { Code = "joined-group", Name = "Thành viên cộng đồng", Description = "Tham gia ít nhất một nhóm.", Icon = "groups", SortOrder = 3, IsActive = true },
            new AchievementDefinition { Code = "portfolio-ready", Name = "Portfolio sẵn sàng", Description = "Hoàn thiện vai trò, kỹ năng hoặc project nổi bật.", Icon = "workspaces", SortOrder = 4, IsActive = true },
            new AchievementDefinition { Code = "got-reaction", Name = "Được quan tâm", Description = "Bài viết của bạn đã nhận reaction.", Icon = "favorite", SortOrder = 5, IsActive = true }
        };

        foreach (var definition in definitions)
        {
            var existing = await context.AchievementDefinitions.FindAsync(definition.Code);
            if (existing == null)
            {
                await context.AchievementDefinitions.AddAsync(definition);
            }
            else
            {
                existing.Name = definition.Name;
                existing.Description = definition.Description;
                existing.Icon = definition.Icon;
                existing.SortOrder = definition.SortOrder;
                existing.IsActive = true;
            }
        }
        await context.SaveChangesAsync();
    }

    private static async Task EnsureGroupsAndPostsAsync(AppDbContext context, IReadOnlyList<AppUser> users)
    {
        for (var i = 0; i < GroupNames.Length; i++)
        {
            var existing = await context.Groups
                .FirstOrDefaultAsync(g => g.Name == GroupNames[i] || g.Name == OldGroupNames[i]);
            if (existing == null) continue;
            existing.Name = GroupNames[i];
            existing.Description = GroupDescriptions[i];
            existing.AvatarUrl = GroupAvatarAssets[i];
        }
        await context.SaveChangesAsync();

        var existingGroupNames = await context.Groups.Select(g => g.Name).ToListAsync();
        var newGroups = new List<Group>();
        for (var i = 0; i < 20; i++)
        {
            if (existingGroupNames.Contains(GroupNames[i])) continue;

            var owner = users[i % users.Count];
            var group = new Group
            {
                Id = Guid.NewGuid(),
                Name = GroupNames[i],
                Description = GroupDescriptions[i],
                AvatarUrl = GroupAvatarAssets[i],
                OwnerId = owner.Id,
                CreatedDate = DateTime.UtcNow.AddDays(-30 + i),
                IsDeleted = false
            };

            group.Members.Add(new GroupMember
            {
                GroupId = group.Id,
                UserId = owner.Id,
                Role = (int)GroupRole.Owner,
                JoinedDate = group.CreatedDate
            });

            foreach (var member in users.Skip(i % 6).Take(12))
            {
                if (member.Id == owner.Id) continue;
                group.Members.Add(new GroupMember
                {
                    GroupId = group.Id,
                    UserId = member.Id,
                    Role = (int)GroupRole.Member,
                    JoinedDate = group.CreatedDate.AddDays(1)
                });
            }

            newGroups.Add(group);
        }

        if (newGroups.Count > 0)
        {
            await context.Groups.AddRangeAsync(newGroups);
            await context.SaveChangesAsync();
        }

        var groups = await context.Groups
            .Where(g => GroupNames.Contains(g.Name) && !g.IsDeleted)
            .Include(g => g.Members)
            .ToListAsync();

        var seedGroupIds = groups.Select(g => g.Id).ToArray();
        var seedUserIds = users.Select(u => u.Id).ToArray();
        var existingPosts = await context.Posts
            .Where(p => p.GroupId.HasValue && seedGroupIds.Contains(p.GroupId.Value) && seedUserIds.Contains(p.UserId) && !p.IsDeleted)
            .OrderBy(p => p.CreatedDate)
            .ToListAsync();

        for (var i = 0; i < existingPosts.Count; i++)
        {
            existingPosts[i].Content = PostBodies[i % PostBodies.Length];
            if (i % 2 == 0)
            {
                existingPosts[i].MediaUrl = DemoImages[i % DemoImages.Length];
                existingPosts[i].MediaType = 1;
            }
            else
            {
                existingPosts[i].MediaUrl = null;
                existingPosts[i].MediaType = 0;
            }
        }

        var existingPostIds = existingPosts.Select(p => p.Id).ToArray();
        var existingComments = await context.Comments
            .Where(c => existingPostIds.Contains(c.PostId) && !c.IsDeleted)
            .OrderBy(c => c.CreatedDate)
            .ToListAsync();

        for (var i = 0; i < existingComments.Count; i++)
        {
            existingComments[i].Content = CommentBodies[i % CommentBodies.Length];
        }

        await context.SaveChangesAsync();
        await EnsureEngagementAsync(context, users, existingPosts);

        var existingSeedPosts = existingPosts.Count;
        if (existingSeedPosts >= 120) return;

        var posts = new List<Post>();
        foreach (var group in groups)
        {
            var memberIds = group.Members.Select(m => m.UserId).ToArray();
            for (var i = 0; i < 6; i++)
            {
                var authorId = memberIds[(i + group.Name.Length) % memberIds.Length];
                posts.Add(new Post
                {
                    Id = Guid.NewGuid(),
                    GroupId = group.Id,
                    UserId = authorId,
                    Content = PostBodies[(i + group.Name.Length) % PostBodies.Length],
                    MediaUrl = i % 2 == 0 ? DemoImages[(i + group.Name.Length) % DemoImages.Length] : null,
                    MediaType = i % 2 == 0 ? 1 : 0,
                    CreatedDate = DateTime.UtcNow.AddHours(-(posts.Count + 1) * 3),
                    IsDeleted = false
                });
            }
        }

        await context.Posts.AddRangeAsync(posts);
        await context.SaveChangesAsync();
        await EnsureEngagementAsync(context, users, posts);
    }

    private static async Task EnsureEngagementAsync(AppDbContext context, IReadOnlyList<AppUser> users, IReadOnlyList<Post> posts)
    {
        if (posts.Count == 0) return;
        var comments = new List<Comment>();
        var reactions = new List<Reaction>();
        foreach (var post in posts)
        {
            var existingCommentCount = await context.Comments.CountAsync(c => c.PostId == post.Id && !c.IsDeleted);
            for (var i = existingCommentCount; i < 5; i++)
            {
                var user = users[(i + post.Content.Length) % users.Count];
                if (user.Id == post.UserId) user = users[(i + 7) % users.Count];
                comments.Add(new Comment
                {
                    Id = Guid.NewGuid(),
                    PostId = post.Id,
                    UserId = user.Id,
                    Content = CommentBodies[(i + post.Content.Length) % CommentBodies.Length],
                    CreatedDate = post.CreatedDate.AddMinutes(15 + i * 10),
                    IsDeleted = false
                });
            }

            var reactionUsers = users
                .Where(u => u.Id != post.UserId)
                .Skip(post.Content.Length % 5)
                .Take(14)
                .ToList();
            var existingReactions = await context.Reactions
                .Where(r => r.PostId == post.Id)
                .ToListAsync();
            foreach (var user in reactionUsers)
            {
                var reaction = existingReactions.FirstOrDefault(r => r.UserId == user.Id);
                if (reaction == null)
                {
                    reactions.Add(new Reaction
                    {
                        Id = Guid.NewGuid(),
                        PostId = post.Id,
                        UserId = user.Id,
                        Type = (post.Content.Length + user.DisplayName.Length) % 3 + 1,
                        CreatedDate = post.CreatedDate.AddMinutes(5 + reactions.Count % 20)
                    });
                }
                else
                {
                    reaction.Type = (post.Content.Length + user.DisplayName.Length) % 3 + 1;
                }
            }
        }

        if (comments.Count > 0) await context.Comments.AddRangeAsync(comments);
        if (reactions.Count > 0) await context.Reactions.AddRangeAsync(reactions);
        await context.SaveChangesAsync();
    }

    private static async Task EnsureChatMessagesAsync(AppDbContext context, IReadOnlyList<AppUser> users)
    {
        var groups = await context.Groups
            .Where(g => GroupNames.Contains(g.Name) && !g.IsDeleted)
            .OrderBy(g => g.CreatedDate)
            .Take(12)
            .ToListAsync();
        if (groups.Count == 0 || users.Count < 2) return;

        var seedUserIds = users.Select(u => u.Id).ToArray();
        var groupIds = groups.Select(g => g.Id).ToArray();
        var existingGroupMessages = await context.Messages.CountAsync(m =>
            m.IsGroupMessage &&
            m.GroupId.HasValue &&
            groupIds.Contains(m.GroupId.Value) &&
            seedUserIds.Contains(m.SenderId));
        var messages = new List<Message>();

        if (existingGroupMessages < 72)
        {
            for (var g = 0; g < groups.Count; g++)
            {
                for (var i = 0; i < 6; i++)
                {
                    messages.Add(new Message
                    {
                        Id = Guid.NewGuid(),
                        GroupId = groups[g].Id,
                        SenderId = users[(g + i) % users.Count].Id,
                        Content = ChatBodies[(g * 6 + i) % ChatBodies.Length],
                        IsGroupMessage = true,
                        CreatedDate = DateTime.UtcNow.AddHours(-(groups.Count * 6 - (g * 6 + i)))
                    });
                }
            }
        }

        var existingPrivateMessages = await context.Messages.CountAsync(m =>
            !m.IsGroupMessage &&
            seedUserIds.Contains(m.SenderId) &&
            m.ReceiverId != null &&
            seedUserIds.Contains(m.ReceiverId));

        if (existingPrivateMessages < 40)
        {
            for (var i = 0; i < 40; i++)
            {
                var sender = users[i % users.Count];
                var receiver = users[(i + 9) % users.Count];
                messages.Add(new Message
                {
                    Id = Guid.NewGuid(),
                    SenderId = sender.Id,
                    ReceiverId = receiver.Id,
                    Content = PrivateChatBodies[i % PrivateChatBodies.Length],
                    IsGroupMessage = false,
                    CreatedDate = DateTime.UtcNow.AddMinutes(-(160 - i * 3))
                });
            }
        }

        if (messages.Count == 0) return;
        await context.Messages.AddRangeAsync(messages);
        await context.SaveChangesAsync();
    }

    private static async Task EnsureStoriesAsync(AppDbContext context, IReadOnlyList<AppUser> users)
    {
        if (users.Count == 0) return;

        var now = DateTime.UtcNow;
        var storyUsers = users.Take(16).ToList();
        for (var i = 0; i < StoryBodies.Length; i++)
        {
            var user = storyUsers[i % storyUsers.Count];
            var content = StoryBodies[i];
            var story = await context.Stories.FirstOrDefaultAsync(s =>
                s.UserId == user.Id &&
                s.Content == content);

            if (story == null)
            {
                story = new Story
                {
                    Id = Guid.NewGuid(),
                    UserId = user.Id,
                    Content = content,
                    MediaUrl = i % 3 == 0 ? DemoImages[i % DemoImages.Length] : null,
                    MediaType = i % 3 == 0 ? 1 : 0,
                    CreatedDate = now.AddMinutes(-(i + 1) * 23),
                    ExpiresAt = now.AddHours(24).AddMinutes(-i * 23),
                    IsDeleted = false
                };
                await context.Stories.AddAsync(story);
            }
            else
            {
                story.MediaUrl = i % 3 == 0 ? DemoImages[i % DemoImages.Length] : null;
                story.MediaType = i % 3 == 0 ? 1 : 0;
                story.CreatedDate = now.AddMinutes(-(i + 1) * 23);
                story.ExpiresAt = now.AddHours(24).AddMinutes(-i * 23);
                story.IsDeleted = false;
                story.UpdatedDate = now;
            }
        }

        await context.SaveChangesAsync();
    }

    private static async Task EnsurePortfoliosAsync(AppDbContext context, IReadOnlyList<AppUser> users)
    {
        for (var i = 0; i < users.Count; i++)
        {
            var user = users[i];
            var portfolio = await context.UserPortfolios.FirstOrDefaultAsync(item => item.UserId == user.Id);
            if (portfolio == null)
            {
                portfolio = new UserPortfolio { UserId = user.Id };
                await context.UserPortfolios.AddAsync(portfolio);
            }

            portfolio.Title = PortfolioTitles[i % PortfolioTitles.Length];
            portfolio.Bio = PortfolioBios[i % PortfolioBios.Length];
            portfolio.Skills = PortfolioSkills[i % PortfolioSkills.Length];
            portfolio.GithubUrl = $"https://github.com/demo-tech-{i + 1:00}";
            portfolio.WebsiteUrl = $"https://portfolio-demo-{i + 1:00}.local";
            portfolio.Location = i % 2 == 0 ? "Ha Noi" : "Ho Chi Minh City";
            portfolio.FeaturedProjectName = PortfolioProjects[i % PortfolioProjects.Length];
            portfolio.FeaturedProjectUrl = $"https://github.com/demo-tech-{i + 1:00}/featured-project";
            portfolio.UpdatedDate = DateTime.UtcNow.AddDays(-i);
        }

        await context.SaveChangesAsync();
    }

    private static async Task EnsureMarketplaceAsync(AppDbContext context, IReadOnlyList<AppUser> users)
    {
        if (users.Count == 0) return;
        for (var i = 0; i < MarketplaceTitles.Length; i++)
        {
            var seller = users[i % Math.Min(users.Count, 12)];
            var title = MarketplaceTitles[i];
            var item = await context.MarketplaceItems.FirstOrDefaultAsync(product =>
                product.SellerId == seller.Id && product.Title == title);
            if (item == null)
            {
                item = new MarketplaceItem
                {
                    Id = Guid.NewGuid(),
                    SellerId = seller.Id,
                    Title = title,
                    CreatedDate = DateTime.UtcNow.AddHours(-(i + 1) * 4)
                };
                await context.MarketplaceItems.AddAsync(item);
            }

            item.Description = MarketplaceDescriptions[i % MarketplaceDescriptions.Length];
            item.Price = MarketplacePrices[i % MarketplacePrices.Length];
            item.Category = MarketplaceCategories[i % MarketplaceCategories.Length];
            item.Condition = i % 4 == 0 ? "Mới" : "Đã sử dụng";
            item.MediaUrl = DemoImages[i % DemoImages.Length];
            item.Status = i % 5 == 0 ? 1 : 0;
            item.UpdatedDate = DateTime.UtcNow.AddHours(-i);
        }
        await context.SaveChangesAsync();
    }

    private static readonly string[] DemoNames =
    [
        "An Nguyễn", "Bình Trần", "Chi Lê", "Dũng Phạm", "Em Võ", "Giang Đỗ",
        "Hạnh Mai", "Khoa Hồ", "Linh Đặng", "Minh Bùi", "Nam Cao", "Oanh Vũ",
        "Phúc Lâm", "Quyên Đào", "Sơn Lý", "Thảo Trương", "Uy Nguyễn", "Vy Phan",
        "Xuân Hà", "Yến Huỳnh", "Bảo Tạ", "Cẩm Lưu", "Đại Ngô", "Hân Phùng",
        "Kiệt Tô", "Lan Đinh", "Mỹ Châu", "Nhi Dương", "Phong La", "Tuấn Thái"
    ];

    private static readonly string[] DemoBios =
    [
        "Theo dõi AI, laptop và những công cụ giúp làm việc nhanh hơn.",
        "Thích build PC, thử gear mới và ghi lại trải nghiệm thật.",
        "Quan tâm sản phẩm số, bảo mật, hiệu năng và cộng đồng công nghệ.",
        "Hay chia sẻ chuyện đi làm, setup góc máy và các mẹo học tech."
    ];

    private static readonly string[] GroupNames =
    [
        "AI Lab Việt Nam", "Build PC & Workstation", "Laptop Creator Hub", "Gear Desk Setup",
        "GPU & Gaming Tech", "DevOps Cloud Notes", "Data Analyst Việt", "Cybersecurity Daily",
        "Flutter Mobile Pro", ".NET Backend Guild", "Productivity Tools", "Startup AI Garage",
        "Prompt Engineering", "Machine Learning Lab", "Web Performance", "Smart Home & IoT",
        "Game Dev Corner", "Open Source Việt", "Tech News Radar", "Sinh viên IT"
    ];

    private static readonly string[] GroupAvatarAssets =
    [
        "assets/images/group_ai_lab.png",
        "assets/images/group_pc_workstation.png",
        "assets/images/group_laptop_creator.png",
        "assets/images/group_gear_setup.png",
        "assets/images/group_gpu_gaming.png",
        "assets/images/group_devops_cloud.png",
        "assets/images/group_data_analyst.png",
        "assets/images/group_cybersecurity.png",
        "assets/images/group_flutter_mobile.png",
        "assets/images/group_dotnet_backend.png",
        "assets/images/group_productivity.png",
        "assets/images/group_startup_ai.png",
        "assets/images/group_prompt_engineering.png",
        "assets/images/group_machine_learning.png",
        "assets/images/group_web_performance.png",
        "assets/images/group_iot.png",
        "assets/images/group_game_dev.png",
        "assets/images/group_open_source.png",
        "assets/images/group_tech_news.png",
        "assets/images/group_students_it.png"
    ];

    private static readonly string[] OldGroupNames =
    [
        "Lap trinh .NET", "Flutter Viet Nam", "UI UX hang ngay", "Hoc tieng Anh",
        "Sach va ca phe", "Chay bo buoi sang", "Nhiep anh mobile", "Startup Garage",
        "Du lich tu tuc", "An ngon tai nha", "Machine Learning Lab", "Game Dev Corner",
        "Quan ly du an", "Freelancer Hub", "Am nhac cuoi ngay", "Phim hay cuoi tuan",
        "Suc khoe tinh than", "Data Analyst Viet", "DevOps Notes", "Sinh vien IT"
    ];

    private static readonly string[] GroupDescriptions =
    [
        "Tin mới về mô hình AI, agent, RAG và cách đưa AI vào sản phẩm thật.",
        "Trao đổi cấu hình CPU, main, RAM, SSD, tản nhiệt và nguồn cho máy làm việc.",
        "Review laptop cho developer, designer, video editor và người làm AI local.",
        "Chia sẻ bàn làm việc, bàn phím cơ, chuột, màn hình, dock và audio.",
        "Cập nhật GPU, handheld PC, công nghệ gaming và tối ưu hiệu năng.",
        "Ghi chú về CI/CD, Docker, Kubernetes, cloud cost và quan sát hệ thống.",
        "SQL, dashboard, BI, data pipeline và câu chuyện dữ liệu trong doanh nghiệp.",
        "Tin bảo mật, passwordless, zero trust, phishing và cách tự bảo vệ tài khoản.",
        "Flutter, Dart, package hay và kinh nghiệm build app mượt trên nhiều nền tảng.",
        "ASP.NET Core, kiến trúc backend, API, auth và tối ưu database.",
        "Công cụ giúp làm việc nhanh hơn: note, automation, AI assistant và workflow.",
        "Nơi thử nghiệm ý tưởng startup dùng AI, market validation và go-to-market.",
        "Prompt, eval, system instruction và kinh nghiệm dùng AI có kiểm soát.",
        "Đọc paper, fine-tune, vector database và triển khai mô hình machine learning.",
        "Core Web Vitals, caching, rendering, bundle size và trải nghiệm người dùng.",
        "Thiết bị thông minh, automation trong nhà, sensor và bảo mật IoT.",
        "Gameplay, engine, asset pipeline, đồ họa realtime và công cụ làm game.",
        "Dự án mã nguồn mở, contribution, license và câu chuyện maintain dự án.",
        "Radar tin công nghệ mỗi ngày: AI, chip, thiết bị, nền tảng và chính sách.",
        "Nơi sinh viên IT hỏi bài, xin lộ trình học, tìm team và chia sẻ đồ án."
    ];

    private static readonly string[] PostBodies =
    [
        "Mình vừa thử chạy một workflow RAG nhỏ cho tài liệu nội bộ. Điểm bất ngờ là phần chunking ảnh hưởng chất lượng trả lời nhiều hơn cả model đang dùng.",
        "Có tin các hãng đang đẩy mạnh laptop AI PC với NPU riêng. Mình tò mò liệu dev bình thường có hưởng lợi ngay không hay vẫn chủ yếu là GPU/cloud.",
        "Hôm nay nâng RAM từ 16GB lên 32GB, Android Studio, Docker và trình duyệt bớt giật hẳn. Nếu làm mobile hoặc backend local thì đây vẫn là nâng cấp đáng tiền.",
        "Mình đổi sang màn 27 inch 2K 120Hz cho code và đọc log. Không phải gear đắt nhất, nhưng mắt đỡ mỏi rõ sau vài ngày làm việc dài.",
        "Vừa so sánh Copilot, ChatGPT và một local model nhỏ cho task refactor. Local chạy ổn với dữ liệu nhạy cảm, nhưng vẫn cần prompt rất rõ và test kỹ.",
        "Có ai đang dùng bàn phím low-profile để code cả ngày không? Mình thích cảm giác nhẹ tay nhưng vẫn phân vân vì layout compact dễ bấm nhầm phím tắt.",
        "Mình gom checklist bảo mật cá nhân: bật 2FA, dùng password manager, tách email chính/phụ, và kiểm tra quyền app mỗi tháng một lần.",
        "Thử deploy một service .NET lên container mới thấy health check và logging quan trọng hơn mình tưởng. Lỗi nhỏ mà không có log thì tìm rất mệt.",
        "Tin chip mới năm nay tập trung nhiều vào hiệu năng mỗi watt. Với laptop mỏng nhẹ, mình nghĩ pin và nhiệt sẽ đáng quan tâm hơn điểm benchmark đỉnh.",
        "Mình đang thử dùng AI để tóm tắt meeting rồi tự tạo task. Hiệu quả nhất khi transcript sạch và prompt ép model trả về JSON có schema rõ.",
        "Có bạn nào build PC cho AI local dưới ngân sách vừa phải không? Mình đang cân giữa GPU cũ nhiều VRAM và GPU mới tiết kiệm điện hơn.",
        "Một kinh nghiệm nhỏ: trước khi mua gear, mình tạo bảng nhu cầu thật sự dùng mỗi ngày. Nhờ vậy tránh mua vì hype khá nhiều.",
        "Vừa đọc một bài về agent tự thao tác trên trình duyệt. Demo rất ấn tượng, nhưng mình vẫn muốn có lớp xác nhận trước các hành động quan trọng.",
        "Mình chuyển pipeline data sang incremental load, dashboard nhẹ hơn hẳn. Chi phí cloud giảm không nhiều nhưng thời gian chờ của team giảm rõ.",
        "Setup góc máy mới với dock USB-C, một sợi cáp cho màn hình, sạc và mạng LAN. Cảm giác dọn bớt dây giúp bàn làm việc dễ tập trung hơn.",
        "Mình thử benchmark app Flutter sau khi tối ưu ảnh và cache. Scroll feed mượt hơn nhiều, nhất là khi có nhiều bài kèm media.",
        "Có tin nhiều công cụ thiết kế thêm AI generate layout. Mình thấy hữu ích nhất ở bước phác thảo nhanh, còn quyết định UX vẫn phải dựa vào người dùng thật.",
        "Một bạn trong team dùng AI viết test case edge, kết quả khá tốt. Nhưng test vẫn cần reviewer hiểu nghiệp vụ để tránh assert cho có.",
        "Mình vừa cập nhật router Wi-Fi 6 cho phòng làm việc. Video call ổn hơn, nhưng khác biệt lớn nhất là nhiều thiết bị kết nối cùng lúc không còn chập chờn.",
        "Nếu mới học IT, mình nghĩ nên làm một project nhỏ end-to-end: auth, upload ảnh, feed, chat, deploy. Học vậy nhớ lâu hơn đọc rời rạc."
    ];

    private static readonly string[] CommentBodies =
    [
        "Cảm ơn đã chia sẻ, đúng thứ mình đang tìm.",
        "Mình cũng gặp tình huống tương tự, nhất là khi chạy nhiều tool cùng lúc.",
        "Có benchmark hoặc ảnh setup thực tế thì càng dễ so sánh.",
        "Ý này hay, nhưng mình nghĩ vẫn nên kiểm tra chi phí vận hành lâu dài.",
        "Mình đã thử cách gần giống vậy và thấy hiệu quả khá rõ.",
        "Phần này nếu thêm checklist ngắn thì người mới sẽ dễ áp dụng hơn."
    ];

    private static readonly string[] ChatBodies =
    [
        "Mọi người thấy trend AI agent năm nay có đủ chín để đưa vào workflow nội bộ chưa?",
        "Mình nghĩ nên bắt đầu từ tác vụ ít rủi ro như tóm tắt, phân loại ticket và tạo draft.",
        "Có ai test NPU trên laptop mới chưa? Mình muốn biết chạy local inference có thực dụng không.",
        "Với gear thì mình ưu tiên màn hình tốt trước, sau đó mới tới bàn phím và chuột.",
        "GPU cũ nhiều VRAM vẫn hấp dẫn cho lab AI, nhưng tiền điện và nhiệt cũng đáng cân nhắc.",
        "Đợt này team mình chuyển log sang structured JSON, debug production nhẹ hơn hẳn.",
        "Nếu làm app mobile có feed ảnh, cache và resize ảnh phía server là rất quan trọng.",
        "Mình vừa thêm 2FA cho toàn bộ tài khoản dev, hơi mất công lúc đầu nhưng yên tâm hơn."
    ];

    private static readonly string[] PrivateChatBodies =
    [
        "Bạn gửi mình cấu hình PC hôm qua được không? Mình muốn so lại PSU và tản nhiệt.",
        "Mình vừa đọc tin về laptop AI mới, pin khá ổn nhưng giá vẫn hơi cao.",
        "Chiều nay mình test thử prompt cho tính năng tóm tắt bài đăng, có kết quả sẽ gửi bạn.",
        "Con chuột bạn recommend dùng ổn thật, cổ tay đỡ mỏi sau cả ngày code.",
        "Mình đang cân nhắc thêm màn phụ dọc để đọc log và tài liệu.",
        "Nếu deploy bản demo, nhớ bật seed data để app nhìn có sức sống hơn nhé.",
        "Mình nghĩ bài viết nên có comment và reaction sẵn, nhìn giống cộng đồng đang hoạt động hơn.",
        "Mai mình thử chạy local model với bộ tài liệu nhỏ, xem latency thế nào."
    ];

    private static readonly string[] StoryBodies =
    [
        "Setup sáng nay: màn phụ dọc để đọc log, rất đáng tiền.",
        "Vừa test prompt mới cho workflow AI, kết quả ổn hơn hẳn.",
        "Checklist hôm nay: backup DB, update package, review security.",
        "Góc làm việc gọn lại sau khi đổi dock USB-C.",
        "Đang thử build app Flutter trên Windows, hot reload vẫn mượt.",
        "Một mẹo nhỏ: resize ảnh trước khi đưa lên feed sẽ nhẹ app hơn.",
        "Vừa đọc tin GPU mới, VRAM vẫn là thứ đáng cân nhắc nhất.",
        "Hôm nay học thêm về SignalR để làm realtime notification.",
        "Team mình đang thử dùng AI để tạo test case edge.",
        "Có ai dùng laptop AI PC chưa, NPU thực tế thế nào?",
        "Đang gom tài liệu .NET clean architecture cho nhóm.",
        "Story test từ demo account, feed nhìn có sức sống hơn.",
        "Vừa đổi bàn phím low-profile, cổ tay đỡ mỏi khi code dài.",
        "Đọc paper về RAG thấy chunking quan trọng hơn mình nghĩ.",
        "Một buổi tối debug SQL, index đúng là cứu hiệu năng.",
        "Đang setup mini lab Docker để test deploy nhanh."
    ];

    private static readonly string[] PortfolioTitles =
    [
        "Flutter Developer",
        ".NET Backend Engineer",
        "AI Product Builder",
        "Data Analyst",
        "Cloud DevOps Learner"
    ];

    private static readonly string[] PortfolioBios =
    [
        "Thich xay app mobile nhanh, UI gon va co trai nghiem tot.",
        "Tap trung API, auth, database va he thong co kha nang mo rong.",
        "Dang thu nghiem AI workflow, RAG va assistant cho san pham thuc te.",
        "Quan tam dashboard, SQL, tracking metric va chuyen doi du lieu thanh insight.",
        "Hoc Docker, CI/CD, cloud cost va quan sat he thong."
    ];

    private static readonly string[] PortfolioSkills =
    [
        "Flutter, Dart, Provider, REST API",
        "ASP.NET Core, EF Core, SQL Server, JWT",
        "Python, LLM, RAG, Prompt Engineering",
        "SQL, Power BI, Excel, Data Modeling",
        "Docker, GitHub Actions, Azure, Linux"
    ];

    private static readonly string[] PortfolioProjects =
    [
        "TechNet mobile social feed",
        "Realtime group chat",
        "AI document assistant",
        "Laptop price tracking dashboard",
        "DevOps deployment template"
    ];

    private static readonly string[] MarketplaceTitles =
    [
        "Laptop ThinkPad T14 Gen 3",
        "Màn hình Dell 27 inch 2K",
        "Bàn phím cơ Keychron K3",
        "Chuột Logitech MX Master",
        "SSD NVMe Samsung 1TB",
        "RAM DDR4 32GB kit",
        "Dock USB-C đa cổng",
        "Tai nghe Sony WH-1000XM",
        "GPU RTX 3060 12GB",
        "Mini PC Intel NUC",
        "Webcam Logitech C920",
        "Router Wi-Fi 6 Asus"
    ];

    private static readonly string[] MarketplaceDescriptions =
    [
        "Đồ tech còn tốt, phù hợp học tập, làm việc và build setup cá nhân.",
        "Đã test ổn định, ngoại hình đẹp, ưu tiên giao dịch nhanh trong cộng đồng.",
        "Nâng cấp setup nên cần nhượng lại, còn dùng tốt cho dev và creator.",
        "Phù hợp sinh viên IT hoặc người mới setup góc làm việc."
    ];

    private static readonly decimal[] MarketplacePrices =
    [
        12500000, 4200000, 1850000, 1650000, 2100000, 1900000,
        950000, 3900000, 5200000, 6800000, 1200000, 2400000
    ];

    private static readonly string[] MarketplaceCategories =
    [
        "Laptop", "Màn hình", "Gear", "Gear", "Linh kiện", "Linh kiện",
        "Phụ kiện", "Audio", "Linh kiện", "PC", "Phụ kiện", "Network"
    ];

    private static readonly string[] DemoImages =
    [
        "http://localhost:5046/uploads/technet-ai-workflow.png",
        "http://localhost:5046/uploads/technet-pc-gear.png"
    ];
}
