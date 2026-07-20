using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using MiniSocialNetwork.Domain.Entities;

namespace MiniSocialNetwork.Infrastructure.Persistence;

public class AppDbContext : IdentityDbContext<AppUser>
{
    public DbSet<Group> Groups { get; set; }
    public DbSet<GroupMember> GroupMembers { get; set; }
    public DbSet<Post> Posts { get; set; }
    public DbSet<Comment> Comments { get; set; }
    public DbSet<Reaction> Reactions { get; set; }
    public DbSet<Message> Messages { get; set; }
    public DbSet<Story> Stories { get; set; }
    public DbSet<StoryReaction> StoryReactions { get; set; }
    public DbSet<UserPortfolio> UserPortfolios { get; set; }
    public DbSet<AchievementDefinition> AchievementDefinitions { get; set; }
    public DbSet<UserAchievement> UserAchievements { get; set; }
    public DbSet<MarketplaceItem> MarketplaceItems { get; set; }

    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        // GroupMember composite key
        builder.Entity<GroupMember>()
            .HasKey(x => new { x.GroupId, x.UserId });

        // Group → Owner
        builder.Entity<Group>()
            .HasOne(g => g.Owner)
            .WithMany(u => u.OwnedGroups)
            .HasForeignKey(g => g.OwnerId)
            .OnDelete(DeleteBehavior.NoAction);

        // GroupMember → User
        builder.Entity<GroupMember>()
            .HasOne(gm => gm.User)
            .WithMany(u => u.GroupMembers)
            .HasForeignKey(gm => gm.UserId)
            .OnDelete(DeleteBehavior.NoAction);

        // 🔥 FIX CASCADE (QUAN TRỌNG NHẤT)
        builder.Entity<Comment>()
            .HasOne(c => c.Post)
            .WithMany(p => p.Comments)
            .HasForeignKey(c => c.PostId)
            .OnDelete(DeleteBehavior.NoAction);

        builder.Entity<Comment>()
            .HasOne(c => c.User)
            .WithMany()
            .HasForeignKey(c => c.UserId)
            .OnDelete(DeleteBehavior.NoAction);

        // (optional nhưng nên thêm để tránh lỗi sau này)
        builder.Entity<Reaction>()
            .HasOne(r => r.Post)
            .WithMany(p => p.Reactions)
            .HasForeignKey(r => r.PostId)
            .OnDelete(DeleteBehavior.NoAction);

        builder.Entity<Reaction>()
            .HasOne(r => r.User)
            .WithMany()
            .HasForeignKey(r => r.UserId)
            .OnDelete(DeleteBehavior.NoAction);

        // Message check constraint
        builder.Entity<Message>()
            .ToTable(table => table.HasCheckConstraint("CK_Messages_Target",
                @"([IsGroupMessage] = 1 AND [GroupId] IS NOT NULL AND [ReceiverId] IS NULL) 
                  OR ([IsGroupMessage] = 0 AND [GroupId] IS NULL AND [ReceiverId] IS NOT NULL)"));

        // Reaction unique
        builder.Entity<Reaction>()
            .HasIndex(r => new { r.PostId, r.UserId })
            .IsUnique();

        builder.Entity<Story>()
            .HasOne(story => story.User)
            .WithMany()
            .HasForeignKey(story => story.UserId)
            .OnDelete(DeleteBehavior.NoAction);

        builder.Entity<StoryReaction>()
            .HasOne(reaction => reaction.Story)
            .WithMany(story => story.Reactions)
            .HasForeignKey(reaction => reaction.StoryId)
            .OnDelete(DeleteBehavior.NoAction);

        builder.Entity<StoryReaction>()
            .HasOne(reaction => reaction.User)
            .WithMany()
            .HasForeignKey(reaction => reaction.UserId)
            .OnDelete(DeleteBehavior.NoAction);

        builder.Entity<StoryReaction>()
            .HasIndex(reaction => new { reaction.StoryId, reaction.UserId })
            .IsUnique();

        builder.Entity<UserPortfolio>()
            .HasKey(portfolio => portfolio.UserId);

        builder.Entity<UserPortfolio>()
            .HasOne(portfolio => portfolio.User)
            .WithMany()
            .HasForeignKey(portfolio => portfolio.UserId)
            .OnDelete(DeleteBehavior.NoAction);

        builder.Entity<AchievementDefinition>()
            .HasKey(achievement => achievement.Code);

        builder.Entity<UserAchievement>()
            .HasKey(achievement => new { achievement.UserId, achievement.AchievementCode });

        builder.Entity<UserAchievement>()
            .HasOne(achievement => achievement.User)
            .WithMany()
            .HasForeignKey(achievement => achievement.UserId)
            .OnDelete(DeleteBehavior.NoAction);

        builder.Entity<UserAchievement>()
            .HasOne(achievement => achievement.Achievement)
            .WithMany()
            .HasForeignKey(achievement => achievement.AchievementCode)
            .OnDelete(DeleteBehavior.NoAction);

        builder.Entity<MarketplaceItem>()
            .HasOne(item => item.Seller)
            .WithMany()
            .HasForeignKey(item => item.SellerId)
            .OnDelete(DeleteBehavior.NoAction);
    }
}
