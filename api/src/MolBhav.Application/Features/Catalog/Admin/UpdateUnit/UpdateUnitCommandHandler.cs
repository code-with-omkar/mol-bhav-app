using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Catalog.Admin.UpdateUnit;

internal sealed class UpdateUnitCommandHandler(IUnitOfMeasureRepository units, ILanguageContext languageContext)
    : ICommandHandler<UpdateUnitCommand>
{
    public async Task<Result> Handle(UpdateUnitCommand request, CancellationToken cancellationToken)
    {
        var unit = await units.GetByIdAsync(request.UnitId, cancellationToken);
        if (unit is null)
        {
            return Error.NotFound("UnitOfMeasure.NotFound", "Unit not found.");
        }

        var translations = CatalogTranslationMapper.ToDomain(request.Translations, languageContext.SupportedLanguages);
        if (translations.IsFailure)
        {
            return translations.Error;
        }

        return unit.Update(request.Symbol, request.IsActive!.Value, translations.Value);
    }
}
