using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MolBhav.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddPriceRecordLocationDateIndexes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "ix_price_records_mandi_id",
                schema: "pricing",
                table: "price_records");

            migrationBuilder.DropIndex(
                name: "ix_price_records_supplier_id",
                schema: "pricing",
                table: "price_records");

            migrationBuilder.CreateIndex(
                name: "ix_price_records_mandi_id_record_date",
                schema: "pricing",
                table: "price_records",
                columns: new[] { "mandi_id", "record_date" },
                descending: new[] { false, true },
                filter: "mandi_id IS NOT NULL AND NOT is_voided");

            migrationBuilder.CreateIndex(
                name: "ix_price_records_supplier_id_record_date",
                schema: "pricing",
                table: "price_records",
                columns: new[] { "supplier_id", "record_date" },
                descending: new[] { false, true },
                filter: "supplier_id IS NOT NULL AND NOT is_voided");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "ix_price_records_mandi_id_record_date",
                schema: "pricing",
                table: "price_records");

            migrationBuilder.DropIndex(
                name: "ix_price_records_supplier_id_record_date",
                schema: "pricing",
                table: "price_records");

            migrationBuilder.CreateIndex(
                name: "ix_price_records_mandi_id",
                schema: "pricing",
                table: "price_records",
                column: "mandi_id");

            migrationBuilder.CreateIndex(
                name: "ix_price_records_supplier_id",
                schema: "pricing",
                table: "price_records",
                column: "supplier_id");
        }
    }
}
