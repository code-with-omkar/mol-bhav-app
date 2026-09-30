namespace MolBhav.Infrastructure.Reporting;

/// <summary>Fixed PDF headings per supported language; data names (products, mandis) come localized from the catalog.</summary>
internal sealed record ReportLabels(
    string Title,
    string PreparedFor,
    string Period,
    string Generated,
    string Watchlist,
    string Product,
    string Latest,
    string Change,
    string Low,
    string High,
    string Alerts,
    string Date,
    string Location,
    string Previous,
    string New,
    string Opportunities,
    string Quantity,
    string BestLocation,
    string EstimatedCost,
    string Saving,
    string Nothing,
    string Page)
{
    private static readonly ReportLabels English = new(
        "Weekly summary", "Prepared for", "Period", "Generated", "Watchlist prices", "Product", "Latest", "Change",
        "Low", "High", "Alerts triggered", "Date", "Location", "Previous", "New", "Sourcing opportunities", "Quantity",
        "Best location", "Estimated cost", "Saving vs target", "Nothing in this period.", "Page");

    private static readonly Dictionary<string, ReportLabels> ByLanguage = new(StringComparer.OrdinalIgnoreCase)
    {
        ["en"] = English,
        ["hi"] = new(
            "साप्ताहिक सारांश", "किसके लिए", "अवधि", "बनाया गया", "वॉचलिस्ट कीमतें", "उत्पाद", "नवीनतम", "बदलाव",
            "न्यूनतम", "अधिकतम", "ट्रिगर हुए अलर्ट", "तारीख", "स्थान", "पिछली", "नई", "खरीद के अवसर", "मात्रा",
            "सबसे अच्छा स्थान", "अनुमानित लागत", "लक्ष्य से बचत", "इस अवधि में कुछ नहीं।", "पृष्ठ"),
        ["mr"] = new(
            "साप्ताहिक सारांश", "यांच्यासाठी", "कालावधी", "तयार केले", "वॉचलिस्ट किमती", "उत्पादन", "नवीनतम", "बदल",
            "किमान", "कमाल", "ट्रिगर झालेले अलर्ट", "तारीख", "ठिकाण", "मागील", "नवीन", "खरेदीच्या संधी", "प्रमाण",
            "सर्वोत्तम ठिकाण", "अंदाजित खर्च", "लक्ष्यापेक्षा बचत", "या कालावधीत काहीही नाही.", "पान"),
        ["gu"] = new(
            "સાપ્તાહિક સારાંશ", "કોના માટે", "સમયગાળો", "બનાવ્યું", "વોચલિસ્ટ ભાવ", "ઉત્પાદન", "તાજેતરનો", "ફેરફાર",
            "ન્યૂનતમ", "મહત્તમ", "ટ્રિગર થયેલ એલર્ટ", "તારીખ", "સ્થળ", "અગાઉનો", "નવો", "ખરીદીની તકો", "જથ્થો",
            "શ્રેષ્ઠ સ્થળ", "અંદાજિત ખર્ચ", "લક્ષ્યથી બચત", "આ સમયગાળામાં કંઈ નથી.", "પાનું"),
        ["ta"] = new(
            "வாராந்திர சுருக்கம்", "யாருக்காக", "காலம்", "உருவாக்கப்பட்டது", "கண்காணிப்பு பட்டியல் விலைகள்", "பொருள்", "சமீபத்திய", "மாற்றம்",
            "குறைந்த", "அதிக", "தூண்டப்பட்ட எச்சரிக்கைகள்", "தேதி", "இடம்", "முந்தைய", "புதிய", "கொள்முதல் வாய்ப்புகள்", "அளவு",
            "சிறந்த இடம்", "மதிப்பிடப்பட்ட செலவு", "இலக்கை விட சேமிப்பு", "இந்த காலத்தில் எதுவும் இல்லை.", "பக்கம்"),
        ["te"] = new(
            "వారపు సారాంశం", "ఎవరి కోసం", "వ్యవధి", "రూపొందించబడింది", "వాచ్‌లిస్ట్ ధరలు", "ఉత్పత్తి", "తాజా", "మార్పు",
            "కనిష్ఠ", "గరిష్ఠ", "ట్రిగర్ అయిన అలర్ట్‌లు", "తేదీ", "ప్రదేశం", "మునుపటి", "కొత్త", "కొనుగోలు అవకాశాలు", "పరిమాణం",
            "ఉత్తమ ప్రదేశం", "అంచనా వ్యయం", "లక్ష్యం కంటే ఆదా", "ఈ వ్యవధిలో ఏమీ లేదు.", "పేజీ"),
        ["kn"] = new(
            "ವಾರದ ಸಾರಾಂಶ", "ಯಾರಿಗಾಗಿ", "ಅವಧಿ", "ರಚಿಸಲಾಗಿದೆ", "ವಾಚ್‌ಲಿಸ್ಟ್ ಬೆಲೆಗಳು", "ಉತ್ಪನ್ನ", "ಇತ್ತೀಚಿನ", "ಬದಲಾವಣೆ",
            "ಕನಿಷ್ಠ", "ಗರಿಷ್ಠ", "ಪ್ರಚೋದಿತ ಎಚ್ಚರಿಕೆಗಳು", "ದಿನಾಂಕ", "ಸ್ಥಳ", "ಹಿಂದಿನ", "ಹೊಸ", "ಖರೀದಿ ಅವಕಾಶಗಳು", "ಪ್ರಮಾಣ",
            "ಉತ್ತಮ ಸ್ಥಳ", "ಅಂದಾಜು ವೆಚ್ಚ", "ಗುರಿಗಿಂತ ಉಳಿತಾಯ", "ಈ ಅವಧಿಯಲ್ಲಿ ಏನೂ ಇಲ್ಲ.", "ಪುಟ"),
    };

    public static ReportLabels For(string? language) =>
        language is not null && ByLanguage.TryGetValue(language, out var labels) ? labels : English;
}
