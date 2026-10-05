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

    public async Task<Guid?> GetActiveIdByCodeAsync(ProcurementCategoryCode code, CancellationToken cancellationToken = default) =>
        await Set.AsNoTracking()
            .Where(c => c.Code == code && c.IsActive)
            .Select(c => (Guid?)c.Id)
            .SingleOrDefaultAsync(cancellationToken);

    public async Task<IReadOnlySet<Guid>> GetSubCategoryIdsAsync(Guid categoryId, CancellationToken cancellationToken = default)
    {
        var ids = await DbContext.Set<SubCategory>().AsNoTracking()
            .Where(s => s.CategoryId == categoryId)
            .Select(s => s.Id)
            .ToListAsync(cancellationToken);
        return ids.ToHashSet();
    }
}
