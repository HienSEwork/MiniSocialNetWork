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

    // New
    public DbSet<FriendRequest> FriendRequests { get; set; }

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

        // FriendRequest configuration
        builder.Entity<FriendRequest>(fr =>
        {
            fr.HasKey(x => x.Id);
            fr.HasOne(x => x.Requester)
                .WithMany()
                .HasForeignKey(x => x.RequesterId)
                .OnDelete(DeleteBehavior.NoAction);

            fr.HasOne(x => x.Addressee)
                .WithMany()
                .HasForeignKey(x => x.AddresseeId)
                .OnDelete(DeleteBehavior.NoAction);

            // optional index to speed lookups by requester/addressee/status
            fr.HasIndex(x => new { x.RequesterId, x.AddresseeId });
            fr.HasIndex(x => new { x.AddresseeId, x.Status });
        });
    }
}
