using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MolBhav.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddAlertingProcurementNotificationReportingBillingModules : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "alerting");

            migrationBuilder.EnsureSchema(
                name: "procurement");

            migrationBuilder.EnsureSchema(
                name: "notification");

            migrationBuilder.EnsureSchema(
                name: "billing");

            migrationBuilder.EnsureSchema(
                name: "reporting");

            migrationBuilder.CreateTable(
                name: "alert_rules",
                schema: "alerting",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    product_id = table.Column<Guid>(type: "uuid", nullable: false),
                    variant_id = table.Column<Guid>(type: "uuid", nullable: true),
                    location_kind = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: true),
                    mandi_id = table.Column<Guid>(type: "uuid", nullable: true),
                    supplier_id = table.Column<Guid>(type: "uuid", nullable: true),
                    threshold_type = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    threshold_percent = table.Column<decimal>(type: "numeric(5,2)", precision: 5, scale: 2, nullable: false),
                    is_active = table.Column<bool>(type: "boolean", nullable: false),
                    created_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    updated_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    updated_by = table.Column<Guid>(type: "uuid", nullable: true),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_alert_rules", x => x.id);
                    table.CheckConstraint("ck_alert_rules_location", "(location_kind IS NULL AND mandi_id IS NULL AND supplier_id IS NULL) OR (location_kind = 'Mandi' AND mandi_id IS NOT NULL AND supplier_id IS NULL) OR (location_kind = 'Supplier' AND supplier_id IS NOT NULL AND mandi_id IS NULL)");
                    table.ForeignKey(
                        name: "fk_alert_rules_mandis_mandi_id",
                        column: x => x.mandi_id,
                        principalSchema: "market",
                        principalTable: "mandis",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_alert_rules_product_variants_variant_id",
                        column: x => x.variant_id,
                        principalSchema: "catalog",
                        principalTable: "product_variants",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_alert_rules_products_product_id",
                        column: x => x.product_id,
                        principalSchema: "catalog",
                        principalTable: "products",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_alert_rules_suppliers_supplier_id",
                        column: x => x.supplier_id,
                        principalSchema: "market",
                        principalTable: "suppliers",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_alert_rules_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "identity",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "cost_components",
                schema: "procurement",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    code = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    component_type = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    value = table.Column<decimal>(type: "numeric(12,4)", precision: 12, scale: 4, nullable: false),
                    is_active = table.Column<bool>(type: "boolean", nullable: false),
                    created_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    updated_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    updated_by = table.Column<Guid>(type: "uuid", nullable: true),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_cost_components", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "notifications",
                schema: "notification",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    channel = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    title = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    body = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    status = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    sent_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    failure_reason = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    created_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    updated_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    updated_by = table.Column<Guid>(type: "uuid", nullable: true),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_notifications", x => x.id);
                    table.ForeignKey(
                        name: "fk_notifications_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "identity",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "plans",
                schema: "billing",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    code = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    price = table.Column<decimal>(type: "numeric(12,2)", precision: 12, scale: 2, nullable: false),
                    currency = table.Column<string>(type: "character varying(3)", maxLength: 3, nullable: false),
                    billing_period = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    is_active = table.Column<bool>(type: "boolean", nullable: false),
                    created_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    updated_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    updated_by = table.Column<Guid>(type: "uuid", nullable: true),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_plans", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "procurement_requirements",
                schema: "procurement",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    product_id = table.Column<Guid>(type: "uuid", nullable: false),
                    variant_id = table.Column<Guid>(type: "uuid", nullable: true),
                    quantity = table.Column<decimal>(type: "numeric(14,3)", precision: 14, scale: 3, nullable: false),
                    unit_id = table.Column<Guid>(type: "uuid", nullable: false),
                    target_district_id = table.Column<Guid>(type: "uuid", nullable: true),
                    target_price = table.Column<decimal>(type: "numeric(14,2)", precision: 14, scale: 2, nullable: true),
                    created_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    updated_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    updated_by = table.Column<Guid>(type: "uuid", nullable: true),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_procurement_requirements", x => x.id);
                    table.ForeignKey(
                        name: "fk_procurement_requirements_districts_target_district_id",
                        column: x => x.target_district_id,
                        principalSchema: "market",
                        principalTable: "districts",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_procurement_requirements_product_variants_variant_id",
                        column: x => x.variant_id,
                        principalSchema: "catalog",
                        principalTable: "product_variants",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_procurement_requirements_products_product_id",
                        column: x => x.product_id,
                        principalSchema: "catalog",
                        principalTable: "products",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_procurement_requirements_units_of_measure_unit_id",
                        column: x => x.unit_id,
                        principalSchema: "catalog",
                        principalTable: "units_of_measure",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_procurement_requirements_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "identity",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "reports",
                schema: "reporting",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    report_type = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    format = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    parameters_json = table.Column<string>(type: "jsonb", nullable: false),
                    status = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    download_url = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    failure_reason = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    requested_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    completed_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    created_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    updated_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    updated_by = table.Column<Guid>(type: "uuid", nullable: true),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_reports", x => x.id);
                    table.ForeignKey(
                        name: "fk_reports_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "identity",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "alerts",
                schema: "alerting",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    alert_rule_id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    product_id = table.Column<Guid>(type: "uuid", nullable: false),
                    variant_id = table.Column<Guid>(type: "uuid", nullable: true),
                    location_kind = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    mandi_id = table.Column<Guid>(type: "uuid", nullable: true),
                    supplier_id = table.Column<Guid>(type: "uuid", nullable: true),
                    price_record_id = table.Column<Guid>(type: "uuid", nullable: false),
                    previous_price = table.Column<decimal>(type: "numeric(18,4)", precision: 18, scale: 4, nullable: false),
                    new_price = table.Column<decimal>(type: "numeric(18,4)", precision: 18, scale: 4, nullable: false),
                    percent_change = table.Column<decimal>(type: "numeric(9,4)", precision: 9, scale: 4, nullable: false),
                    threshold_type = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    triggered_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    is_read = table.Column<bool>(type: "boolean", nullable: false),
                    created_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    updated_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    updated_by = table.Column<Guid>(type: "uuid", nullable: true),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_alerts", x => x.id);
                    table.CheckConstraint("ck_alerts_location", "(location_kind = 'Mandi' AND mandi_id IS NOT NULL AND supplier_id IS NULL) OR (location_kind = 'Supplier' AND supplier_id IS NOT NULL AND mandi_id IS NULL)");
                    table.ForeignKey(
                        name: "fk_alerts_alert_rules_alert_rule_id",
                        column: x => x.alert_rule_id,
                        principalSchema: "alerting",
                        principalTable: "alert_rules",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_alerts_mandis_mandi_id",
                        column: x => x.mandi_id,
                        principalSchema: "market",
                        principalTable: "mandis",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_alerts_price_records_price_record_id",
                        column: x => x.price_record_id,
                        principalSchema: "pricing",
                        principalTable: "price_records",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_alerts_product_variants_variant_id",
                        column: x => x.variant_id,
                        principalSchema: "catalog",
                        principalTable: "product_variants",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_alerts_products_product_id",
                        column: x => x.product_id,
                        principalSchema: "catalog",
                        principalTable: "products",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_alerts_suppliers_supplier_id",
                        column: x => x.supplier_id,
                        principalSchema: "market",
                        principalTable: "suppliers",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_alerts_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "identity",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "subscriptions",
                schema: "billing",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    plan_id = table.Column<Guid>(type: "uuid", nullable: false),
                    status = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    started_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    expires_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    is_auto_renew = table.Column<bool>(type: "boolean", nullable: false),
                    cancelled_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    created_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    updated_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    updated_by = table.Column<Guid>(type: "uuid", nullable: true),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_subscriptions", x => x.id);
                    table.ForeignKey(
                        name: "fk_subscriptions_plans_plan_id",
                        column: x => x.plan_id,
                        principalSchema: "billing",
                        principalTable: "plans",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_subscriptions_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "identity",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "procurement_opportunities",
                schema: "procurement",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    requirement_id = table.Column<Guid>(type: "uuid", nullable: false),
                    location_kind = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    location_id = table.Column<Guid>(type: "uuid", nullable: false),
                    location_name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    quantity = table.Column<decimal>(type: "numeric(14,3)", precision: 14, scale: 3, nullable: false),
                    unit_price = table.Column<decimal>(type: "numeric(14,2)", precision: 14, scale: 2, nullable: false),
                    estimated_cost = table.Column<decimal>(type: "numeric(16,2)", precision: 16, scale: 2, nullable: false),
                    savings_vs_target = table.Column<decimal>(type: "numeric(16,2)", precision: 16, scale: 2, nullable: true),
                    price_record_date = table.Column<DateOnly>(type: "date", nullable: false),
                    computed_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    updated_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    updated_by = table.Column<Guid>(type: "uuid", nullable: true),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_procurement_opportunities", x => x.id);
                    table.ForeignKey(
                        name: "fk_procurement_opportunities_procurement_requirements_requirem~",
                        column: x => x.requirement_id,
                        principalSchema: "procurement",
                        principalTable: "procurement_requirements",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_alert_rules_mandi_id",
                schema: "alerting",
                table: "alert_rules",
                column: "mandi_id");

            migrationBuilder.CreateIndex(
                name: "ix_alert_rules_product_id_is_active",
                schema: "alerting",
                table: "alert_rules",
                columns: new[] { "product_id", "is_active" });

            migrationBuilder.CreateIndex(
                name: "ix_alert_rules_supplier_id",
                schema: "alerting",
                table: "alert_rules",
                column: "supplier_id");

            migrationBuilder.CreateIndex(
                name: "ix_alert_rules_user_id",
                schema: "alerting",
                table: "alert_rules",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "ix_alert_rules_variant_id",
                schema: "alerting",
                table: "alert_rules",
                column: "variant_id");

            migrationBuilder.CreateIndex(
                name: "ix_alerts_alert_rule_id",
                schema: "alerting",
                table: "alerts",
                column: "alert_rule_id");

            migrationBuilder.CreateIndex(
                name: "ix_alerts_mandi_id",
                schema: "alerting",
                table: "alerts",
                column: "mandi_id");

            migrationBuilder.CreateIndex(
                name: "ix_alerts_price_record_id",
                schema: "alerting",
                table: "alerts",
                column: "price_record_id");

            migrationBuilder.CreateIndex(
                name: "ix_alerts_product_id",
                schema: "alerting",
                table: "alerts",
                column: "product_id");

            migrationBuilder.CreateIndex(
                name: "ix_alerts_supplier_id",
                schema: "alerting",
                table: "alerts",
                column: "supplier_id");

            migrationBuilder.CreateIndex(
                name: "ix_alerts_user_id_triggered_at_utc",
                schema: "alerting",
                table: "alerts",
                columns: new[] { "user_id", "triggered_at_utc" });

            migrationBuilder.CreateIndex(
                name: "ix_alerts_variant_id",
                schema: "alerting",
                table: "alerts",
                column: "variant_id");

            migrationBuilder.CreateIndex(
                name: "ix_cost_components_code",
                schema: "procurement",
                table: "cost_components",
                column: "code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_notifications_status",
                schema: "notification",
                table: "notifications",
                column: "status");

            migrationBuilder.CreateIndex(
                name: "ix_notifications_user_id_created_at_utc",
                schema: "notification",
                table: "notifications",
                columns: new[] { "user_id", "created_at_utc" });

            migrationBuilder.CreateIndex(
                name: "ix_plans_code",
                schema: "billing",
                table: "plans",
                column: "code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_procurement_opportunities_requirement_id_estimated_cost",
                schema: "procurement",
                table: "procurement_opportunities",
                columns: new[] { "requirement_id", "estimated_cost" });

            migrationBuilder.CreateIndex(
                name: "ix_procurement_requirements_product_id",
                schema: "procurement",
                table: "procurement_requirements",
                column: "product_id");

            migrationBuilder.CreateIndex(
                name: "ix_procurement_requirements_target_district_id",
                schema: "procurement",
                table: "procurement_requirements",
                column: "target_district_id");

            migrationBuilder.CreateIndex(
                name: "ix_procurement_requirements_unit_id",
                schema: "procurement",
                table: "procurement_requirements",
                column: "unit_id");

            migrationBuilder.CreateIndex(
                name: "ix_procurement_requirements_user_id",
                schema: "procurement",
                table: "procurement_requirements",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "ix_procurement_requirements_variant_id",
                schema: "procurement",
                table: "procurement_requirements",
                column: "variant_id");

            migrationBuilder.CreateIndex(
                name: "ix_reports_status",
                schema: "reporting",
                table: "reports",
                column: "status");

            migrationBuilder.CreateIndex(
                name: "ix_reports_user_id_requested_at_utc",
                schema: "reporting",
                table: "reports",
                columns: new[] { "user_id", "requested_at_utc" });

            migrationBuilder.CreateIndex(
                name: "ix_subscriptions_plan_id",
                schema: "billing",
                table: "subscriptions",
                column: "plan_id");

            migrationBuilder.CreateIndex(
                name: "ix_subscriptions_user_id_status",
                schema: "billing",
                table: "subscriptions",
                columns: new[] { "user_id", "status" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "alerts",
                schema: "alerting");

            migrationBuilder.DropTable(
                name: "cost_components",
                schema: "procurement");

            migrationBuilder.DropTable(
                name: "notifications",
                schema: "notification");

            migrationBuilder.DropTable(
                name: "procurement_opportunities",
                schema: "procurement");

            migrationBuilder.DropTable(
                name: "reports",
                schema: "reporting");

            migrationBuilder.DropTable(
                name: "subscriptions",
                schema: "billing");

            migrationBuilder.DropTable(
                name: "alert_rules",
                schema: "alerting");

            migrationBuilder.DropTable(
                name: "procurement_requirements",
                schema: "procurement");

            migrationBuilder.DropTable(
                name: "plans",
                schema: "billing");
        }
    }
}
