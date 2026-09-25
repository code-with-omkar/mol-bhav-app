using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Domain.Catalog;

namespace MolBhav.Infrastructure.Persistence.Repositories.Catalog;

internal sealed class UnitOfMeasureRepository(MolBhavDbContext dbContext)
    : Repository<UnitOfMeasure, Guid>(dbContext), IUnitOfMeasureRepository
{
    public override Task<UnitOfMeasure?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        Set.SingleOrDefaultAsync(u => u.Id == id, cancellationToken);

    public Task<bool> CodeExistsAsync(CatalogCode code, CancellationToken cancellationToken = default) =>
        Set.AnyAsync(u => u.Code == code, cancellationToken);

    public Task<bool> ExistsAsync(Guid id, CancellationToken cancellationToken = default) =>
        Set.AnyAsync(u => u.Id == id, cancellationToken);
}
