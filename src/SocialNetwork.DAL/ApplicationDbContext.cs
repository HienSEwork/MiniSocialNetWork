using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using SocialNetwork.DAL.Entities;
using SocialNetwork.DAL.Enums;

namespace SocialNetwork.DAL;

public class ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
    : IdentityDbContext<ApplicationUser>(options)
{
    public DbSet<Post> Posts => Set<Post>();

    public DbSet<Comment> Comments => Set<Comment>();

    public DbSet<Reaction> Reactions => Set<Reaction>();

    public DbSet<SavedPost> SavedPosts => Set<SavedPost>();

    public DbSet<Message> Messages => Set<Message>();

    public DbSet<Group> Groups => Set<Group>();

    public DbSet<GroupMember> GroupMembers => Set<GroupMember>();

    public DbSet<Friendship> Friendships => Set<Friendship>();

    public DbSet<Notification> Notifications => Set<Notification>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.Entity<ApplicationUser>(entity =>
        {
            entity.Property(user => user.DisplayName)
                .HasMaxLength(100);

            entity.Property(user => user.AvatarUrl)
                .HasMaxLength(500);

            entity.Property(user => user.Bio)
                .HasMaxLength(500);
        });

        builder.Entity<Post>(entity =>
        {
            entity.Property(post => post.Content)
                .HasMaxLength(2_000);

            entity.Property(post => post.MediaUrl)
                .HasMaxLength(500);

            entity.HasOne(post => post.User)
                .WithMany(user => user.Posts)
                .HasForeignKey(post => post.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(post => post.Group)
                .WithMany(group => group.Posts)
                .HasForeignKey(post => post.GroupId)
                .OnDelete(DeleteBehavior.SetNull);

            entity.HasQueryFilter(post => !post.IsDeleted);
        });

        builder.Entity<Comment>(entity =>
        {
            entity.Property(comment => comment.Content)
                .HasMaxLength(1_000);

            entity.HasOne(comment => comment.Post)
                .WithMany(post => post.Comments)
                .HasForeignKey(comment => comment.PostId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(comment => comment.User)
                .WithMany(user => user.Comments)
                .HasForeignKey(comment => comment.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasQueryFilter(comment => !comment.IsDeleted);
        });

        builder.Entity<Reaction>(entity =>
        {
            entity.HasIndex(reaction => new { reaction.PostId, reaction.UserId })
                .IsUnique();

            entity.HasOne(reaction => reaction.Post)
                .WithMany(post => post.Reactions)
                .HasForeignKey(reaction => reaction.PostId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(reaction => reaction.User)
                .WithMany(user => user.Reactions)
                .HasForeignKey(reaction => reaction.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasQueryFilter(reaction => !reaction.Post.IsDeleted);
        });

        builder.Entity<SavedPost>(entity =>
        {
            entity.HasIndex(savedPost => new { savedPost.UserId, savedPost.PostId })
                .IsUnique();

            entity.HasOne(savedPost => savedPost.User)
                .WithMany(user => user.SavedPosts)
                .HasForeignKey(savedPost => savedPost.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(savedPost => savedPost.Post)
                .WithMany(post => post.SavedPosts)
                .HasForeignKey(savedPost => savedPost.PostId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasQueryFilter(savedPost => !savedPost.Post.IsDeleted);
        });

        builder.Entity<Message>(entity =>
        {
            entity.Property(message => message.Content)
                .HasMaxLength(2_000);

            entity.HasOne(message => message.Sender)
                .WithMany(user => user.SentMessages)
                .HasForeignKey(message => message.SenderId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(message => message.Receiver)
                .WithMany(user => user.ReceivedMessages)
                .HasForeignKey(message => message.ReceiverId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(message => message.Group)
                .WithMany(group => group.Messages)
                .HasForeignKey(message => message.GroupId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.ToTable(table => table.HasCheckConstraint(
                "CK_Messages_Target",
                "([IsGroupMessage] = 1 AND [GroupId] IS NOT NULL AND [ReceiverId] IS NULL) OR ([IsGroupMessage] = 0 AND [GroupId] IS NULL AND [ReceiverId] IS NOT NULL)"));
        });

        builder.Entity<Group>(entity =>
        {
            entity.Property(group => group.Name)
                .HasMaxLength(120);

            entity.Property(group => group.Description)
                .HasMaxLength(1_000);

            entity.HasOne(group => group.Owner)
                .WithMany(user => user.OwnedGroups)
                .HasForeignKey(group => group.OwnerId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasQueryFilter(group => !group.IsDeleted);
        });

        builder.Entity<GroupMember>(entity =>
        {
            entity.HasKey(groupMember => new { groupMember.GroupId, groupMember.UserId });

            entity.HasOne(groupMember => groupMember.Group)
                .WithMany(group => group.Members)
                .HasForeignKey(groupMember => groupMember.GroupId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(groupMember => groupMember.User)
                .WithMany(user => user.GroupMemberships)
                .HasForeignKey(groupMember => groupMember.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasQueryFilter(groupMember => !groupMember.Group.IsDeleted);
        });

        builder.Entity<Friendship>(entity =>
        {
            entity.HasIndex(friendship => new { friendship.RequesterId, friendship.AddresseeId })
                .IsUnique();

            entity.Property(friendship => friendship.Status)
                .HasConversion<int>();

            entity.HasOne(friendship => friendship.Requester)
                .WithMany(user => user.FriendshipsRequested)
                .HasForeignKey(friendship => friendship.RequesterId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(friendship => friendship.Addressee)
                .WithMany(user => user.FriendshipsReceived)
                .HasForeignKey(friendship => friendship.AddresseeId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        builder.Entity<Notification>(entity =>
        {
            entity.Property(notification => notification.Title)
                .HasMaxLength(200);

            entity.Property(notification => notification.Message)
                .HasMaxLength(1000);

            entity.Property(notification => notification.Link)
                .HasMaxLength(500);

            entity.HasIndex(notification => new { notification.UserId, notification.CreatedDate });

            entity.HasOne(notification => notification.User)
                .WithMany(user => user.Notifications)
                .HasForeignKey(notification => notification.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(notification => notification.Actor)
                .WithMany(user => user.NotificationsCreated)
                .HasForeignKey(notification => notification.ActorId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        builder.Entity<IdentityRole>().HasData(
            new IdentityRole
            {
                Id = "role-admin",
                Name = "Admin",
                NormalizedName = "ADMIN"
            },
            new IdentityRole
            {
                Id = "role-user",
                Name = "User",
                NormalizedName = "USER"
            });
    }
}
