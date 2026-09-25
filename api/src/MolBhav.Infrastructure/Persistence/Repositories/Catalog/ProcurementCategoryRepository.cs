using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Infrastructure.Persistence.Repositories.Catalog;

internal sealed class ProcurementCategoryRepository(MolBhavDbContext dbContext)
    : Repository<ProcurementCategory, Guid>(dbContext), IProcurementCategoryRepository
{
    /// <summary>Loads the whole aggregate: sub-categories (and all owned translations, which EF always includes).</summary>
    public override Task<ProcurementCategory?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        Set.Include(c => c.SubCategories)
            .AsSplitQuery()
            .SingleOrDefaultAsync(c => c.Id == id, cancellationToken);

    public Task<bool> CodeExistsAsync(ProcurementCategoryCode code, CancellationToken cancellationToken = default) =>
        Set.AnyAsync(c => c.Code == code, cancellationToken);

    public Task<bool> SubCategoryExistsAsync(Guid subCategoryId, CancellationToken cancellationToken = default) =>
        DbContext.Set<SubCategory>().AnyAsync(s => s.Id == subCategoryId, cancellationToken);
}
