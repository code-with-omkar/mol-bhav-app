using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MolBhav.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class LinkUserCategoriesToCatalog : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Before the Catalog module existed, category codes were only shape-validated. Selections that match no
            // catalog category cannot satisfy the FK; drop them (the user re-selects on the onboarding screen).
            migrationBuilder.Sql("""
                DELETE FROM identity.user_categories uc
                WHERE NOT EXISTS (SELECT 1 FROM catalog.procurement_categories pc WHERE pc.code = uc.category_code);
                """);

            migrationBuilder.AddForeignKey(
                name: "fk_user_categories_procurement_categories_category_code",
                schema: "identity",
                table: "user_categories",
                column: "category_code",
                principalSchema: "catalog",
                principalTable: "procurement_categories",
                principalColumn: "code",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "fk_user_categories_procurement_categories_category_code",
                schema: "identity",
                table: "user_categories");
        }
    }
}
