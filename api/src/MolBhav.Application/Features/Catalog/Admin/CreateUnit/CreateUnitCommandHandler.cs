using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Catalog.Admin.CreateUnit;

internal sealed class CreateUnitCommandHandler(IUnitOfMeasureRepository units, ILanguageContext languageContext)
    : ICommandHandler<CreateUnitCommand, CreatedResponse>
{
    public async Task<Result<CreatedResponse>> Handle(CreateUnitCommand request, CancellationToken cancellationToken)
    {
        var code = CatalogCode.Create(request.Code);
        if (code.IsFailure)
        {
            return Result.Failure<CreatedResponse>(code.Error);
        }

        if (await units.CodeExistsAsync(code.Value, cancellationToken))
        {
            return Error.Conflict("UnitOfMeasure.CodeTaken", $"Unit '{code.Value.Value}' already exists.");
        }

        var translations = CatalogTranslationMapper.ToDomain(request.Translations, languageContext.SupportedLanguages);
        if (translations.IsFailure)
        {
            return Result.Failure<CreatedResponse>(translations.Error);
        }

        var unit = UnitOfMeasure.Create(code.Value, request.Symbol, request.Dimension!.Value, request.ToBaseFactor!.Value, translations.Value);
        if (unit.IsFailure)
        {
            return Result.Failure<CreatedResponse>(unit.Error);
        }

        units.Add(unit.Value);
        return new CreatedResponse(unit.Value.Id);
    }
}
