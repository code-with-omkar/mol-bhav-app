using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.Market;

namespace MolBhav.Application.Abstractions.Market;

/// <summary><see cref="IRepository{TAggregate,TId}.GetByIdAsync"/> loads the state with all its districts.</summary>
public interface IStateRepository : IRepository<State, Guid>
{
    Task<bool> NameExistsAsync(string name, CancellationToken cancellationToken = default);

    Task<bool> CodeExistsAsync(string code, CancellationToken cancellationToken = default);

    Task<bool> DistrictExistsAsync(Guid districtId, CancellationToken cancellationToken = default);
}

public interface IMandiRepository : IRepository<Mandi, Guid>
{
    Task<bool> CodeExistsAsync(MarketCode code, CancellationToken cancellationToken = default);

    /// <summary>Used by ingestion to resolve a source's location code onto a mandi. Null when unknown or inactive.</summary>
    Task<Mandi?> GetByCodeAsync(MarketCode code, CancellationToken cancellationToken = default);
}

public interface ISupplierRepository : IRepository<Supplier, Guid>
{
    Task<bool> CodeExistsAsync(MarketCode code, CancellationToken cancellationToken = default);

    /// <summary>Used by ingestion to resolve a source's location code onto a supplier. Null when unknown or inactive.</summary>
    Task<Supplier?> GetByCodeAsync(MarketCode code, CancellationToken cancellationToken = default);
}
