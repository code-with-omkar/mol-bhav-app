using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.Reporting;

namespace MolBhav.Application.Abstractions.Reporting;

public interface IReportRepository : IRepository<Report, Guid>
{
}
