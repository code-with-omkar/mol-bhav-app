using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MolBhav.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddMonetizationModule : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "monetization");

            migrationBuilder.CreateTable(
                name: "ad_unlock_sessions",
                schema: "monetization",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    feature = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    ads_required = table.Column<int>(type: "integer", nullable: false),
                    ads_verified = table.Column<int>(type: "integer", nullable: false),
                    status = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    expires_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    granted_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    created_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    updated_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    updated_by = table.Column<Guid>(type: "uuid", nullable: true),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_ad_unlock_sessions", x => x.id);
                    table.CheckConstraint("ck_ad_unlock_sessions_ads", "ads_required >= 1 AND ads_verified >= 0");
                    table.ForeignKey(
                        name: "fk_ad_unlock_sessions_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "identity",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "feature_grants",
                schema: "monetization",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    feature = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    quantity = table.Column<int>(type: "integer", nullable: false),
                    source = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    granted_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    expires_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    consumed_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    created_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    updated_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    updated_by = table.Column<Guid>(type: "uuid", nullable: true),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_feature_grants", x => x.id);
                    table.CheckConstraint("ck_feature_grants_quantity", "quantity >= 1");
                    table.ForeignKey(
                        name: "fk_feature_grants_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "identity",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "rewarded_ad_views",
                schema: "monetization",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    transaction_id = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    session_id = table.Column<Guid>(type: "uuid", nullable: false),
                    ad_network = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    ad_unit = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    verified_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_rewarded_ad_views", x => x.id);
                    table.ForeignKey(
                        name: "fk_rewarded_ad_views_ad_unlock_sessions_session_id",
                        column: x => x.session_id,
                        principalSchema: "monetization",
                        principalTable: "ad_unlock_sessions",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_rewarded_ad_views_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "identity",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_ad_unlock_sessions_user_id",
                schema: "monetization",
                table: "ad_unlock_sessions",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "ix_feature_grants_unconsumed",
                schema: "monetization",
                table: "feature_grants",
                columns: new[] { "user_id", "feature" },
                filter: "consumed_at_utc IS NULL");

            migrationBuilder.CreateIndex(
                name: "ix_feature_grants_user_id_feature_granted_at_utc",
                schema: "monetization",
                table: "feature_grants",
                columns: new[] { "user_id", "feature", "granted_at_utc" });

            migrationBuilder.CreateIndex(
                name: "ix_rewarded_ad_views_session_id",
                schema: "monetization",
                table: "rewarded_ad_views",
                column: "session_id");

            migrationBuilder.CreateIndex(
                name: "ix_rewarded_ad_views_transaction_id",
                schema: "monetization",
                table: "rewarded_ad_views",
                column: "transaction_id",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_rewarded_ad_views_user_id",
                schema: "monetization",
                table: "rewarded_ad_views",
                column: "user_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "feature_grants",
                schema: "monetization");

            migrationBuilder.DropTable(
                name: "rewarded_ad_views",
                schema: "monetization");

            migrationBuilder.DropTable(
                name: "ad_unlock_sessions",
                schema: "monetization");
        }
    }
}
