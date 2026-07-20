using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using MiniSocialNetwork.Infrastructure.Persistence;

#nullable disable

namespace MiniSocialNetwork.Infrastructure.Migrations
{
    [DbContext(typeof(AppDbContext))]
    [Migration("20260720033000_AddAppUserIsDeleted")]
    public partial class AddAppUserIsDeleted : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "AspNetUsers",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "AspNetUsers");
        }
    }
}
