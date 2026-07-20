using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using MiniSocialNetwork.Infrastructure.Persistence;

#nullable disable

namespace MiniSocialNetwork.Infrastructure.Migrations;

[DbContext(typeof(AppDbContext))]
[Migration("20260720130000_AddMarketplace")]
public partial class AddMarketplace : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateTable(
            name: "MarketplaceItems",
            columns: table => new
            {
                Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                SellerId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                Title = table.Column<string>(type: "nvarchar(max)", nullable: false),
                Description = table.Column<string>(type: "nvarchar(max)", nullable: false),
                Price = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                Category = table.Column<string>(type: "nvarchar(max)", nullable: false),
                Condition = table.Column<string>(type: "nvarchar(max)", nullable: false),
                MediaUrl = table.Column<string>(type: "nvarchar(max)", nullable: true),
                Status = table.Column<int>(type: "int", nullable: false),
                CreatedDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                UpdatedDate = table.Column<DateTime>(type: "datetime2", nullable: true)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_MarketplaceItems", x => x.Id);
                table.ForeignKey(
                    name: "FK_MarketplaceItems_AspNetUsers_SellerId",
                    column: x => x.SellerId,
                    principalTable: "AspNetUsers",
                    principalColumn: "Id");
            });

        migrationBuilder.CreateIndex(
            name: "IX_MarketplaceItems_SellerId",
            table: "MarketplaceItems",
            column: "SellerId");

        migrationBuilder.CreateIndex(
            name: "IX_MarketplaceItems_Status_CreatedDate",
            table: "MarketplaceItems",
            columns: new[] { "Status", "CreatedDate" });
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropTable(name: "MarketplaceItems");
    }
}
