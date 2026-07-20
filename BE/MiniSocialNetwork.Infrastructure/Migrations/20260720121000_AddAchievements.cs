using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using MiniSocialNetwork.Infrastructure.Persistence;

#nullable disable

namespace MiniSocialNetwork.Infrastructure.Migrations;

[DbContext(typeof(AppDbContext))]
[Migration("20260720121000_AddAchievements")]
public partial class AddAchievements : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateTable(
            name: "AchievementDefinitions",
            columns: table => new
            {
                Code = table.Column<string>(type: "nvarchar(450)", nullable: false),
                Name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                Description = table.Column<string>(type: "nvarchar(max)", nullable: false),
                Icon = table.Column<string>(type: "nvarchar(max)", nullable: false),
                SortOrder = table.Column<int>(type: "int", nullable: false),
                IsActive = table.Column<bool>(type: "bit", nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_AchievementDefinitions", x => x.Code);
            });

        migrationBuilder.CreateTable(
            name: "UserAchievements",
            columns: table => new
            {
                UserId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                AchievementCode = table.Column<string>(type: "nvarchar(450)", nullable: false),
                UnlockedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_UserAchievements", x => new { x.UserId, x.AchievementCode });
                table.ForeignKey(
                    name: "FK_UserAchievements_AchievementDefinitions_AchievementCode",
                    column: x => x.AchievementCode,
                    principalTable: "AchievementDefinitions",
                    principalColumn: "Code");
                table.ForeignKey(
                    name: "FK_UserAchievements_AspNetUsers_UserId",
                    column: x => x.UserId,
                    principalTable: "AspNetUsers",
                    principalColumn: "Id");
            });

        migrationBuilder.CreateIndex(
            name: "IX_UserAchievements_AchievementCode",
            table: "UserAchievements",
            column: "AchievementCode");
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropTable(name: "UserAchievements");
        migrationBuilder.DropTable(name: "AchievementDefinitions");
    }
}
