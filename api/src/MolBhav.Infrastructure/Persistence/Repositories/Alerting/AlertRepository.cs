using MolBhav.Application.Abstractions.Alerting;
using MolBhav.Domain.Alerting;
using MolBhav.Infrastructure.Persistence.Repositories;

namespace MolBhav.Infrastructure.Persistence.Repositories.Alerting;

internal sealed class AlertRepository(MolBhavDbContext dbContext) : Repository<Alert, Guid>(dbContext), IAlertRepository
{
}
