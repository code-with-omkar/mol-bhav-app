using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MolBhav.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddPromotionsModule : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "promotions");

            migrationBuilder.CreateTable(
                name: "advertisers",
                schema: "promotions",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    name = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    contact_name = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: true),
                    contact_phone = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    gstin = table.Column<string>(type: "character varying(15)", maxLength: 15, nullable: true),
                    created_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    updated_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    updated_by = table.Column<Guid>(type: "uuid", nullable: true),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_advertisers", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "campaigns",
                schema: "promotions",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    advertiser_id = table.Column<Guid>(type: "uuid", nullable: false),
                    name = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    placement = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    status = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    starts_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    ends_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    priority = table.Column<int>(type: "integer", nullable: false),
                    daily_impression_cap = table.Column<int>(type: "integer", nullable: true),
                    title = table.Column<string>(type: "character varying(60)", maxLength: 60, nullable: false),
                    body = table.Column<string>(type: "character varying(140)", maxLength: 140, nullable: false),
                    cta_label = table.Column<string>(type: "character varying(24)", maxLength: 24, nullable: false),
                    cta_url = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    image_url = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    created_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    updated_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    updated_by = table.Column<Guid>(type: "uuid", nullable: true),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_campaigns", x => x.id);
                    table.CheckConstraint("ck_campaigns_daily_cap", "daily_impression_cap IS NULL OR daily_impression_cap >= 1");
                    table.CheckConstraint("ck_campaigns_priority", "priority BETWEEN 0 AND 100");
                    table.CheckConstraint("ck_campaigns_schedule", "ends_at_utc > starts_at_utc");
                    table.ForeignKey(
                        name: "fk_campaigns_advertisers_advertiser_id",
                        column: x => x.advertiser_id,
                        principalSchema: "promotions",
                        principalTable: "advertisers",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "campaign_daily_stats",
                schema: "promotions",
                columns: table => new
                {
                    campaign_id = table.Column<Guid>(type: "uuid", nullable: false),
                    day = table.Column<DateOnly>(type: "date", nullable: false),
                    impressions = table.Column<int>(type: "integer", nullable: false),
                    clicks = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_campaign_daily_stats", x => new { x.campaign_id, x.day });
                    table.CheckConstraint("ck_campaign_daily_stats_counts", "impressions >= 0 AND clicks >= 0");
                    table.ForeignKey(
                        name: "fk_campaign_daily_stats_campaigns_campaign_id",
                        column: x => x.campaign_id,
                        principalSchema: "promotions",
                        principalTable: "campaigns",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "campaign_targets",
                schema: "promotions",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    category_code = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    state_id = table.Column<Guid>(type: "uuid", nullable: true),
                    campaign_id = table.Column<Guid>(type: "uuid", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_campaign_targets", x => x.id);
                    table.ForeignKey(
                        name: "fk_campaign_targets_campaigns_campaign_id",
                        column: x => x.campaign_id,
                        principalSchema: "promotions",
                        principalTable: "campaigns",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_campaign_targets_states_state_id",
                        column: x => x.state_id,
                        principalSchema: "market",
                        principalTable: "states",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "campaign_user_daily_counts",
                schema: "promotions",
                columns: table => new
                {
                    campaign_id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    day = table.Column<DateOnly>(type: "date", nullable: false),
                    impressions = table.Column<int>(type: "integer", nullable: false),
                    clicks = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_campaign_user_daily_counts", x => new { x.campaign_id, x.user_id, x.day });
                    table.CheckConstraint("ck_campaign_user_daily_counts_counts", "impressions BETWEEN 0 AND 20 AND clicks BETWEEN 0 AND 5");
                    table.ForeignKey(
                        name: "fk_campaign_user_daily_counts_campaigns_campaign_id",
                        column: x => x.campaign_id,
                        principalSchema: "promotions",
                        principalTable: "campaigns",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_advertisers_name",
                schema: "promotions",
                table: "advertisers",
                column: "name");

            migrationBuilder.CreateIndex(
                name: "ix_campaign_targets_campaign_id_category_code",
                schema: "promotions",
                table: "campaign_targets",
                columns: new[] { "campaign_id", "category_code" });

            migrationBuilder.CreateIndex(
                name: "ix_campaign_targets_state_id",
                schema: "promotions",
                table: "campaign_targets",
                column: "state_id");

            migrationBuilder.CreateIndex(
                name: "ix_campaign_user_daily_counts_day",
                schema: "promotions",
                table: "campaign_user_daily_counts",
                column: "day");

            migrationBuilder.CreateIndex(
                name: "ix_campaigns_active_placement_ends_at_utc",
                schema: "promotions",
                table: "campaigns",
                columns: new[] { "placement", "ends_at_utc" },
                filter: "status = 'Active'");

            migrationBuilder.CreateIndex(
                name: "ix_campaigns_advertiser_id",
                schema: "promotions",
                table: "campaigns",
                column: "advertiser_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "campaign_daily_stats",
                schema: "promotions");

            migrationBuilder.DropTable(
                name: "campaign_targets",
                schema: "promotions");

            migrationBuilder.DropTable(
                name: "campaign_user_daily_counts",
                schema: "promotions");

            migrationBuilder.DropTable(
                name: "campaigns",
                schema: "promotions");

            migrationBuilder.DropTable(
                name: "advertisers",
                schema: "promotions");
        }
    }
}
