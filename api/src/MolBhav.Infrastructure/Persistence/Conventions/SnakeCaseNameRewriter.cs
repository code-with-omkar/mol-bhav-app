using System.Text;

namespace MolBhav.Infrastructure.Persistence.Conventions;

/// <summary>PascalCase → snake_case, acronym-aware: <c>HTTPRequestId</c> → <c>http_request_id</c>, <c>PK_OutboxMessage</c> → <c>pk_outbox_message</c>.</summary>
internal static class SnakeCaseNameRewriter
{
    public static string Rewrite(string name)
    {
        if (string.IsNullOrEmpty(name))
        {
            return name;
        }

        var builder = new StringBuilder(name.Length + 8);

        for (var i = 0; i < name.Length; i++)
        {
            var current = name[i];

            if (current is '_' or ' ' or '-' or '.')
            {
                if (builder.Length > 0 && builder[^1] != '_')
                {
                    builder.Append('_');
                }

                continue;
            }

            if (char.IsUpper(current))
            {
                var previous = i > 0 ? name[i - 1] : '\0';
                var next = i + 1 < name.Length ? name[i + 1] : '\0';

                var startsNewWord =
                    char.IsLower(previous) || char.IsDigit(previous) || (char.IsUpper(previous) && char.IsLower(next));

                if (startsNewWord && builder.Length > 0 && builder[^1] != '_')
                {
                    builder.Append('_');
                }

                builder.Append(char.ToLowerInvariant(current));
                continue;
            }

            builder.Append(current);
        }

        return builder.ToString();
    }
}
