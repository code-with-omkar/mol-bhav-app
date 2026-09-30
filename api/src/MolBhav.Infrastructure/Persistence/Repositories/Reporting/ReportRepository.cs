using MolBhav.Application.Abstractions.Reporting;
using MolBhav.Domain.Reporting;
using MolBhav.Infrastructure.Persistence.Repositories;

namespace MolBhav.Infrastructure.Persistence.Repositories.Reporting;

internal sealed class ReportRepository(MolBhavDbContext dbContext) : Repository<Report, Guid>(dbContext), IReportRepository
{
}
