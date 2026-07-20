using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MiniSocialNetwork.Infrastructure.Migrations;

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
