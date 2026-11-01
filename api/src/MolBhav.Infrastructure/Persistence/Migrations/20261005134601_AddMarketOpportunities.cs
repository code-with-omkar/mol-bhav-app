using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MolBhav.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddMarketOpportunities : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "market_opportunities",
                schema: "alerting",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    product_id = table.Column<Guid>(type: "uuid", nullable: false),
                    variant_id = table.Column<Guid>(type: "uuid", nullable: true),
                    detected_on = table.Column<DateOnly>(type: "date", nullable: false),
                    home_location_kind = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    home_mandi_id = table.Column<Guid>(type: "uuid", nullable: true),
                    home_supplier_id = table.Column<Guid>(type: "uuid", nullable: true),
                    home_price = table.Column<decimal>(type: "numeric(18,4)", precision: 18, scale: 4, nullable: false),
                    best_location_kind = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    best_mandi_id = table.Column<Guid>(type: "uuid", nullable: true),
                    best_supplier_id = table.Column<Guid>(type: "uuid", nullable: true),
                    best_price = table.Column<decimal>(type: "numeric(18,4)", precision: 18, scale: 4, nullable: false),
                    landed_price = table.Column<decimal>(type: "numeric(18,4)", precision: 18, scale: 4, nullable: false),
                    savings_percent = table.Column<decimal>(type: "numeric(9,4)", precision: 9, scale: 4, nullable: false),
                    price_date = table.Column<DateOnly>(type: "date", nullable: false),
                    detected_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    is_read = table.Column<bool>(type: "boolean", nullable: false),
                    created_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    updated_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    updated_by = table.Column<Guid>(type: "uuid", nullable: true),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_market_opportunities", x => x.id);
                    table.CheckConstraint("ck_market_opportunities_best_location", "(best_location_kind = 'Mandi' AND best_mandi_id IS NOT NULL AND best_supplier_id IS NULL) OR (best_location_kind = 'Supplier' AND best_supplier_id IS NOT NULL AND best_mandi_id IS NULL)");
                    table.CheckConstraint("ck_market_opportunities_home_location", "(home_location_kind = 'Mandi' AND home_mandi_id IS NOT NULL AND home_supplier_id IS NULL) OR (home_location_kind = 'Supplier' AND home_supplier_id IS NOT NULL AND home_mandi_id IS NULL)");
                    table.CheckConstraint("ck_market_opportunities_prices", "home_price > 0 AND best_price > 0 AND landed_price >= best_price AND landed_price < home_price");
                    table.ForeignKey(
                        name: "fk_market_opportunities_mandis_best_mandi_id",
                        column: x => x.best_mandi_id,
                        principalSchema: "market",
                        principalTable: "mandis",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_market_opportunities_mandis_home_mandi_id",
                        column: x => x.home_mandi_id,
                        principalSchema: "market",
                        principalTable: "mandis",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_market_opportunities_product_variants_variant_id",
                        column: x => x.variant_id,
                        principalSchema: "catalog",
                        principalTable: "product_variants",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_market_opportunities_products_product_id",
                        column: x => x.product_id,
                        principalSchema: "catalog",
                        principalTable: "products",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_market_opportunities_suppliers_best_supplier_id",
                        column: x => x.best_supplier_id,
                        principalSchema: "market",
                        principalTable: "suppliers",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_market_opportunities_suppliers_home_supplier_id",
                        column: x => x.home_supplier_id,
                        principalSchema: "market",
                        principalTable: "suppliers",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_market_opportunities_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "identity",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_market_opportunities_best_mandi_id",
                schema: "alerting",
                table: "market_opportunities",
                column: "best_mandi_id");

            migrationBuilder.CreateIndex(
                name: "ix_market_opportunities_best_supplier_id",
                schema: "alerting",
                table: "market_opportunities",
                column: "best_supplier_id");

            migrationBuilder.CreateIndex(
                name: "ix_market_opportunities_detected_on_user_id_product_id",
                schema: "alerting",
                table: "market_opportunities",
                columns: new[] { "detected_on", "user_id", "product_id" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_market_opportunities_home_mandi_id",
                schema: "alerting",
                table: "market_opportunities",
                column: "home_mandi_id");

            migrationBuilder.CreateIndex(
                name: "ix_market_opportunities_home_supplier_id",
                schema: "alerting",
                table: "market_opportunities",
                column: "home_supplier_id");

            migrationBuilder.CreateIndex(
                name: "ix_market_opportunities_product_id",
                schema: "alerting",
                table: "market_opportunities",
                column: "product_id");

            migrationBuilder.CreateIndex(
                name: "ix_market_opportunities_user_id_detected_at_utc",
                schema: "alerting",
                table: "market_opportunities",
                columns: new[] { "user_id", "detected_at_utc" });

            migrationBuilder.CreateIndex(
                name: "ix_market_opportunities_variant_id",
                schema: "alerting",
                table: "market_opportunities",
                column: "variant_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "market_opportunities",
                schema: "alerting");
        }
    }
}
