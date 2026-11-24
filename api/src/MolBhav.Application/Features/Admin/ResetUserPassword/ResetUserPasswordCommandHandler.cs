using System.Security.Cryptography;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Identity;

namespace MolBhav.Application.Features.Admin.ResetUserPassword;

internal sealed class ResetUserPasswordCommandHandler(
    IUserRepository users,
    IPasswordHasher passwordHasher,
    IRefreshTokenRepository refreshTokens,
    TimeProvider timeProvider)
    : ICommandHandler<ResetUserPasswordCommand, ResetUserPasswordResponse>
{
    // No 0/O/1/l/I: the password is read out or typed from a screen.
    private const string Alphabet = "abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    private const int Length = 12;

    public async Task<Result<ResetUserPasswordResponse>> Handle(ResetUserPasswordCommand request, CancellationToken cancellationToken)
    {
        if (request.UserId == request.ActingUserId)
        {
            return Error.Forbidden("User.CannotResetOwnPassword", "Use Change password for your own account.");
        }

        var user = await users.GetByIdAsync(request.UserId, cancellationToken);
        if (user is null)
        {
            return Error.NotFound("User.NotFound", "User not found.");
        }

        if (user.Role == UserRole.Admin)
        {
            return Error.Forbidden("User.AdminPasswordNotResettable", "An admin account's password cannot be reset by another admin.");
        }

        var password = NewTemporaryPassword();
        user.SetPassword(passwordHasher.Hash(password));

        // Whoever knew the old password (or held a session) is signed out; only the new password gets back in.
        var now = timeProvider.GetUtcNow();
        foreach (var grant in await refreshTokens.GetActiveForUserAsync(user.Id, cancellationToken))
        {
            grant.Revoke(now);
        }

        return new ResetUserPasswordResponse(password);
    }

    /// <summary>Always has a letter and a digit, so it passes the same rules a user's own password must.</summary>
    private static string NewTemporaryPassword()
    {
        string candidate;
        do
        {
            candidate = string.Concat(Enumerable.Range(0, Length).Select(_ => Alphabet[RandomNumberGenerator.GetInt32(Alphabet.Length)]));
        }
        while (!candidate.Any(char.IsLetter) || !candidate.Any(char.IsDigit));

        return candidate;
    }
}
