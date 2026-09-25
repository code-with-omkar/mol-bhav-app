using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Abstractions.Catalog;

/// <summary><see cref="IRepository{TAggregate,TId}.GetByIdAsync"/> loads the category with all its sub-categories and translations.</summary>
public interface IProcurementCategoryRepository : IRepository<ProcurementCategory, Guid>
{
    Task<bool> CodeExistsAsync(ProcurementCategoryCode code, CancellationToken cancellationToken = default);

    Task<bool> SubCategoryExistsAsync(Guid subCategoryId, CancellationToken cancellationToken = default);
}

/// <summary><see cref="IRepository{TAggregate,TId}.GetByIdAsync"/> loads the product with all its variants and translations.</summary>
public interface IProductRepository : IRepository<Product, Guid>
{
    Task<bool> CodeExistsAsync(CatalogCode code, CancellationToken cancellationToken = default);
}

public interface IUnitOfMeasureRepository : IRepository<UnitOfMeasure, Guid>
{
    Task<bool> CodeExistsAsync(CatalogCode code, CancellationToken cancellationToken = default);

    Task<bool> ExistsAsync(Guid id, CancellationToken cancellationToken = default);
}
