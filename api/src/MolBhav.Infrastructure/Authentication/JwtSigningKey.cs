using System.Text;
using Microsoft.IdentityModel.Tokens;

namespace MolBhav.Infrastructure.Authentication;

internal static class JwtSigningKey
{
    public const string Algorithm = SecurityAlgorithms.HmacSha256;

    public static SymmetricSecurityKey Create(string signingKey) => new(Encoding.UTF8.GetBytes(signingKey));
}
