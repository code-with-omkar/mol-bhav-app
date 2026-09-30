using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MolBhav.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddOffersModule : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "coupons",
                schema: "billing",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    code = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    discount_type = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    discount_value = table.Column<long>(type: "bigint", nullable: false),
                    max_uses = table.Column<int>(type: "integer", nullable: true),
                    uses_count = table.Column<int>(type: "integer", nullable: false),
                    valid_from = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    valid_to = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    applicable_plan_code = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: true),
                    min_amount_paise = table.Column<long>(type: "bigint", nullable: false),
                    is_active = table.Column<bool>(type: "boolean", nullable: false),
                    created_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    updated_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    updated_by = table.Column<Guid>(type: "uuid", nullable: true),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_coupons", x => x.id);
                    table.CheckConstraint("ck_coupons_discount_type", "discount_type IN ('Percent', 'Fixed')");
                    table.CheckConstraint("ck_coupons_discount_value", "discount_value > 0");
                    table.CheckConstraint("ck_coupons_percent_range", "discount_type <> 'Percent' OR discount_value BETWEEN 1 AND 100");
                    table.CheckConstraint("ck_coupons_uses", "uses_count >= 0 AND (max_uses IS NULL OR uses_count <= max_uses)");
                    table.CheckConstraint("ck_coupons_validity", "valid_to IS NULL OR valid_to > valid_from");
                });

            migrationBuilder.CreateIndex(
                name: "ix_coupons_code",
                schema: "billing",
                table: "coupons",
                column: "code",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "coupons",
                schema: "billing");
        }
    }
}
