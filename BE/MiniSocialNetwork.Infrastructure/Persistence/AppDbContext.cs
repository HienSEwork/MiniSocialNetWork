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

        // GroupMember
        builder.Entity<GroupMember>()
            .HasOne(gm => gm.User)
            .WithMany(u => u.GroupMembers)
            .HasForeignKey(gm => gm.UserId)
            .OnDelete(DeleteBehavior.NoAction);

        // Message check constraint
        builder.Entity<Message>()
            .HasCheckConstraint("CK_Messages_Target",
                @"([IsGroupMessage] = 1 AND [GroupId] IS NOT NULL AND [ReceiverId] IS NULL) 
                  OR ([IsGroupMessage] = 0 AND [GroupId] IS NULL AND [ReceiverId] IS NOT NULL)");

        // Reaction unique
        builder.Entity<Reaction>()
            .HasIndex(r => new { r.PostId, r.UserId })
            .IsUnique();
    }
}