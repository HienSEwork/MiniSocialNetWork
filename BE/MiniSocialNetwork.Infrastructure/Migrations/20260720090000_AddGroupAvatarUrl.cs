using Microsoft.EntityFrameworkCore.Migrations;
using Microsoft.EntityFrameworkCore.Infrastructure;
using MiniSocialNetwork.Infrastructure.Persistence;

#nullable disable

namespace MiniSocialNetwork.Infrastructure.Migrations;

[DbContext(typeof(AppDbContext))]
[Migration("20260720090000_AddGroupAvatarUrl")]
public partial class AddGroupAvatarUrl : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<string>(
            name: "AvatarUrl",
            table: "Groups",
            type: "nvarchar(max)",
            nullable: true);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropColumn(
            name: "AvatarUrl",
            table: "Groups");
    }
}
