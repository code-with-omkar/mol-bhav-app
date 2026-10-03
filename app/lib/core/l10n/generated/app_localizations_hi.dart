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
  String get navAlerts => 'अलर्ट';

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
  String get browseByMandi => 'मंडी के अनुसार देखें';

  @override
  String get browseByCommodity => 'वस्तु के अनुसार देखें';

  @override
  String get mandiLabel => 'मंडी';

  @override
  String get mandiPricesHint =>
      'ताज़ा भाव देखने के लिए राज्य, ज़िला और मंडी चुनें।';

  @override
  String get mandiPricesEmpty => 'इस मंडी के हाल के भाव उपलब्ध नहीं हैं।';

  @override
  String get mandisEmpty => 'इस ज़िले में अभी कोई मंडी नहीं है।';

  @override
  String priceDate(String date) {
    return 'भाव दिनांक: $date';
  }

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

  @override
  String get yourNameLabel => 'आपका नाम';

  @override
  String get yourNameHint => 'जैसे रमेश पाटिल';

  @override
  String get nameErrorLength => '2–60 अक्षर लिखें।';

  @override
  String get nameErrorCharacters =>
      'केवल अक्षर, स्पेस और . \' - का उपयोग करें।';

  @override
  String get addYourName => 'अपना नाम जोड़ें';

  @override
  String get addToWatchlist => 'वॉचलिस्ट में जोड़ें';

  @override
  String get addToWatchlistTitle => 'वॉचलिस्ट में जोड़ें';

  @override
  String get removeFromWatchlist => 'वॉचलिस्ट से हटाएं';

  @override
  String get addedToWatchlist => 'वॉचलिस्ट में जोड़ा गया।';

  @override
  String get alreadyInWatchlist => 'पहले से वॉचलिस्ट में है।';

  @override
  String removedFromWatchlist(String name) {
    return '$name वॉचलिस्ट से हटाया गया।';
  }

  @override
  String get undo => 'वापस लें';

  @override
  String get searchWatchlistHint => 'अपनी वॉचलिस्ट खोजें';

  @override
  String get searchProductsHint => 'उत्पाद खोजें';

  @override
  String get noMatches => 'आपकी खोज से कुछ नहीं मिला।';

  @override
  String get categoryLabel => 'श्रेणी';

  @override
  String get allVarieties => 'सभी किस्में';

  @override
  String get quickCostEstimate => 'लागत अनुमान';

  @override
  String get estimateSavedLabel => 'सहेजा गया';

  @override
  String get unitLockedHelper => 'कीमतें इसी इकाई में हैं।';

  @override
  String get anyDistrict => 'कोई भी ज़िला';

  @override
  String get estimateNoPrices =>
      'यहाँ इस सामग्री की हाल की कीमतें नहीं हैं। दूसरा ज़िला या सामग्री चुनें।';

  @override
  String estimateSavingsVsAverage(String amount, String average) {
    return 'तुलना किए गए स्थानों के औसत ($average) से $amount की बचत। लागू शुल्क शामिल।';
  }

  @override
  String get savedEstimates => 'सहेजे गए अनुमान';

  @override
  String get savedEstimatesEmpty => 'अभी कोई सहेजा गया अनुमान नहीं।';

  @override
  String get deleteEstimate => 'अनुमान हटाएं';

  @override
  String get generateReport => 'रिपोर्ट बनाएं';

  @override
  String get reportTypeLabel => 'रिपोर्ट का प्रकार';

  @override
  String get reportWeeklySummaryPdf => 'साप्ताहिक सारांश (PDF)';

  @override
  String get reportPriceHistoryCsv => 'कीमत इतिहास (CSV)';

  @override
  String get reportWeeklySummary => 'साप्ताहिक सारांश';

  @override
  String get reportPriceHistory => 'कीमत इतिहास';

  @override
  String get reportPeriodLabel => 'अवधि';

  @override
  String lastDays(int days) {
    return 'पिछले $days दिन';
  }

  @override
  String get customRange => 'अपनी तारीखें';

  @override
  String get reportLanguageLabel => 'रिपोर्ट की भाषा';

  @override
  String get generate => 'बनाएं';

  @override
  String get reportGenerating => 'बन रही है…';

  @override
  String get reportFailed => 'विफल';

  @override
  String get reportReady => 'आपकी रिपोर्ट तैयार है। डाउनलोड के लिए टैप करें।';

  @override
  String get reportNeedsPro =>
      'कीमत इतिहास एक्सपोर्ट के लिए MolBhav Pro चाहिए।';

  @override
  String get yourReports => 'आपकी रिपोर्ट';

  @override
  String get optionalAllMandis => 'सभी मंडियां (वैकल्पिक)';

  @override
  String get allMandis => 'सभी मंडियां';

  @override
  String get csvProNote => 'एक उत्पाद की रोज़ की कीमतें, Excel के लिए तैयार।';

  @override
  String fileSavedNoViewer(String name) {
    return '$name सहेजी गई, पर इसे खोलने वाला कोई ऐप नहीं है।';
  }

  @override
  String alertRose(String product, String percent) {
    return '$product $percent% बढ़ा';
  }

  @override
  String alertDropped(String product, String percent) {
    return '$product $percent% गिरा';
  }

  @override
  String alertRoseIn(String product, String percent, String market) {
    return '$market में $product $percent% बढ़ा';
  }

  @override
  String alertDroppedIn(String product, String percent, String market) {
    return '$market में $product $percent% गिरा';
  }

  @override
  String alertPreviousPrice(String price) {
    return 'पिछला: $price';
  }

  @override
  String alertCurrentPrice(String price) {
    return 'मौजूदा: $price';
  }

  @override
  String get showAllStates => 'सभी राज्यों की मंडियाँ दिखाएँ';

  @override
  String reportRequestedAt(String dateTime) {
    return 'अनुरोध: $dateTime';
  }

  @override
  String reportGeneratedAt(String dateTime) {
    return 'तैयार हुई: $dateTime';
  }

  @override
  String get reportNotDownloadedYet => 'अभी तक डाउनलोड नहीं हुई';

  @override
  String reportDownloadedAt(String dateTime) {
    return 'डाउनलोड: $dateTime';
  }

  @override
  String get reportReadyLabel => 'तैयार';

  @override
  String get contactUs => 'हमसे संपर्क करें';

  @override
  String get contactWhatsApp => 'WhatsApp पर संदेश भेजें';

  @override
  String get contactCall => 'हमें कॉल करें';

  @override
  String get contactEmail => 'हमें ईमेल करें';

  @override
  String get cannotOpenLink => 'इस डिवाइस पर इसे खोलने वाला कोई ऐप नहीं है।';

  @override
  String get supportWhatsAppPrefill => 'नमस्ते MolBhav, मुझे इसमें मदद चाहिए:';

  @override
  String get supportEmailSubject => 'MolBhav सहायता अनुरोध';

  @override
  String get supportEmailIntro => 'कृपया बताएँ कि आपको किस बारे में मदद चाहिए:';

  @override
  String get appVersionLabel => 'ऐप संस्करण';

  @override
  String get accountLabel => 'खाता';

  @override
  String get faqTitle => 'आम सवाल';

  @override
  String get faqEmpty => 'अभी कोई सवाल उपलब्ध नहीं है।';

  @override
  String get raiseTicket => 'टिकट बनाएँ';

  @override
  String get myTickets => 'मेरे टिकट';

  @override
  String get ticketsEmpty => 'आपने अभी तक कोई टिकट नहीं बनाया है।';

  @override
  String get ticketTitle => 'टिकट';

  @override
  String get ticketRaised => 'टिकट बन गया। हम यहीं जवाब देंगे।';

  @override
  String get submitTicket => 'टिकट जमा करें';

  @override
  String get ticketCategoryLabel => 'यह किस बारे में है?';

  @override
  String get ticketCategoryAccount => 'खाता';

  @override
  String get ticketCategoryPayment => 'भुगतान';

  @override
  String get ticketCategoryData => 'भाव और डेटा';

  @override
  String get ticketCategoryOther => 'कुछ और';

  @override
  String get ticketSubjectLabel => 'विषय';

  @override
  String get ticketSubjectHint => 'APMC पुणे में प्याज़ का भाव गलत दिख रहा है';

  @override
  String ticketSubjectHelper(int count) {
    return 'कम से कम $count अक्षर।';
  }

  @override
  String get ticketMessageLabel => 'संदेश';

  @override
  String get ticketMessageHint => 'बताएँ क्या हुआ और आप क्या उम्मीद कर रहे थे।';

  @override
  String get ticketStatusOpen => 'खुला';

  @override
  String get ticketStatusInProgress => 'प्रक्रिया में';

  @override
  String get ticketStatusResolved => 'हल हो गया';

  @override
  String get ticketStatusClosed => 'बंद';

  @override
  String ticketUpdatedAt(String dateTime) {
    return 'अपडेट: $dateTime';
  }

  @override
  String get ticketAuthorYou => 'आप';

  @override
  String get ticketAuthorSupport => 'सहायता टीम';

  @override
  String get ticketReplyHint => 'जवाब लिखें';

  @override
  String get sendReply => 'जवाब भेजें';

  @override
  String get ticketClosedNotice =>
      'यह टिकट बंद है। मदद चाहिए तो नया टिकट बनाएँ।';

  @override
  String get sharePrice => 'भाव शेयर करें';

  @override
  String get shareModalLabel => 'मॉडल भाव';

  @override
  String shareModalLine(String price) {
    return 'मॉडल: $price';
  }

  @override
  String sharePriceHeadline(String product, String market) {
    return '$market में $product';
  }

  @override
  String shareRange(String min, String max) {
    return 'रेंज: $min – $max';
  }

  @override
  String sourceLine(String source) {
    return 'स्रोत: $source';
  }

  @override
  String get shareImageSaved => 'भाव कार्ड आपके डाउनलोड में सेव हो गया।';

  @override
  String get fromLink => 'शेयर किया गया';

  @override
  String get inviteFriend => 'दोस्त को आमंत्रित करें';

  @override
  String get inviteFriendSubtitle =>
      'MolBhav को दूसरे खरीदारों के साथ शेयर करें';

  @override
  String get inviteMessage =>
      'मैं खरीदारी से पहले रोज़ मंडी और सामग्री के भाव देखने के लिए MolBhav इस्तेमाल करता हूँ। आप भी आज़माएँ:';

  @override
  String get myRulesAction => 'मेरे नियम';

  @override
  String get alertRulesTitle => 'मेरे अलर्ट नियम';

  @override
  String get alertRulesEmpty =>
      'अभी कोई अलर्ट नियम नहीं है। नया जोड़ने के लिए “अलर्ट बनाएँ” दबाएँ।';

  @override
  String get alertRuleDeleted => 'अलर्ट नियम हटा दिया गया।';

  @override
  String get alertRuleActiveLabel => 'चालू';

  @override
  String get alertRuleInactiveLabel => 'रुका हुआ';

  @override
  String alertRuleConditionBelow(String price) {
    return 'भाव $price से नीचे';
  }

  @override
  String alertRuleConditionAbove(String price) {
    return 'भाव $price से ऊपर';
  }

  @override
  String alertRuleConditionDrop(String percent) {
    return '$percent% गिरावट';
  }

  @override
  String alertRuleConditionSpike(String percent) {
    return '$percent% उछाल';
  }

  @override
  String get alertRulesEditTitle => 'अलर्ट नियम बदलें';

  @override
  String get alertRulesThresholdPercentLabel => 'सीमा (%)';

  @override
  String alertRulesThresholdPriceLabel(String unit) {
    return 'सीमा (₹/$unit)';
  }

  @override
  String get alertRulesActiveLabel => 'चालू';

  @override
  String get alertRulesCancel => 'रद्द करें';

  @override
  String get alertRulesSave => 'सेव करें';

  @override
  String get changeNumberAction => 'नंबर बदलें';

  @override
  String resendOtpIn(int seconds) {
    return '$seconds सेकंड में OTP दोबारा भेजें';
  }

  @override
  String get resendOtpAction => 'OTP दोबारा भेजें';

  @override
  String otpAutoFillHint(String phone) {
    return '$phone पर भेजा गया OTP डालें';
  }

  @override
  String get notificationSettingsTitle => 'नोटिफिकेशन सेटिंग';

  @override
  String get pushNotificationsLabel => 'पुश नोटिफिकेशन';

  @override
  String get alertPushLabel => 'भाव अलर्ट पुश';

  @override
  String get priceUpdatePushLabel => 'रोज़ाना भाव अपडेट पुश';

  @override
  String get whatsappNotificationsLabel => 'WhatsApp नोटिफिकेशन';

  @override
  String get alertWhatsappLabel => 'WhatsApp पर भाव अलर्ट';

  @override
  String get notificationSettingsAction => 'नोटिफिकेशन सेटिंग';

  @override
  String get monthlyBilling => 'मासिक';

  @override
  String get yearlyBillingPlain => 'वार्षिक';

  @override
  String yearlyBilling(int percent) {
    return 'वार्षिक ($percent% बचाएँ)';
  }

  @override
  String get upgradeToPro => 'Pro में अपग्रेड करें';

  @override
  String get renewPro => 'Pro रिन्यू करें';

  @override
  String get mySubscription => 'मेरी सदस्यता';

  @override
  String subscriptionActive(String date) {
    return 'चालू — $date को रिन्यू होगी';
  }

  @override
  String get subscriptionExpired => 'समाप्त';

  @override
  String get subscriptionCancelled => 'रद्द';

  @override
  String get subscriptionPending => 'भुगतान बाकी';

  @override
  String get subscriptionFree => 'फ़्री प्लान';

  @override
  String get cancelSubscription => 'सदस्यता रद्द करें';

  @override
  String get cancelSubscriptionConfirm =>
      'क्या Pro सदस्यता रद्द करें? Pro सुविधाएँ तुरंत बंद हो जाएँगी और बचे हुए समय का पैसा वापस नहीं होगा।';

  @override
  String get keepSubscription => 'Pro रखें';

  @override
  String get checkoutTitle => 'चेकआउट';

  @override
  String get summaryPlan => 'प्लान';

  @override
  String get summaryDiscount => 'कूपन छूट';

  @override
  String get summaryTotal => 'कुल';

  @override
  String get couponCode => 'कूपन कोड';

  @override
  String couponApplied(String amount) {
    return 'कूपन लग गया! आप $amount बचाएँगे';
  }

  @override
  String get couponInvalid => 'कूपन अमान्य या समाप्त है';

  @override
  String proceedToPay(String amount) {
    return '$amount चुकाएँ';
  }

  @override
  String get confirmingPayment => 'भुगतान की पुष्टि हो रही है…';

  @override
  String get paymentSuccess => 'भुगतान सफल रहा!';

  @override
  String get paymentSuccessMessage =>
      'अब आप Pro सदस्य हैं। सभी प्रीमियम सुविधाओं का आनंद लें।';

  @override
  String get exploreProFeatures => 'Pro सुविधाएँ देखें';

  @override
  String get paymentFailed => 'भुगतान विफल रहा';

  @override
  String get paymentsMobileOnly => 'भुगतान मोबाइल ऐप में उपलब्ध है';

  @override
  String get paymentActivationPending =>
      'भुगतान मिल गया — सक्रियण बाकी है। एक मिनट बाद रिफ्रेश करें।';

  @override
  String get externalWalletUnsupported =>
      'बाहरी वॉलेट समर्थित नहीं हैं। कोई दूसरा भुगतान तरीका चुनें।';

  @override
  String get upgradeToUnlock => 'यह सुविधा खोलने के लिए Pro में अपग्रेड करें';

  @override
  String get seePlans => 'प्लान देखें';

  @override
  String get proFeatureReports => 'भाव इतिहास एक्सपोर्ट (CSV)';

  @override
  String get proFeatureAlerts => 'भाव अलर्ट नियम';

  @override
  String get proFeatureProcurement => 'खरीद लागत अनुमान';

  @override
  String get proFeatureComparison => 'मंडी भाव तुलना';

  @override
  String get freeFeatureBasicPrices => 'रोज़ाना के बुनियादी भाव';

  @override
  String get freeFeatureWatchlist => 'निजी वॉचलिस्ट';

  @override
  String get proFeatureEverythingInFree => 'फ़्री की सभी सुविधाएँ';

  @override
  String get passwordLabel => 'पासवर्ड';

  @override
  String get confirmPasswordLabel => 'पासवर्ड दोबारा डालें';

  @override
  String get passwordLoginSubtitle => 'अपना मोबाइल नंबर और पासवर्ड डालें।';

  @override
  String get registerTitle => 'अपना खाता बनाएँ';

  @override
  String get registerSubtitle =>
      'मोबाइल नंबर से लॉग इन करने के लिए पासवर्ड चुनें।';

  @override
  String get loginAction => 'लॉग इन करें';

  @override
  String get createAccountAction => 'खाता बनाएँ';

  @override
  String get switchToRegister => 'MolBhav पर नए हैं? खाता बनाएँ';

  @override
  String get switchToLogin => 'पहले से खाता है? लॉग इन करें';

  @override
  String get passwordRequired => 'अपना पासवर्ड डालें।';

  @override
  String get passwordTooWeak =>
      'कम से कम 8 अक्षर रखें, जिनमें एक अक्षर और एक अंक हो।';

  @override
  String get passwordsDoNotMatch => 'पासवर्ड मेल नहीं खाते।';

  @override
  String get invalidCredentials => 'मोबाइल नंबर या पासवर्ड गलत है।';

  @override
  String get accountExists => 'इस नंबर का खाता पहले से है। कृपया लॉग इन करें।';

  @override
  String get useOtpInstead => 'OTP से लॉग इन करें';

  @override
  String get usePasswordInstead => 'पासवर्ड से लॉग इन करें';

  @override
  String get showPassword => 'पासवर्ड दिखाएँ';

  @override
  String get hidePassword => 'पासवर्ड छिपाएँ';
}
