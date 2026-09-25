// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'MolBhav';

  @override
  String get retry => 'फिर से कोशिश करें';

  @override
  String get back => 'वापस';

  @override
  String get loading => 'लोड हो रहा है';

  @override
  String get errorNetwork =>
      'इंटरनेट कनेक्शन नहीं है। अपना नेटवर्क जाँचें और फिर से कोशिश करें।';

  @override
  String get errorServer =>
      'हमारी ओर से कुछ गड़बड़ हुई। कृपया फिर से कोशिश करें।';

  @override
  String get errorSession =>
      'आपका सत्र समाप्त हो गया है। कृपया फिर से लॉग इन करें।';

  @override
  String get errorUnexpected => 'कुछ गड़बड़ हो गई। कृपया फिर से कोशिश करें।';

  @override
  String get taglineTranslation => 'मूल्य समझें। भाव परखें। बेहतर खरीदें।';

  @override
  String get loginTitle => 'अपने मोबाइल से लॉग इन करें';

  @override
  String get loginSubtitle =>
      'आपका नंबर सत्यापित करने के लिए हम 6 अंकों का OTP भेजेंगे।';

  @override
  String get mobileNumberLabel => 'मोबाइल नंबर';

  @override
  String get mobileNumberHint => '98765 43210';

  @override
  String get mobileNumberInvalid => '10 अंकों का सही मोबाइल नंबर डालें।';

  @override
  String get sendOtp => 'OTP भेजें';

  @override
  String get appLanguage => 'ऐप की भाषा';

  @override
  String get loginPrivacyNote =>
      'आपका नंबर सिर्फ़ लॉग इन के लिए इस्तेमाल होता है।';

  @override
  String get otpTitle => 'OTP डालें';

  @override
  String otpSentTo(String phone) {
    return '$phone पर भेजा गया';
  }

  @override
  String get otpChangeNumber => 'बदलें';

  @override
  String otpResendIn(String time) {
    return '$time में OTP दोबारा भेजें';
  }

  @override
  String get otpResend => 'OTP दोबारा भेजें';

  @override
  String get otpResent => 'नया OTP भेज दिया गया है।';

  @override
  String get otpVerify => 'सत्यापित करें और आगे बढ़ें';

  @override
  String get otpInvalid => 'OTP गलत है या उसकी समय-सीमा खत्म हो गई है।';

  @override
  String get otpFieldLabel => 'वन-टाइम पासवर्ड';

  @override
  String get profileTitle => 'आपका व्यवसाय';

  @override
  String get profileStep =>
      'चरण 1 / 2 · इससे हम आपको उन बाज़ारों के भाव दिखा पाते हैं जहाँ से आप खरीदते हैं।';

  @override
  String get businessTypeLabel => 'व्यवसाय का प्रकार';

  @override
  String get stateLabel => 'राज्य';

  @override
  String get districtLabel => 'ज़िला';

  @override
  String get selectPlaceholder => 'चुनें';

  @override
  String get selectStateFirst => 'पहले राज्य चुनें';

  @override
  String get preferredLanguageLabel => 'पसंदीदा भाषा';

  @override
  String get preferredLanguageHelper =>
      'अलर्ट, WhatsApp संदेश और रिपोर्ट इसी भाषा में होंगे।';

  @override
  String get districtsLoadError => 'ज़िले लोड नहीं हो सके।';

  @override
  String get continueAction => 'आगे बढ़ें';

  @override
  String get selectCategoryTitle => 'श्रेणी चुनें';

  @override
  String get selectCategorySubtitle =>
      'शुरू करने के लिए अपनी खरीद श्रेणियाँ चुनें। आप बाद में और जोड़ सकते हैं।';

  @override
  String continueSelected(int count) {
    return 'आगे बढ़ें ($count चुनी गईं)';
  }

  @override
  String get categoryComingSoon => 'जल्द आ रहा है';

  @override
  String get categoriesEmpty => 'अभी कोई श्रेणी उपलब्ध नहीं है।';

  @override
  String get navHome => 'होम';

  @override
  String get navMarkets => 'बाज़ार';

  @override
  String get navWatchlist => 'वॉचलिस्ट';

  @override
  String get navOpportunities => 'अवसर';

  @override
  String get navMore => 'और';

  @override
  String get priceUp => 'भाव बढ़ा';

  @override
  String get priceDown => 'भाव घटा';

  @override
  String get priceFlat => 'कोई बदलाव नहीं';

  @override
  String timeToday(String time) {
    return 'आज, $time';
  }

  @override
  String timeYesterday(String time) {
    return 'कल, $time';
  }

  @override
  String timeOnDate(String date, String time) {
    return '$date, $time';
  }

  @override
  String updatedAt(String when) {
    return 'अपडेट: $when';
  }

  @override
  String get greetingMorning => 'सुप्रभात,';

  @override
  String get greetingAfternoon => 'नमस्ते,';

  @override
  String get greetingEvening => 'शुभ संध्या,';

  @override
  String get homeSubtitle =>
      'आज अपने व्यवसाय के लिए खरीद का सबसे अच्छा अवसर खोजें।';

  @override
  String get homeBuyingToday => 'आज आप क्या खरीद रहे हैं?';

  @override
  String get homeTopOpportunities => 'आज के प्रमुख अवसर';

  @override
  String get viewAll => 'सभी देखें';

  @override
  String get homeMyWatchlist => 'मेरी वॉचलिस्ट';

  @override
  String get compareMarkets => 'बाज़ारों की तुलना करें';

  @override
  String get alertsLabel => 'अलर्ट';

  @override
  String bestPriceIn(String market) {
    return '$market में सबसे अच्छा भाव';
  }

  @override
  String get homeNoOpportunity => 'अभी कोई नया अवसर नहीं है।';

  @override
  String get watchlistEmpty => 'आपकी वॉचलिस्ट खाली है।';

  @override
  String get marketComparisonTitle => 'बाज़ार तुलना';

  @override
  String get share => 'शेयर करें';

  @override
  String get commodityLabel => 'वस्तु';

  @override
  String get marketsLabel => 'बाज़ार';

  @override
  String get columnMarket => 'बाज़ार';

  @override
  String columnPricePer(String unit) {
    return 'भाव (₹/$unit)';
  }

  @override
  String get columnChange => 'बदलाव';

  @override
  String arrivals(String quantity) {
    return 'आवक $quantity';
  }

  @override
  String bestMarket(String market) {
    return 'सबसे अच्छा बाज़ार · $market';
  }

  @override
  String lowerThanYourMarket(String amount, String market) {
    return '$market (आपका बाज़ार) से $amount कम';
  }

  @override
  String get comparisonEmpty => 'इन बाज़ारों के भाव अभी उपलब्ध नहीं हैं।';

  @override
  String get priceTrendsTitle => 'भाव का रुझान';

  @override
  String get createAlertAction => 'अलर्ट बनाएँ';

  @override
  String trendTitle(String commodity, String market, String unit) {
    return '$commodity — $market (₹/$unit)';
  }

  @override
  String get statMin => 'न्यूनतम';

  @override
  String get statModal => 'मॉडल';

  @override
  String get statMax => 'अधिकतम';

  @override
  String get relatedMarkets => 'संबंधित बाज़ार';

  @override
  String get trendsEmpty => 'इस अवधि का भाव इतिहास उपलब्ध नहीं है।';

  @override
  String get buyingOpportunityTitle => 'खरीद का अवसर';

  @override
  String get editRequirement => 'ज़रूरत बदलें';

  @override
  String requirementLine(String quantity, String place) {
    return 'आवश्यक मात्रा · $quantity · $place में डिलीवरी';
  }

  @override
  String get bestPriceBadge => 'सबसे अच्छा भाव';

  @override
  String get potentialDifference => 'संभावित अंतर';

  @override
  String differenceCaption(String quantity, String market) {
    return '$quantity पर, $market में खरीदने की तुलना में';
  }

  @override
  String get howCalculated => 'हमने यह कैसे निकाला';

  @override
  String calculationLine(
    String reference,
    String best,
    String quantity,
    String total,
  ) {
    return '($reference − $best) × $quantity = $total। भाड़ा और हैंडलिंग अभी शामिल नहीं हैं।';
  }

  @override
  String viewSuppliers(String market) {
    return '$market के सप्लायर देखें';
  }

  @override
  String get watchlistTitle => 'मेरी वॉचलिस्ट';

  @override
  String get search => 'खोजें';

  @override
  String get addItem => 'आइटम जोड़ें';

  @override
  String get filterAll => 'सभी';

  @override
  String alertBelow(String price) {
    return '$price से नीचे अलर्ट';
  }

  @override
  String alertAbove(String price) {
    return '$price से ऊपर अलर्ट';
  }

  @override
  String get alertsTitle => 'अलर्ट';

  @override
  String get alertSettings => 'अलर्ट सेटिंग';

  @override
  String get filterPriceSignals => 'भाव संकेत';

  @override
  String get filterOpportunities => 'अवसर';

  @override
  String get kindSignal => 'भाव संकेत';

  @override
  String get kindOpportunity => 'अवसर';

  @override
  String get kindSpike => 'भाव में उछाल';

  @override
  String get sentOnWhatsApp => 'WhatsApp पर भेजा गया';

  @override
  String get sentAsPush => 'पुश सूचना';

  @override
  String get viewOpportunity => 'अवसर देखें';

  @override
  String get viewDetails => 'विवरण देखें';

  @override
  String get alertsEmpty => 'अभी कोई अलर्ट नहीं है।';

  @override
  String get createAlertTitle => 'अलर्ट बनाएँ';

  @override
  String get productLabel => 'उत्पाद';

  @override
  String get marketLabel => 'बाज़ार';

  @override
  String get notifyWhen => 'मुझे सूचित करें जब भाव';

  @override
  String get conditionBelow => 'इससे नीचे जाए';

  @override
  String get conditionAbove => 'इससे ऊपर जाए';

  @override
  String get conditionPercent => '% में बदले';

  @override
  String get priceLabel => 'भाव';

  @override
  String get changeLabel => 'बदलाव';

  @override
  String currentPriceIn(String market, String price) {
    return '$market में मौजूदा भाव: $price';
  }

  @override
  String get sendVia => 'अलर्ट भेजें';

  @override
  String get pushNotification => 'पुश सूचना';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String whatsappTarget(String phone, String language) {
    return '$phone · $language में';
  }

  @override
  String get saveAlert => 'अलर्ट सहेजें';

  @override
  String get alertSaved => 'अलर्ट सहेजा गया।';

  @override
  String get costEstimatorTitle => 'लागत अनुमान';

  @override
  String get materialLabel => 'सामग्री';

  @override
  String get quantityLabel => 'मात्रा';

  @override
  String get unitLabel => 'इकाई';

  @override
  String get deliverToLabel => 'डिलीवरी स्थान';

  @override
  String get estimatedCost => 'अनुमानित लागत';

  @override
  String estimateCaption(
    String quantity,
    String unit,
    String price,
    String source,
  ) {
    return '$quantity $unit × $price (सबसे कम बेंचमार्क, $source)';
  }

  @override
  String estimateSavings(String amount, String average) {
    return 'ज़िले के औसत $average की तुलना में $amount की बचत। भाड़ा, हैंडलिंग और GST शामिल नहीं हैं।';
  }

  @override
  String get columnSource => 'स्रोत';

  @override
  String columnRupeePer(String unit) {
    return '₹/$unit';
  }

  @override
  String get saveEstimate => 'अनुमान सहेजें';

  @override
  String get estimateSaved => 'अनुमान सहेजा गया।';

  @override
  String get estimatePrompt => 'अनुमानित लागत देखने के लिए मात्रा डालें।';

  @override
  String get reportsTitle => 'रिपोर्ट';

  @override
  String thisWeek(String range) {
    return 'इस सप्ताह · $range';
  }

  @override
  String potentialSavingsFound(String amount) {
    return '$amount की संभावित बचत मिली';
  }

  @override
  String weekStats(String items, String alerts, String opportunities) {
    return '$items वॉचलिस्ट आइटम · $alerts अलर्ट · $opportunities अवसर';
  }

  @override
  String downloadPdf(String language) {
    return 'PDF डाउनलोड करें ($language)';
  }

  @override
  String get weeklySummaries => 'साप्ताहिक सारांश';

  @override
  String summaryTitle(String range) {
    return '$range सारांश';
  }

  @override
  String summaryMeta(String language, String pages) {
    return 'PDF · $language · $pages पेज';
  }

  @override
  String get exportsTitle => 'एक्सपोर्ट';

  @override
  String get proBadge => 'Pro';

  @override
  String get download => 'डाउनलोड';

  @override
  String get reportsEmpty => 'अभी कोई रिपोर्ट नहीं है।';

  @override
  String get moreTitle => 'और';

  @override
  String get molbhavPro => 'MolBhav Pro';

  @override
  String get proSubtitle => 'उन्नत अलर्ट, एक्सपोर्ट, 1 साल का इतिहास';

  @override
  String pricePerMonth(String price) {
    return '$price/माह';
  }

  @override
  String get myCategories => 'मेरी श्रेणियाँ';

  @override
  String get languageLabel => 'भाषा';

  @override
  String get pushNotifications => 'पुश सूचनाएँ';

  @override
  String get whatsappAlerts => 'WhatsApp अलर्ट';

  @override
  String get helpSupport => 'सहायता';

  @override
  String get logOut => 'लॉग आउट';

  @override
  String placeLine(String district, String state) {
    return '$district, $state';
  }

  @override
  String get choosePlanTitle => 'अपना प्लान चुनें';

  @override
  String get currentPlan => 'मौजूदा प्लान';

  @override
  String get perMonth => '/ माह';

  @override
  String get perYear => '/ वर्ष';

  @override
  String upgradeTo(String plan) {
    return '$plan में अपग्रेड करें';
  }

  @override
  String get cancelAnytime => 'कभी भी रद्द करें। कीमतों में GST शामिल है।';
}
