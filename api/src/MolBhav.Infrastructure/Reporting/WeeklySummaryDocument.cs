using System.Globalization;
using MolBhav.Application.Features.Alerting.Models;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace MolBhav.Infrastructure.Reporting;

internal sealed record OpportunitySummary(
    string ProductName, decimal Quantity, string UnitSymbol, string? LocationName, decimal? EstimatedCost, decimal? Saving);

internal sealed record WeeklySummaryData(
    string? DisplayName,
    DateOnly FromDate,
    DateOnly ToDate,
    DateTimeOffset GeneratedAtUtc,
    IReadOnlyList<WatchlistPeriodRow> Watchlist,
    IReadOnlyList<AlertResponse> Alerts,
    IReadOnlyList<OpportunitySummary> Opportunities);

/// <summary>The weekly summary PDF: watchlist movement, triggered alerts and best sourcing option per requirement.</summary>
internal static class WeeklySummaryDocument
{
    private const string Brand = "#168447";
    private const string Ink = "#1B2A22";
    private const string Muted = "#5E6B63";
    private const string Rule = "#E3E7E1";
    private const string HeaderFill = "#F1F5EF";
    private const string Up = "#C0392B";
    private const string Down = "#168447";

    /// <summary>India has one time zone and no DST, so a fixed offset is exact.</summary>
    public static readonly TimeSpan IndiaOffset = TimeSpan.FromHours(5.5);

    private static readonly CultureInfo Numbers = CultureInfo.GetCultureInfo("en-IN");

    public static byte[] Render(WeeklySummaryData data, string language)
    {
        ReportFonts.EnsureRegistered();
        var labels = ReportLabels.For(language);
        var dates = DateCulture(language);

        return Document.Create(container => container.Page(page =>
        {
            page.Size(PageSizes.A4);
            page.Margin(36);
            page.PageColor(Colors.White);
            page.DefaultTextStyle(s => s.FontFamily(ReportFonts.Families).FontSize(9.5f).FontColor(Ink));

            page.Header().PaddingBottom(10).BorderBottom(1).BorderColor(Rule).Column(col =>
            {
                col.Item().Row(row =>
                {
                    row.RelativeItem().Text("MolBhav").FontSize(18).Bold().FontColor(Brand);
                    row.RelativeItem().AlignRight().AlignBottom().Text(labels.Title).FontSize(14).Bold();
                });
                col.Item().PaddingTop(4).Text(text =>
                {
                    if (!string.IsNullOrWhiteSpace(data.DisplayName))
                    {
                        text.Span($"{labels.PreparedFor}: ").FontColor(Muted);
                        text.Span($"{data.DisplayName}   ");
                    }

                    text.Span($"{labels.Period}: ").FontColor(Muted);
                    text.Span($"{Date(data.FromDate, dates)} – {Date(data.ToDate, dates)}   ");
                    text.Span($"{labels.Generated}: ").FontColor(Muted);
                    text.Span(Date(DateOnly.FromDateTime(data.GeneratedAtUtc.ToOffset(IndiaOffset).DateTime), dates));
                });
            });

            page.Content().PaddingTop(14).Column(col =>
            {
                col.Spacing(18);
                col.Item().Element(c => Watchlist(c, data.Watchlist, labels, dates));
                col.Item().Element(c => Alerts(c, data.Alerts, labels, dates));
                col.Item().Element(c => Opportunities(c, data.Opportunities, labels));
            });

            page.Footer().AlignCenter().Text(text =>
            {
                text.DefaultTextStyle(s => s.FontSize(8).FontColor(Muted));
                text.Span($"MolBhav · {labels.Page} ");
                text.CurrentPageNumber();
                text.Span(" / ");
                text.TotalPages();
            });
        })).GeneratePdf();
    }

    private static void Watchlist(IContainer container, IReadOnlyList<WatchlistPeriodRow> rows, ReportLabels labels, CultureInfo dates) =>
        Section(container, labels.Watchlist, rows.Count == 0 ? labels.Nothing : null, table =>
        {
            table.ColumnsDefinition(c =>
            {
                c.RelativeColumn(3.2f);
                c.RelativeColumn(1.6f);
                c.RelativeColumn(1.1f);
                c.RelativeColumn(1.4f);
                c.RelativeColumn(1.4f);
            });
            table.Header(h =>
            {
                HeaderCell(h.Cell(), labels.Product);
                HeaderCell(h.Cell(), labels.Latest, right: true);
                HeaderCell(h.Cell(), labels.Change, right: true);
                HeaderCell(h.Cell(), labels.Low, right: true);
                HeaderCell(h.Cell(), labels.High, right: true);
            });
            foreach (var row in rows)
            {
                BodyCell(table.Cell()).Column(c =>
                {
                    c.Item().Text(Named(row.ProductName, row.VariantName));
                    if (row.LastDate is { } last)
                    {
                        c.Item().Text(Date(last, dates)).FontSize(7.5f).FontColor(Muted);
                    }
                });
                Amount(table.Cell(), row.LastPrice, row.UnitSymbol);
                Percent(table.Cell(), row.PercentChange);
                Amount(table.Cell(), row.LowPrice, null);
                Amount(table.Cell(), row.HighPrice, null);
            }
        });

    private static void Alerts(IContainer container, IReadOnlyList<AlertResponse> alerts, ReportLabels labels, CultureInfo dates) =>
        Section(container, labels.Alerts, alerts.Count == 0 ? labels.Nothing : null, table =>
        {
            table.ColumnsDefinition(c =>
            {
                c.RelativeColumn(1.3f);
                c.RelativeColumn(2.4f);
                c.RelativeColumn(2.2f);
                c.RelativeColumn(1.3f);
                c.RelativeColumn(1.3f);
                c.RelativeColumn(1.1f);
            });
            table.Header(h =>
            {
                HeaderCell(h.Cell(), labels.Date);
                HeaderCell(h.Cell(), labels.Product);
                HeaderCell(h.Cell(), labels.Location);
                HeaderCell(h.Cell(), labels.Previous, right: true);
                HeaderCell(h.Cell(), labels.New, right: true);
                HeaderCell(h.Cell(), labels.Change, right: true);
            });
            foreach (var alert in alerts)
            {
                BodyCell(table.Cell()).Text(Date(DateOnly.FromDateTime(alert.TriggeredAtUtc.ToOffset(IndiaOffset).DateTime), dates));
                BodyCell(table.Cell()).Text(Named(alert.Product.Name, alert.VariantName));
                BodyCell(table.Cell()).Text(alert.LocationName ?? "—");
                Amount(table.Cell(), alert.PreviousPrice, null);
                Amount(table.Cell(), alert.NewPrice, null);
                Percent(table.Cell(), alert.PercentChange);
            }
        });

    private static void Opportunities(IContainer container, IReadOnlyList<OpportunitySummary> items, ReportLabels labels) =>
        Section(container, labels.Opportunities, items.Count == 0 ? labels.Nothing : null, table =>
        {
            table.ColumnsDefinition(c =>
            {
                c.RelativeColumn(2.4f);
                c.RelativeColumn(1.3f);
                c.RelativeColumn(2.4f);
                c.RelativeColumn(1.6f);
                c.RelativeColumn(1.5f);
            });
            table.Header(h =>
            {
                HeaderCell(h.Cell(), labels.Product);
                HeaderCell(h.Cell(), labels.Quantity, right: true);
                HeaderCell(h.Cell(), labels.BestLocation);
                HeaderCell(h.Cell(), labels.EstimatedCost, right: true);
                HeaderCell(h.Cell(), labels.Saving, right: true);
            });
            foreach (var item in items)
            {
                BodyCell(table.Cell()).Text(item.ProductName);
                BodyCell(table.Cell()).AlignRight().Text($"{item.Quantity.ToString("#,##0.##", Numbers)} {item.UnitSymbol}");
                BodyCell(table.Cell()).Text(item.LocationName ?? "—");
                Amount(table.Cell(), item.EstimatedCost, null);
                Amount(table.Cell(), item.Saving, null);
            }
        });

    private static void Section(IContainer container, string title, string? emptyMessage, Action<TableDescriptor> table) =>
        container.Column(col =>
        {
            col.Item().PaddingBottom(6).Text(title).FontSize(12).Bold().FontColor(Brand);
            if (emptyMessage is not null)
            {
                col.Item().Text(emptyMessage).FontColor(Muted);
            }
            else
            {
                col.Item().Table(table);
            }
        });

    private static void HeaderCell(IContainer cell, string text, bool right = false)
    {
        var box = cell.Background(HeaderFill).PaddingVertical(5).PaddingHorizontal(6);
        (right ? box.AlignRight() : box).Text(text).FontSize(8.5f).Bold().FontColor(Muted);
    }

    private static IContainer BodyCell(IContainer cell) =>
        cell.BorderBottom(0.5f).BorderColor(Rule).PaddingVertical(5).PaddingHorizontal(6);

    private static void Amount(IContainer cell, decimal? value, string? unitSymbol)
    {
        var text = value is { } v ? $"₹{v.ToString("#,##0.00", Numbers)}" : "—";
        BodyCell(cell).AlignRight().Column(c =>
        {
            c.Item().AlignRight().Text(text);
            if (value is not null && !string.IsNullOrEmpty(unitSymbol))
            {
                c.Item().AlignRight().Text($"/ {unitSymbol}").FontSize(7.5f).FontColor(Muted);
            }
        });
    }

    private static void Percent(IContainer cell, decimal? value)
    {
        var box = BodyCell(cell).AlignRight();
        if (value is not { } v)
        {
            box.Text("—").FontColor(Muted);
            return;
        }

        var sign = v > 0 ? "+" : string.Empty;
        box.Text($"{sign}{v.ToString("0.0", CultureInfo.InvariantCulture)}%").FontColor(v > 0 ? Up : v < 0 ? Down : Muted);
    }

    private static string Named(string product, string? variant) =>
        string.IsNullOrWhiteSpace(variant) ? product : $"{product} · {variant}";

    private static string Date(DateOnly date, CultureInfo culture) => date.ToString("d MMM yyyy", culture);

    /// <summary>Month names in the report language where the runtime has the culture; English otherwise.</summary>
    private static CultureInfo DateCulture(string language)
    {
        try
        {
            return CultureInfo.GetCultureInfo($"{language}-IN");
        }
        catch (CultureNotFoundException)
        {
            return CultureInfo.GetCultureInfo("en-IN");
        }
    }
}
