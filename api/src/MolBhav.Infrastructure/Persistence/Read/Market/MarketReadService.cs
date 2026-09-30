using Dapper;
using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Market.Models;
using MolBhav.Infrastructure.Persistence.Configurations.Market;

namespace MolBhav.Infrastructure.Persistence.Read.Market;

/// <summary>
/// Market/location reads for the mobile screens (active items only) and the admin portal (inactive included).
/// All SQL is parameterised; table names are compile-time constants. Names here are plain strings, unlike Catalog —
/// no per-language translation for states/districts/mandis/suppliers yet.
/// </summary>
internal sealed class MarketReadService(IDbConnectionFactory connectionFactory) : IMarketReadService
{
    private const string States = Schemas.Market + "." + StateConfiguration.TableName;
    private const string Districts = Schemas.Market + "." + DistrictConfiguration.TableName;
    private const string Mandis = Schemas.Market + "." + MandiConfiguration.TableName;
    private const string Suppliers = Schemas.Market + "." + SupplierConfiguration.TableName;

    private const string StatesSql = $"""
        SELECT s.id, s.name, s.code FROM {States} s WHERE s.is_active ORDER BY s.name;
        """;

    private const string DistrictsSql = $"""
        SELECT s.id FROM {States} s WHERE s.id = @StateId AND s.is_active;

        SELECT d.id, d.name FROM {Districts} d WHERE d.state_id = @StateId AND d.is_active ORDER BY d.name;
        """;

    private const string MandiListFrom = $"""
        FROM {Mandis} m
        JOIN {Districts} d ON d.id = m.district_id
        JOIN {States} s ON s.id = d.state_id
        """;

    private const string MandiListWhere = $"""
        WHERE m.is_active AND d.is_active AND s.is_active
          AND (@DistrictId::uuid IS NULL OR m.district_id = @DistrictId::uuid)
          AND (@Pattern::text IS NULL OR m.code ILIKE @Pattern::text OR m.name ILIKE @Pattern::text)
        """;

    private static readonly string MandiListSql = $"""
        SELECT count(*)
        {MandiListFrom}
        {MandiListWhere};

        SELECT m.id, m.code, m.name, m.district_id, d.name AS district_name, s.name AS state_name
        {MandiListFrom}
        {MandiListWhere}
        ORDER BY s.name, d.name, m.name
        LIMIT @Limit OFFSET @Offset;
        """;

    private const string SupplierListFrom = $"""
        FROM {Suppliers} sup
        JOIN {Districts} d ON d.id = sup.district_id
        JOIN {States} s ON s.id = d.state_id
        """;

    private const string SupplierListWhere = $"""
        WHERE sup.is_active AND d.is_active AND s.is_active
          AND (@DistrictId::uuid IS NULL OR sup.district_id = @DistrictId::uuid)
          AND (@Pattern::text IS NULL OR sup.code ILIKE @Pattern::text OR sup.name ILIKE @Pattern::text)
        """;

    private static readonly string SupplierListSql = $"""
        SELECT count(*)
        {SupplierListFrom}
        {SupplierListWhere};

        SELECT sup.id, sup.code, sup.name, sup.district_id, d.name AS district_name, s.name AS state_name, sup.contact_phone
        {SupplierListFrom}
        {SupplierListWhere}
        ORDER BY s.name, d.name, sup.name
        LIMIT @Limit OFFSET @Offset;
        """;

    private const string AdminStatesSql = $"""
        SELECT s.id, s.name, s.code, s.is_active FROM {States} s ORDER BY s.name;

        SELECT d.id, d.state_id, d.name, d.is_active FROM {Districts} d ORDER BY d.name;
        """;

    private const string AdminMandiListFrom = $"""
        FROM {Mandis} m
        JOIN {Districts} d ON d.id = m.district_id
        """;

    private const string AdminMandiListWhere = $"""
        WHERE (@DistrictId::uuid IS NULL OR m.district_id = @DistrictId::uuid)
          AND (@IsActive::boolean IS NULL OR m.is_active = @IsActive::boolean)
          AND (@Pattern::text IS NULL OR m.code ILIKE @Pattern::text OR m.name ILIKE @Pattern::text)
        """;

    private static readonly string AdminMandiListSql = $"""
        SELECT count(*)
        {AdminMandiListFrom}
        {AdminMandiListWhere};

        SELECT m.id, m.code, m.name, m.district_id, d.name AS district_name, m.is_active
        {AdminMandiListFrom}
        {AdminMandiListWhere}
        ORDER BY d.name, m.name
        LIMIT @Limit OFFSET @Offset;
        """;

    private const string AdminSupplierListFrom = $"""
        FROM {Suppliers} sup
        JOIN {Districts} d ON d.id = sup.district_id
        """;

    private const string AdminSupplierListWhere = $"""
        WHERE (@DistrictId::uuid IS NULL OR sup.district_id = @DistrictId::uuid)
          AND (@IsActive::boolean IS NULL OR sup.is_active = @IsActive::boolean)
          AND (@Pattern::text IS NULL OR sup.code ILIKE @Pattern::text OR sup.name ILIKE @Pattern::text)
        """;

    private static readonly string AdminSupplierListSql = $"""
        SELECT count(*)
        {AdminSupplierListFrom}
        {AdminSupplierListWhere};

        SELECT sup.id, sup.code, sup.name, sup.district_id, d.name AS district_name, sup.contact_phone, sup.is_active
        {AdminSupplierListFrom}
        {AdminSupplierListWhere}
        ORDER BY d.name, sup.name
        LIMIT @Limit OFFSET @Offset;
        """;

    public async Task<IReadOnlyList<StateResponse>> GetStatesAsync(CancellationToken cancellationToken = default)
    {
        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = await connection.QueryAsync<StateRow>(Command(StatesSql, null, cancellationToken));
        return rows.Select(s => new StateResponse(s.Id, s.Name, s.Code)).ToArray();
    }

    public async Task<IReadOnlyList<DistrictResponse>?> GetDistrictsAsync(Guid stateId, CancellationToken cancellationToken = default)
    {
        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(DistrictsSql, new { StateId = stateId }, cancellationToken));

        var activeStateId = await grid.ReadSingleOrDefaultAsync<Guid?>();
        if (activeStateId is null)
        {
            return null;
        }

        var districts = await grid.ReadAsync<DistrictRow>();
        return districts.Select(d => new DistrictResponse(d.Id, d.Name)).ToArray();
    }

    public async Task<PagedResult<MandiResponse>> GetMandisAsync(
        Guid? districtId,
        string? search,
        PageRequest page,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(page);

        var args = new DynamicParameters();
        args.Add("DistrictId", districtId);
        args.Add("Pattern", ContainsPattern(search));
        args.Add("Limit", page.PageSize);
        args.Add("Offset", page.Offset);

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(MandiListSql, args, cancellationToken));

        var total = await grid.ReadSingleAsync<long>();
        var items = (await grid.ReadAsync<MandiRow>())
            .Select(m => new MandiResponse(m.Id, m.Code, m.Name, m.DistrictId, m.DistrictName, m.StateName))
            .ToArray();

        return new PagedResult<MandiResponse>(items, page.Page, page.PageSize, total);
    }

    public async Task<PagedResult<SupplierResponse>> GetSuppliersAsync(
        Guid? districtId,
        string? search,
        PageRequest page,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(page);

        var args = new DynamicParameters();
        args.Add("DistrictId", districtId);
        args.Add("Pattern", ContainsPattern(search));
        args.Add("Limit", page.PageSize);
        args.Add("Offset", page.Offset);

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(SupplierListSql, args, cancellationToken));

        var total = await grid.ReadSingleAsync<long>();
        var items = (await grid.ReadAsync<SupplierRow>())
            .Select(s => new SupplierResponse(s.Id, s.Code, s.Name, s.DistrictId, s.DistrictName, s.StateName, s.ContactPhone))
            .ToArray();

        return new PagedResult<SupplierResponse>(items, page.Page, page.PageSize, total);
    }

    public async Task<IReadOnlyList<AdminStateResponse>> GetAdminStatesAsync(CancellationToken cancellationToken = default)
    {
        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(AdminStatesSql, null, cancellationToken));

        var states = (await grid.ReadAsync<AdminStateRow>()).AsList();
        var districts = (await grid.ReadAsync<AdminDistrictRow>()).ToLookup(d => d.StateId);

        return states
            .Select(s => new AdminStateResponse(
                s.Id,
                s.Name,
                s.Code,
                s.IsActive,
                districts[s.Id].Select(d => new AdminDistrictResponse(d.Id, d.Name, d.IsActive)).ToArray()))
            .ToArray();
    }

    public async Task<PagedResult<AdminMandiResponse>> GetAdminMandisAsync(
        Guid? districtId,
        string? search,
        bool? isActive,
        PageRequest page,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(page);

        var args = new DynamicParameters();
        args.Add("DistrictId", districtId);
        args.Add("IsActive", isActive);
        args.Add("Pattern", ContainsPattern(search));
        args.Add("Limit", page.PageSize);
        args.Add("Offset", page.Offset);

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(AdminMandiListSql, args, cancellationToken));

        var total = await grid.ReadSingleAsync<long>();
        var items = (await grid.ReadAsync<AdminMandiRow>())
            .Select(m => new AdminMandiResponse(m.Id, m.Code, m.Name, m.DistrictId, m.DistrictName, m.IsActive))
            .ToArray();

        return new PagedResult<AdminMandiResponse>(items, page.Page, page.PageSize, total);
    }

    public async Task<PagedResult<AdminSupplierResponse>> GetAdminSuppliersAsync(
        Guid? districtId,
        string? search,
        bool? isActive,
        PageRequest page,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(page);

        var args = new DynamicParameters();
        args.Add("DistrictId", districtId);
        args.Add("IsActive", isActive);
        args.Add("Pattern", ContainsPattern(search));
        args.Add("Limit", page.PageSize);
        args.Add("Offset", page.Offset);

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(AdminSupplierListSql, args, cancellationToken));

        var total = await grid.ReadSingleAsync<long>();
        var items = (await grid.ReadAsync<AdminSupplierRow>())
            .Select(s => new AdminSupplierResponse(s.Id, s.Code, s.Name, s.DistrictId, s.DistrictName, s.ContactPhone, s.IsActive))
            .ToArray();

        return new PagedResult<AdminSupplierResponse>(items, page.Page, page.PageSize, total);
    }

    /// <summary>ILIKE "contains" pattern with the user's text escaped, so % and _ are matched literally.</summary>
    private static string? ContainsPattern(string? search)
    {
        if (string.IsNullOrWhiteSpace(search))
        {
            return null;
        }

        var escaped = search.Trim()
            .Replace(@"\", @"\\", StringComparison.Ordinal)
            .Replace("%", @"\%", StringComparison.Ordinal)
            .Replace("_", @"\_", StringComparison.Ordinal);

        return $"%{escaped}%";
    }

    private static CommandDefinition Command(string sql, object? args, CancellationToken cancellationToken) =>
        new(sql, args, cancellationToken: cancellationToken);

    // Flat row shapes for Dapper (snake_case → PascalCase via MatchNamesWithUnderscores).
#pragma warning disable CA1812 // Instantiated by Dapper.
    private sealed class StateRow
    {
        public Guid Id { get; init; }

        public string Name { get; init; } = string.Empty;

        public string Code { get; init; } = string.Empty;
    }

    private sealed class DistrictRow
    {
        public Guid Id { get; init; }

        public string Name { get; init; } = string.Empty;
    }

    private sealed class MandiRow
    {
        public Guid Id { get; init; }

        public string Code { get; init; } = string.Empty;

        public string Name { get; init; } = string.Empty;

        public Guid DistrictId { get; init; }

        public string DistrictName { get; init; } = string.Empty;

        public string StateName { get; init; } = string.Empty;
    }

    private sealed class SupplierRow
    {
        public Guid Id { get; init; }

        public string Code { get; init; } = string.Empty;

        public string Name { get; init; } = string.Empty;

        public Guid DistrictId { get; init; }

        public string DistrictName { get; init; } = string.Empty;

        public string StateName { get; init; } = string.Empty;

        public string? ContactPhone { get; init; }
    }

    private sealed class AdminStateRow
    {
        public Guid Id { get; init; }

        public string Name { get; init; } = string.Empty;

        public string Code { get; init; } = string.Empty;

        public bool IsActive { get; init; }
    }

    private sealed class AdminDistrictRow
    {
        public Guid Id { get; init; }

        public Guid StateId { get; init; }

        public string Name { get; init; } = string.Empty;

        public bool IsActive { get; init; }
    }

    private sealed class AdminMandiRow
    {
        public Guid Id { get; init; }

        public string Code { get; init; } = string.Empty;

        public string Name { get; init; } = string.Empty;

        public Guid DistrictId { get; init; }

        public string DistrictName { get; init; } = string.Empty;

        public bool IsActive { get; init; }
    }

    private sealed class AdminSupplierRow
    {
        public Guid Id { get; init; }

        public string Code { get; init; } = string.Empty;

        public string Name { get; init; } = string.Empty;

        public Guid DistrictId { get; init; }

        public string DistrictName { get; init; } = string.Empty;

        public string? ContactPhone { get; init; }

        public bool IsActive { get; init; }
    }
#pragma warning restore CA1812
}
