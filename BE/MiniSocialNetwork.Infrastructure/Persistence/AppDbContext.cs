using System.Collections.Generic;
using System.Reflection.Emit;
using Microsoft.EntityFrameworkCore;
using MiniSocialNetwork.Domain.Entities;

namespace MiniSocialNetwork.Infrastructure.Persistence;

public class AppDbContext : DbContext
{
    public DbSet<Group> Groups { get; set; }
    public DbSet<GroupMember> GroupMembers { get; set; }

    public AppDbContext(DbContextOptions<AppDbContext> options)
    : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        builder.Entity<GroupMember>()
            .HasKey(x => new { x.GroupId, x.UserId });
    }
}