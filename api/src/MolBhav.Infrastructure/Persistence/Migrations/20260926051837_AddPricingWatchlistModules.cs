using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MolBhav.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddPricingWatchlistModules : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "pricing");

            migrationBuilder.EnsureSchema(
                name: "watchlist");

            migrationBuilder.CreateTable(
                name: "price_sources",
                schema: "pricing",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    code = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    is_active = table.Column<bool>(type: "boolean", nullable: false),
                    created_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    updated_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    updated_by = table.Column<Guid>(type: "uuid", nullable: true),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_price_sources", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "watchlist_items",
                schema: "watchlist",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    product_id = table.Column<Guid>(type: "uuid", nullable: false),
                    variant_id = table.Column<Guid>(type: "uuid", nullable: true),
                    created_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    updated_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    updated_by = table.Column<Guid>(type: "uuid", nullable: true),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_watchlist_items", x => x.id);
                    table.ForeignKey(
                        name: "fk_watchlist_items_products_product_id",
                        column: x => x.product_id,
                        principalSchema: "catalog",
                        principalTable: "products",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_watchlist_items_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "identity",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "price_records",
                schema: "pricing",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    product_id = table.Column<Guid>(type: "uuid", nullable: false),
                    variant_id = table.Column<Guid>(type: "uuid", nullable: true),
                    unit_id = table.Column<Guid>(type: "uuid", nullable: false),
                    location_kind = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    mandi_id = table.Column<Guid>(type: "uuid", nullable: true),
                    supplier_id = table.Column<Guid>(type: "uuid", nullable: true),
                    price_source_id = table.Column<Guid>(type: "uuid", nullable: false),
                    min_price = table.Column<decimal>(type: "numeric(18,4)", precision: 18, scale: 4, nullable: true),
                    max_price = table.Column<decimal>(type: "numeric(18,4)", precision: 18, scale: 4, nullable: true),
                    modal_price = table.Column<decimal>(type: "numeric(18,4)", precision: 18, scale: 4, nullable: false),
                    arrival_quantity = table.Column<decimal>(type: "numeric(18,4)", precision: 18, scale: 4, nullable: true),
                    record_date = table.Column<DateOnly>(type: "date", nullable: false),
                    is_voided = table.Column<bool>(type: "boolean", nullable: false),
                    created_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    updated_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    updated_by = table.Column<Guid>(type: "uuid", nullable: true),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_price_records", x => x.id);
                    table.CheckConstraint("ck_price_records_location", "(location_kind = 'Mandi' AND mandi_id IS NOT NULL AND supplier_id IS NULL) OR (location_kind = 'Supplier' AND supplier_id IS NOT NULL AND mandi_id IS NULL)");
                    table.ForeignKey(
                        name: "fk_price_records_mandis_mandi_id",
                        column: x => x.mandi_id,
                        principalSchema: "market",
                        principalTable: "mandis",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_price_records_price_sources_price_source_id",
                        column: x => x.price_source_id,
                        principalSchema: "pricing",
                        principalTable: "price_sources",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_price_records_product_variants_variant_id",
                        column: x => x.variant_id,
                        principalSchema: "catalog",
                        principalTable: "product_variants",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_price_records_products_product_id",
                        column: x => x.product_id,
                        principalSchema: "catalog",
                        principalTable: "products",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_price_records_suppliers_supplier_id",
                        column: x => x.supplier_id,
                        principalSchema: "market",
                        principalTable: "suppliers",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_price_records_units_of_measure_unit_id",
                        column: x => x.unit_id,
                        principalSchema: "catalog",
                        principalTable: "units_of_measure",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "ix_price_records_mandi_id",
                schema: "pricing",
                table: "price_records",
                column: "mandi_id");

            migrationBuilder.CreateIndex(
                name: "ix_price_records_price_source_id",
                schema: "pricing",
                table: "price_records",
                column: "price_source_id");

            migrationBuilder.CreateIndex(
                name: "ix_price_records_product_id_location_kind_record_date",
                schema: "pricing",
                table: "price_records",
                columns: new[] { "product_id", "location_kind", "record_date" });

            migrationBuilder.CreateIndex(
                name: "ix_price_records_product_id_unit_id_price_source_id_record_date",
                schema: "pricing",
                table: "price_records",
                columns: new[] { "product_id", "unit_id", "price_source_id", "record_date" });

            migrationBuilder.CreateIndex(
                name: "ix_price_records_supplier_id",
                schema: "pricing",
                table: "price_records",
                column: "supplier_id");

            migrationBuilder.CreateIndex(
                name: "ix_price_records_unit_id",
                schema: "pricing",
                table: "price_records",
                column: "unit_id");

            migrationBuilder.CreateIndex(
                name: "ix_price_records_variant_id",
                schema: "pricing",
                table: "price_records",
                column: "variant_id");

            migrationBuilder.CreateIndex(
                name: "ix_price_sources_code",
                schema: "pricing",
                table: "price_sources",
                column: "code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_watchlist_items_product_id",
                schema: "watchlist",
                table: "watchlist_items",
                column: "product_id");

            migrationBuilder.CreateIndex(
                name: "ix_watchlist_items_user_id_product_id_variant_id",
                schema: "watchlist",
                table: "watchlist_items",
                columns: new[] { "user_id", "product_id", "variant_id" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "price_records",
                schema: "pricing");

            migrationBuilder.DropTable(
                name: "watchlist_items",
                schema: "watchlist");

            migrationBuilder.DropTable(
                name: "price_sources",
                schema: "pricing");
        }
    }
}
