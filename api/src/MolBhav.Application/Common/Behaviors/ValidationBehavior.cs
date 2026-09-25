using FluentValidation;
using MediatR;
using MolBhav.Application.Common.Exceptions;

namespace MolBhav.Application.Common.Behaviors;

/// <summary>
/// Runs every FluentValidation validator registered for the request before the handler.
/// Validators run sequentially: async rules may hit the scoped DbContext, which is not thread-safe.
/// </summary>
internal sealed class ValidationBehavior<TRequest, TResponse>(IEnumerable<IValidator<TRequest>> validators)
    : IPipelineBehavior<TRequest, TResponse>
    where TRequest : notnull
{
    private readonly IValidator<TRequest>[] _validators = validators.ToArray();

    public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken cancellationToken)
    {
        if (_validators.Length == 0)
        {
            return await next();
        }

        var context = new ValidationContext<TRequest>(request);
        var failures = new List<FluentValidation.Results.ValidationFailure>();

        foreach (var validator in _validators)
        {
            var result = await validator.ValidateAsync(context, cancellationToken);
            failures.AddRange(result.Errors);
        }

        if (failures.Count != 0)
        {
            var errors = failures
                .GroupBy(f => f.PropertyName, StringComparer.Ordinal)
                .ToDictionary(
                    g => g.Key,
                    g => g.Select(f => f.ErrorMessage).Distinct(StringComparer.Ordinal).ToArray(),
                    StringComparer.Ordinal);

            throw new RequestValidationException(errors);
        }

        return await next();
    }
}
