using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using MiniSocialNetwork.Infrastructure.Persistence;

#nullable disable

namespace MiniSocialNetwork.Infrastructure.Migrations;

[DbContext(typeof(AppDbContext))]
[Migration("20260720112000_AddStoryReactionsAndPortfolios")]
public partial class AddStoryReactionsAndPortfolios : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateTable(
            name: "StoryReactions",
            columns: table => new
            {
                Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                StoryId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                UserId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                Type = table.Column<int>(type: "int", nullable: false),
                CreatedDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                UpdatedDate = table.Column<DateTime>(type: "datetime2", nullable: true)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_StoryReactions", x => x.Id);
                table.ForeignKey(
                    name: "FK_StoryReactions_AspNetUsers_UserId",
                    column: x => x.UserId,
                    principalTable: "AspNetUsers",
                    principalColumn: "Id");
                table.ForeignKey(
                    name: "FK_StoryReactions_Stories_StoryId",
                    column: x => x.StoryId,
                    principalTable: "Stories",
                    principalColumn: "Id");
            });

        migrationBuilder.CreateTable(
            name: "UserPortfolios",
            columns: table => new
            {
                UserId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                Title = table.Column<string>(type: "nvarchar(max)", nullable: false),
                Bio = table.Column<string>(type: "nvarchar(max)", nullable: false),
                Skills = table.Column<string>(type: "nvarchar(max)", nullable: false),
                GithubUrl = table.Column<string>(type: "nvarchar(max)", nullable: true),
                WebsiteUrl = table.Column<string>(type: "nvarchar(max)", nullable: true),
                Location = table.Column<string>(type: "nvarchar(max)", nullable: true),
                FeaturedProjectName = table.Column<string>(type: "nvarchar(max)", nullable: true),
                FeaturedProjectUrl = table.Column<string>(type: "nvarchar(max)", nullable: true),
                UpdatedDate = table.Column<DateTime>(type: "datetime2", nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_UserPortfolios", x => x.UserId);
                table.ForeignKey(
                    name: "FK_UserPortfolios_AspNetUsers_UserId",
                    column: x => x.UserId,
                    principalTable: "AspNetUsers",
                    principalColumn: "Id");
            });

        migrationBuilder.CreateIndex(
            name: "IX_StoryReactions_UserId",
            table: "StoryReactions",
            column: "UserId");

        migrationBuilder.CreateIndex(
            name: "IX_StoryReactions_StoryId_UserId",
            table: "StoryReactions",
            columns: new[] { "StoryId", "UserId" },
            unique: true);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropTable(name: "StoryReactions");
        migrationBuilder.DropTable(name: "UserPortfolios");
    }
}
