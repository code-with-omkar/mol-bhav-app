namespace MolBhav.Domain.Weather;

/// <summary>
/// Offline lookup from a user's profile state to the IMD station that represents it (the state/UT capital — 36 entries,
/// one per state and union territory). <c>UserProfile.State</c> holds the <c>market.states</c> code (<c>MH</c>) but is
/// not constrained to it, so a name also matches — case/punctuation-insensitively, with a few common alternate spellings.
/// A user whose state matches nothing simply gets no forecast; it is never an error.
/// </summary>
public static class ImdStationDirectory
{
    private static readonly ImdStation[] Stations =
    [
        new("amaravati", "Amaravati", "Andhra Pradesh"),
        new("itanagar", "Itanagar", "Arunachal Pradesh"),
        new("guwahati", "Guwahati", "Assam"),
        new("patna", "Patna", "Bihar"),
        new("raipur", "Raipur", "Chhattisgarh"),
        new("panaji", "Panaji", "Goa"),
        new("ahmedabad", "Ahmedabad", "Gujarat"),
        new("chandigarh", "Chandigarh", "Haryana"),
        new("shimla", "Shimla", "Himachal Pradesh"),
        new("ranchi", "Ranchi", "Jharkhand"),
        new("bengaluru", "Bengaluru", "Karnataka"),
        new("thiruvananthapuram", "Thiruvananthapuram", "Kerala"),
        new("bhopal", "Bhopal", "Madhya Pradesh"),
        new("mumbai", "Mumbai", "Maharashtra"),
        new("imphal", "Imphal", "Manipur"),
        new("shillong", "Shillong", "Meghalaya"),
        new("aizawl", "Aizawl", "Mizoram"),
        new("kohima", "Kohima", "Nagaland"),
        new("bhubaneswar", "Bhubaneswar", "Odisha"),
        new("ludhiana", "Ludhiana", "Punjab"),
        new("jaipur", "Jaipur", "Rajasthan"),
        new("gangtok", "Gangtok", "Sikkim"),
        new("chennai", "Chennai", "Tamil Nadu"),
        new("hyderabad", "Hyderabad", "Telangana"),
        new("agartala", "Agartala", "Tripura"),
        new("lucknow", "Lucknow", "Uttar Pradesh"),
        new("dehradun", "Dehradun", "Uttarakhand"),
        new("kolkata", "Kolkata", "West Bengal"),
        new("port-blair", "Port Blair", "Andaman and Nicobar Islands"),
        new("chandigarh-ut", "Chandigarh", "Chandigarh"),
        new("daman", "Daman", "Dadra and Nagar Haveli and Daman and Diu"),
        new("delhi", "New Delhi", "Delhi"),
        new("srinagar", "Srinagar", "Jammu and Kashmir"),
        new("leh", "Leh", "Ladakh"),
        new("kavaratti", "Kavaratti", "Lakshadweep"),
        new("puducherry", "Puducherry", "Puducherry"),
    ];

    private static readonly Dictionary<string, string> Aliases = new()
    {
        ["orissa"] = "odisha",
        ["pondicherry"] = "puducherry",
        ["uttaranchal"] = "uttarakhand",
        ["nct of delhi"] = "delhi",
        ["new delhi"] = "delhi",
        ["andaman nicobar islands"] = "andaman and nicobar islands",
        ["dadra and nagar haveli"] = "dadra and nagar haveli and daman and diu",
        ["daman and diu"] = "dadra and nagar haveli and daman and diu",
        ["jammu kashmir"] = "jammu and kashmir",
    };

    /// <summary>The codes of the <c>market.states</c> master (what onboarding stores in <c>UserProfile.State</c>) → state name.</summary>
    private static readonly Dictionary<string, string> StateCodes = new(StringComparer.OrdinalIgnoreCase)
    {
        ["AN"] = "Andaman and Nicobar Islands", ["AP"] = "Andhra Pradesh", ["AR"] = "Arunachal Pradesh", ["AS"] = "Assam",
        ["BR"] = "Bihar", ["CG"] = "Chhattisgarh", ["CH"] = "Chandigarh", ["DH"] = "Dadra and Nagar Haveli and Daman and Diu",
        ["DL"] = "Delhi", ["GA"] = "Goa", ["GJ"] = "Gujarat", ["HP"] = "Himachal Pradesh", ["HR"] = "Haryana",
        ["JH"] = "Jharkhand", ["JK"] = "Jammu and Kashmir", ["KA"] = "Karnataka", ["KL"] = "Kerala", ["LA"] = "Ladakh",
        ["LD"] = "Lakshadweep", ["MH"] = "Maharashtra", ["ML"] = "Meghalaya", ["MN"] = "Manipur", ["MP"] = "Madhya Pradesh",
        ["MZ"] = "Mizoram", ["NL"] = "Nagaland", ["OD"] = "Odisha", ["PB"] = "Punjab", ["PY"] = "Puducherry",
        ["RJ"] = "Rajasthan", ["SK"] = "Sikkim", ["TN"] = "Tamil Nadu", ["TR"] = "Tripura", ["TS"] = "Telangana",
        ["UK"] = "Uttarakhand", ["UP"] = "Uttar Pradesh", ["WB"] = "West Bengal",
    };

    private static readonly Dictionary<string, ImdStation> ByState =
        Stations.ToDictionary(s => Normalise(s.State), s => s);

    public static IReadOnlyList<ImdStation> All => Stations;

    /// <summary>The station for a profile state — a <c>market.states</c> code (<c>MH</c>) or a name — or null when blank or unrecognised.</summary>
    public static ImdStation? ForState(string? state)
    {
        var trimmed = state?.Trim();
        var key = Normalise(trimmed is not null && StateCodes.TryGetValue(trimmed, out var named) ? named : trimmed);
        if (key.Length == 0)
        {
            return null;
        }

        if (Aliases.TryGetValue(key, out var canonical))
        {
            key = canonical;
        }

        return ByState.GetValueOrDefault(key);
    }

    private static string Normalise(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        var chars = value.Trim().ToLowerInvariant()
            .Select(c => char.IsLetterOrDigit(c) ? c : ' ')
            .ToArray();
        return string.Join(' ', new string(chars).Split(' ', StringSplitOptions.RemoveEmptyEntries));
    }
}
