using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using MiniSocialNetwork.Infrastructure.Persistence;

#nullable disable

namespace MiniSocialNetwork.Infrastructure.Migrations;

[DbContext(typeof(AppDbContext))]
[Migration("20260720103000_AddStories")]
public partial class AddStories : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateTable(
            name: "Stories",
            columns: table => new
            {
                Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                UserId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                Content = table.Column<string>(type: "nvarchar(max)", nullable: false),
                MediaUrl = table.Column<string>(type: "nvarchar(max)", nullable: true),
                MediaType = table.Column<int>(type: "int", nullable: false),
                CreatedDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                ExpiresAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                UpdatedDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                IsDeleted = table.Column<bool>(type: "bit", nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_Stories", x => x.Id);
                table.ForeignKey(
                    name: "FK_Stories_AspNetUsers_UserId",
                    column: x => x.UserId,
                    principalTable: "AspNetUsers",
                    principalColumn: "Id");
            });

        migrationBuilder.CreateIndex(
            name: "IX_Stories_UserId",
            table: "Stories",
            column: "UserId");

        migrationBuilder.CreateIndex(
            name: "IX_Stories_ExpiresAt_IsDeleted_CreatedDate",
            table: "Stories",
            columns: new[] { "ExpiresAt", "IsDeleted", "CreatedDate" });
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropTable(name: "Stories");
    }
}
