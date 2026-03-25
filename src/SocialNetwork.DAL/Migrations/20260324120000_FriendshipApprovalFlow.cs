using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using SocialNetwork.DAL;

#nullable disable

namespace SocialNetwork.DAL.Migrations
{
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20260324120000_FriendshipApprovalFlow")]
    public partial class FriendshipApprovalFlow : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "Status",
                table: "Friendships",
                type: "int",
                nullable: true);

            migrationBuilder.Sql("UPDATE [Friendships] SET [Status] = 1 WHERE [Status] IS NULL;");

            migrationBuilder.AlterColumn<int>(
                name: "Status",
                table: "Friendships",
                type: "int",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Status",
                table: "Friendships");
        }

        protected override void BuildTargetModel(ModelBuilder modelBuilder)
        {
#pragma warning disable 612, 618
            new SnapshotAccessor().Build(modelBuilder);
#pragma warning restore 612, 618
        }

        private sealed class SnapshotAccessor : ApplicationDbContextModelSnapshot
        {
            public void Build(ModelBuilder modelBuilder) => BuildModel(modelBuilder);
        }
    }
}
