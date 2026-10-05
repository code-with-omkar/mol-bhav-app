using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MolBhav.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddPriceSourceCategory : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "category_id",
                schema: "pricing",
                table: "price_sources",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            // Existing sources (agmarknet, manual-test, …) are all mandi feeds → agriculture. Falls back to the first
            // category by display order if 'agriculture' was renamed/removed, so the FK below can always be created.
            migrationBuilder.Sql("""
                UPDATE pricing.price_sources
                SET category_id = (
                    SELECT c.id
                    FROM catalog.procurement_categories c
                    ORDER BY (c.code = 'agriculture') DESC, c.display_order, c.code
                    LIMIT 1)
                WHERE category_id = '00000000-0000-0000-0000-000000000000';
                """);

            // The empty-GUID default only existed to add the NOT NULL column; new sources must always name a category.
            migrationBuilder.Sql("ALTER TABLE pricing.price_sources ALTER COLUMN category_id DROP DEFAULT;");

            migrationBuilder.CreateIndex(
                name: "ix_price_sources_category_id",
                schema: "pricing",
                table: "price_sources",
                column: "category_id");

            migrationBuilder.AddForeignKey(
                name: "fk_price_sources_procurement_categories_category_id",
                schema: "pricing",
                table: "price_sources",
                column: "category_id",
                principalSchema: "catalog",
                principalTable: "procurement_categories",
                principalColumn: "id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "fk_price_sources_procurement_categories_category_id",
                schema: "pricing",
                table: "price_sources");

            migrationBuilder.DropIndex(
                name: "ix_price_sources_category_id",
                schema: "pricing",
                table: "price_sources");

            migrationBuilder.DropColumn(
                name: "category_id",
                schema: "pricing",
                table: "price_sources");
        }
    }
}
