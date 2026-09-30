using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Domain.Catalog;

namespace MolBhav.Infrastructure.Persistence.Repositories.Catalog;

internal sealed class ProductRepository(MolBhavDbContext dbContext)
    : Repository<Product, Guid>(dbContext), IProductRepository
{
    /// <summary>Loads the whole aggregate: variants (and all owned translations).</summary>
    public override Task<Product?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        Set.Include(p => p.Variants)
            .AsSplitQuery()
            .SingleOrDefaultAsync(p => p.Id == id, cancellationToken);

    public Task<bool> CodeExistsAsync(CatalogCode code, CancellationToken cancellationToken = default) =>
        Set.AnyAsync(p => p.Code == code, cancellationToken);

    public Task<Product?> GetByCodeAsync(CatalogCode code, CancellationToken cancellationToken = default) =>
        Set.Include(p => p.Variants)
            .AsSplitQuery()
            .SingleOrDefaultAsync(p => p.Code == code && p.IsActive, cancellationToken);
}
