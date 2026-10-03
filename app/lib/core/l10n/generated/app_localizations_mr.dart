// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appTitle => 'MolBhav';

  @override
  String get retry => 'पुन्हा प्रयत्न करा';

  @override
  String get back => 'मागे';

  @override
  String get loading => 'लोड होत आहे';

  @override
  String get errorNetwork =>
      'इंटरनेट कनेक्शन नाही. तुमचे नेटवर्क तपासा आणि पुन्हा प्रयत्न करा.';

  @override
  String get errorServer =>
      'आमच्या बाजूने काहीतरी चूक झाली. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get errorSession => 'तुमचे सत्र संपले आहे. कृपया पुन्हा लॉग इन करा.';

  @override
  String get errorUnexpected => 'काहीतरी चूक झाली. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get taglineTranslation =>
      'मोल जाणा. भाव पारखा. अधिक चांगली खरेदी करा.';

  @override
  String get loginTitle => 'तुमच्या मोबाइलने लॉग इन करा';

  @override
  String get loginSubtitle =>
      'तुमचा नंबर पडताळण्यासाठी आम्ही 6 अंकी OTP पाठवू.';

  @override
  String get mobileNumberLabel => 'मोबाइल नंबर';

  @override
  String get mobileNumberHint => '98765 43210';

  @override
  String get mobileNumberInvalid => '10 अंकी योग्य मोबाइल नंबर टाका.';

  @override
  String get sendOtp => 'OTP पाठवा';

  @override
  String get appLanguage => 'ॲपची भाषा';

  @override
  String get loginPrivacyNote =>
      'तुमचा नंबर फक्त लॉग इन करण्यासाठी वापरला जातो.';

  @override
  String get otpTitle => 'OTP टाका';

  @override
  String otpSentTo(String phone) {
    return '$phone वर पाठवला';
  }

  @override
  String get otpChangeNumber => 'बदला';

  @override
  String otpResendIn(String time) {
    return '$time मध्ये OTP पुन्हा पाठवा';
  }

  @override
  String get otpResend => 'OTP पुन्हा पाठवा';

  @override
  String get otpResent => 'नवीन OTP पाठवला आहे.';

  @override
  String get otpVerify => 'पडताळा आणि पुढे चला';

  @override
  String get otpInvalid => 'OTP चुकीचा आहे किंवा त्याची मुदत संपली आहे.';

  @override
  String get otpFieldLabel => 'वन-टाइम पासवर्ड';

  @override
  String get profileTitle => 'तुमचा व्यवसाय';

  @override
  String get profileStep =>
      'पायरी 1 / 2 · तुम्ही ज्या बाजारांतून खरेदी करता तिथले भाव दाखवण्यासाठी याची मदत होते.';

  @override
  String get businessTypeLabel => 'व्यवसायाचा प्रकार';

  @override
  String get stateLabel => 'राज्य';

  @override
  String get districtLabel => 'जिल्हा';

  @override
  String get selectPlaceholder => 'निवडा';

  @override
  String get selectStateFirst => 'आधी राज्य निवडा';

  @override
  String get preferredLanguageLabel => 'पसंतीची भाषा';

  @override
  String get preferredLanguageHelper =>
      'अलर्ट, WhatsApp संदेश आणि अहवाल याच भाषेत येतील.';

  @override
  String get districtsLoadError => 'जिल्हे लोड करता आले नाहीत.';

  @override
  String get continueAction => 'पुढे चला';

  @override
  String get selectCategoryTitle => 'श्रेणी निवडा';

  @override
  String get selectCategorySubtitle =>
      'सुरुवात करण्यासाठी तुमच्या खरेदी श्रेणी निवडा. नंतर आणखी जोडू शकता.';

  @override
  String continueSelected(int count) {
    return 'पुढे चला ($count निवडल्या)';
  }

  @override
  String get categoryComingSoon => 'लवकरच येत आहे';

  @override
  String get categoriesEmpty => 'सध्या कोणतीही श्रेणी उपलब्ध नाही.';

  @override
  String get navHome => 'होम';

  @override
  String get navMarkets => 'बाजार';

  @override
  String get navWatchlist => 'वॉचलिस्ट';

  @override
  String get navOpportunities => 'संधी';

  @override
  String get navAlerts => 'अलर्ट';

  @override
  String get navMore => 'अधिक';

  @override
  String get priceUp => 'भाव वाढला';

  @override
  String get priceDown => 'भाव घटला';

  @override
  String get priceFlat => 'बदल नाही';

  @override
  String timeToday(String time) {
    return 'आज, $time';
  }

  @override
  String timeYesterday(String time) {
    return 'काल, $time';
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
  String get greetingAfternoon => 'नमस्कार,';

  @override
  String get greetingEvening => 'शुभ संध्या,';

  @override
  String get homeSubtitle =>
      'आज तुमच्या व्यवसायासाठी खरेदीची सर्वोत्तम संधी शोधा.';

  @override
  String get homeBuyingToday => 'आज तुम्ही काय खरेदी करत आहात?';

  @override
  String get homeTopOpportunities => 'आजच्या प्रमुख संधी';

  @override
  String get viewAll => 'सर्व पहा';

  @override
  String get homeMyWatchlist => 'माझी वॉचलिस्ट';

  @override
  String get compareMarkets => 'बाजारांची तुलना करा';

  @override
  String get alertsLabel => 'अलर्ट';

  @override
  String bestPriceIn(String market) {
    return '$market मध्ये सर्वोत्तम भाव';
  }

  @override
  String get homeNoOpportunity => 'सध्या कोणतीही नवीन संधी नाही.';

  @override
  String get watchlistEmpty => 'तुमची वॉचलिस्ट रिकामी आहे.';

  @override
  String get marketComparisonTitle => 'बाजार तुलना';

  @override
  String get share => 'शेअर करा';

  @override
  String get commodityLabel => 'वस्तू';

  @override
  String get marketsLabel => 'बाजार';

  @override
  String get columnMarket => 'बाजार';

  @override
  String columnPricePer(String unit) {
    return 'भाव (₹/$unit)';
  }

  @override
  String get columnChange => 'बदल';

  @override
  String arrivals(String quantity) {
    return 'आवक $quantity';
  }

  @override
  String bestMarket(String market) {
    return 'सर्वोत्तम बाजार · $market';
  }

  @override
  String lowerThanYourMarket(String amount, String market) {
    return '$market (तुमचा बाजार) पेक्षा $amount कमी';
  }

  @override
  String get comparisonEmpty => 'या बाजारांचे भाव अद्याप उपलब्ध नाहीत.';

  @override
  String get browseByMandi => 'मंडीनुसार पहा';

  @override
  String get browseByCommodity => 'वस्तूनुसार पहा';

  @override
  String get mandiLabel => 'मंडी';

  @override
  String get mandiPricesHint =>
      'ताजे भाव पाहण्यासाठी राज्य, जिल्हा आणि मंडी निवडा.';

  @override
  String get mandiPricesEmpty => 'या मंडीचे अलीकडील भाव उपलब्ध नाहीत.';

  @override
  String get mandisEmpty => 'या जिल्ह्यात अद्याप मंडी नाही.';

  @override
  String priceDate(String date) {
    return 'भाव दिनांक: $date';
  }

  @override
  String get priceTrendsTitle => 'भावाचा कल';

  @override
  String get createAlertAction => 'अलर्ट तयार करा';

  @override
  String trendTitle(String commodity, String market, String unit) {
    return '$commodity — $market (₹/$unit)';
  }

  @override
  String get statMin => 'किमान';

  @override
  String get statModal => 'मॉडल';

  @override
  String get statMax => 'कमाल';

  @override
  String get relatedMarkets => 'संबंधित बाजार';

  @override
  String get trendsEmpty => 'या कालावधीचा भाव इतिहास उपलब्ध नाही.';

  @override
  String get buyingOpportunityTitle => 'खरेदीची संधी';

  @override
  String get editRequirement => 'गरज बदला';

  @override
  String requirementLine(String quantity, String place) {
    return 'आवश्यक प्रमाण · $quantity · $place येथे डिलिव्हरी';
  }

  @override
  String get bestPriceBadge => 'सर्वोत्तम भाव';

  @override
  String get potentialDifference => 'संभाव्य फरक';

  @override
  String differenceCaption(String quantity, String market) {
    return '$quantity वर, $market मध्ये खरेदीच्या तुलनेत';
  }

  @override
  String get howCalculated => 'आम्ही हे कसे काढले';

  @override
  String calculationLine(
    String reference,
    String best,
    String quantity,
    String total,
  ) {
    return '($reference − $best) × $quantity = $total. वाहतूक आणि हाताळणी खर्च अद्याप समाविष्ट नाही.';
  }

  @override
  String viewSuppliers(String market) {
    return '$market मधील पुरवठादार पहा';
  }

  @override
  String get watchlistTitle => 'माझी वॉचलिस्ट';

  @override
  String get search => 'शोधा';

  @override
  String get addItem => 'आयटम जोडा';

  @override
  String get filterAll => 'सर्व';

  @override
  String alertBelow(String price) {
    return '$price च्या खाली अलर्ट';
  }

  @override
  String alertAbove(String price) {
    return '$price च्या वर अलर्ट';
  }

  @override
  String get alertsTitle => 'अलर्ट';

  @override
  String get alertSettings => 'अलर्ट सेटिंग';

  @override
  String get filterPriceSignals => 'भाव संकेत';

  @override
  String get filterOpportunities => 'संधी';

  @override
  String get kindSignal => 'भाव संकेत';

  @override
  String get kindOpportunity => 'संधी';

  @override
  String get kindSpike => 'भावात वाढ';

  @override
  String get sentOnWhatsApp => 'WhatsApp वर पाठवले';

  @override
  String get sentAsPush => 'पुश सूचना';

  @override
  String get viewOpportunity => 'संधी पहा';

  @override
  String get viewDetails => 'तपशील पहा';

  @override
  String get alertsEmpty => 'अद्याप कोणतेही अलर्ट नाहीत.';

  @override
  String get createAlertTitle => 'अलर्ट तयार करा';

  @override
  String get productLabel => 'उत्पादन';

  @override
  String get marketLabel => 'बाजार';

  @override
  String get notifyWhen => 'भाव असा झाल्यावर मला कळवा';

  @override
  String get conditionBelow => 'यापेक्षा खाली';

  @override
  String get conditionAbove => 'यापेक्षा वर';

  @override
  String get conditionPercent => '% ने बदलल्यास';

  @override
  String get priceLabel => 'भाव';

  @override
  String get changeLabel => 'बदल';

  @override
  String currentPriceIn(String market, String price) {
    return '$market मधील सध्याचा भाव: $price';
  }

  @override
  String get sendVia => 'अलर्ट याद्वारे पाठवा';

  @override
  String get pushNotification => 'पुश सूचना';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String whatsappTarget(String phone, String language) {
    return '$phone · $language मध्ये';
  }

  @override
  String get saveAlert => 'अलर्ट जतन करा';

  @override
  String get alertSaved => 'अलर्ट जतन केला.';

  @override
  String get costEstimatorTitle => 'खर्च अंदाज';

  @override
  String get materialLabel => 'साहित्य';

  @override
  String get quantityLabel => 'प्रमाण';

  @override
  String get unitLabel => 'एकक';

  @override
  String get deliverToLabel => 'डिलिव्हरी ठिकाण';

  @override
  String get estimatedCost => 'अंदाजित खर्च';

  @override
  String estimateCaption(
    String quantity,
    String unit,
    String price,
    String source,
  ) {
    return '$quantity $unit × $price (सर्वात कमी बेंचमार्क, $source)';
  }

  @override
  String estimateSavings(String amount, String average) {
    return 'जिल्हा सरासरी $average च्या तुलनेत $amount ची बचत. वाहतूक, हाताळणी आणि GST समाविष्ट नाही.';
  }

  @override
  String get columnSource => 'स्रोत';

  @override
  String columnRupeePer(String unit) {
    return '₹/$unit';
  }

  @override
  String get saveEstimate => 'अंदाज जतन करा';

  @override
  String get estimateSaved => 'अंदाज जतन केला.';

  @override
  String get estimatePrompt => 'अंदाजित खर्च पाहण्यासाठी प्रमाण टाका.';

  @override
  String get reportsTitle => 'अहवाल';

  @override
  String thisWeek(String range) {
    return 'या आठवड्यात · $range';
  }

  @override
  String potentialSavingsFound(String amount) {
    return '$amount ची संभाव्य बचत आढळली';
  }

  @override
  String weekStats(String items, String alerts, String opportunities) {
    return '$items वॉचलिस्ट आयटम · $alerts अलर्ट · $opportunities संधी';
  }

  @override
  String downloadPdf(String language) {
    return 'PDF डाउनलोड करा ($language)';
  }

  @override
  String get weeklySummaries => 'साप्ताहिक सारांश';

  @override
  String summaryTitle(String range) {
    return '$range सारांश';
  }

  @override
  String summaryMeta(String language, String pages) {
    return 'PDF · $language · $pages पाने';
  }

  @override
  String get exportsTitle => 'एक्सपोर्ट';

  @override
  String get proBadge => 'Pro';

  @override
  String get download => 'डाउनलोड';

  @override
  String get reportsEmpty => 'अद्याप कोणतेही अहवाल नाहीत.';

  @override
  String get moreTitle => 'अधिक';

  @override
  String get molbhavPro => 'MolBhav Pro';

  @override
  String get proSubtitle => 'प्रगत अलर्ट, एक्सपोर्ट, 1 वर्षाचा इतिहास';

  @override
  String pricePerMonth(String price) {
    return '$price/महिना';
  }

  @override
  String get myCategories => 'माझ्या श्रेणी';

  @override
  String get languageLabel => 'भाषा';

  @override
  String get pushNotifications => 'पुश सूचना';

  @override
  String get whatsappAlerts => 'WhatsApp अलर्ट';

  @override
  String get helpSupport => 'मदत आणि सहाय्य';

  @override
  String get logOut => 'लॉग आउट';

  @override
  String placeLine(String district, String state) {
    return '$district, $state';
  }

  @override
  String get choosePlanTitle => 'तुमचा प्लॅन निवडा';

  @override
  String get currentPlan => 'सध्याचा प्लॅन';

  @override
  String get perMonth => '/ महिना';

  @override
  String get perYear => '/ वर्ष';

  @override
  String upgradeTo(String plan) {
    return '$plan वर अपग्रेड करा';
  }

  @override
  String get cancelAnytime => 'कधीही रद्द करा. किमतींमध्ये GST समाविष्ट आहे.';

  @override
  String get yourNameLabel => 'तुमचे नाव';

  @override
  String get yourNameHint => 'उदा. रमेश पाटील';

  @override
  String get nameErrorLength => '2–60 अक्षरे लिहा.';

  @override
  String get nameErrorCharacters => 'फक्त अक्षरे, स्पेस आणि . \' - वापरा.';

  @override
  String get addYourName => 'तुमचे नाव जोडा';

  @override
  String get addToWatchlist => 'वॉचलिस्टमध्ये जोडा';

  @override
  String get addToWatchlistTitle => 'वॉचलिस्टमध्ये जोडा';

  @override
  String get removeFromWatchlist => 'वॉचलिस्टमधून काढा';

  @override
  String get addedToWatchlist => 'वॉचलिस्टमध्ये जोडले.';

  @override
  String get alreadyInWatchlist => 'आधीच वॉचलिस्टमध्ये आहे.';

  @override
  String removedFromWatchlist(String name) {
    return '$name वॉचलिस्टमधून काढले.';
  }

  @override
  String get undo => 'पूर्ववत करा';

  @override
  String get searchWatchlistHint => 'तुमची वॉचलिस्ट शोधा';

  @override
  String get searchProductsHint => 'उत्पादने शोधा';

  @override
  String get noMatches => 'तुमच्या शोधाशी काहीही जुळत नाही.';

  @override
  String get categoryLabel => 'श्रेणी';

  @override
  String get allVarieties => 'सर्व वाण';

  @override
  String get quickCostEstimate => 'खर्च अंदाज';

  @override
  String get estimateSavedLabel => 'जतन केले';

  @override
  String get unitLockedHelper => 'किमती याच एककात आहेत.';

  @override
  String get anyDistrict => 'कोणताही जिल्हा';

  @override
  String get estimateNoPrices =>
      'येथे या मालाच्या अलीकडील किमती नाहीत. दुसरा जिल्हा किंवा माल निवडा.';

  @override
  String estimateSavingsVsAverage(String amount, String average) {
    return 'तुलना केलेल्या ठिकाणांच्या सरासरीपेक्षा ($average) $amount बचत. लागू शुल्क समाविष्ट.';
  }

  @override
  String get savedEstimates => 'जतन केलेले अंदाज';

  @override
  String get savedEstimatesEmpty => 'अजून कोणताही जतन केलेला अंदाज नाही.';

  @override
  String get deleteEstimate => 'अंदाज हटवा';

  @override
  String get generateReport => 'अहवाल तयार करा';

  @override
  String get reportTypeLabel => 'अहवालाचा प्रकार';

  @override
  String get reportWeeklySummaryPdf => 'साप्ताहिक सारांश (PDF)';

  @override
  String get reportPriceHistoryCsv => 'किंमत इतिहास (CSV)';

  @override
  String get reportWeeklySummary => 'साप्ताहिक सारांश';

  @override
  String get reportPriceHistory => 'किंमत इतिहास';

  @override
  String get reportPeriodLabel => 'कालावधी';

  @override
  String lastDays(int days) {
    return 'मागील $days दिवस';
  }

  @override
  String get customRange => 'स्वतःच्या तारखा';

  @override
  String get reportLanguageLabel => 'अहवालाची भाषा';

  @override
  String get generate => 'तयार करा';

  @override
  String get reportGenerating => 'तयार होत आहे…';

  @override
  String get reportFailed => 'अयशस्वी';

  @override
  String get reportReady => 'तुमचा अहवाल तयार आहे. डाउनलोडसाठी टॅप करा.';

  @override
  String get reportNeedsPro =>
      'किंमत इतिहास निर्यातीसाठी MolBhav Pro आवश्यक आहे.';

  @override
  String get yourReports => 'तुमचे अहवाल';

  @override
  String get optionalAllMandis => 'सर्व मंड्या (पर्यायी)';

  @override
  String get allMandis => 'सर्व मंड्या';

  @override
  String get csvProNote => 'एका उत्पादनाच्या रोजच्या किमती, Excel साठी तयार.';

  @override
  String fileSavedNoViewer(String name) {
    return '$name जतन केले, पण ते उघडणारे कोणतेही अ‍ॅप नाही.';
  }

  @override
  String alertRose(String product, String percent) {
    return '$product $percent% वाढले';
  }

  @override
  String alertDropped(String product, String percent) {
    return '$product $percent% घसरले';
  }

  @override
  String alertRoseIn(String product, String percent, String market) {
    return '$market मध्ये $product $percent% वाढले';
  }

  @override
  String alertDroppedIn(String product, String percent, String market) {
    return '$market मध्ये $product $percent% घसरले';
  }

  @override
  String alertPreviousPrice(String price) {
    return 'मागील: $price';
  }

  @override
  String alertCurrentPrice(String price) {
    return 'सध्याचा: $price';
  }

  @override
  String get showAllStates => 'सर्व राज्यांतील मंडी दाखवा';

  @override
  String reportRequestedAt(String dateTime) {
    return 'विनंती: $dateTime';
  }

  @override
  String reportGeneratedAt(String dateTime) {
    return 'तयार झाला: $dateTime';
  }

  @override
  String get reportNotDownloadedYet => 'अजून डाउनलोड केलेला नाही';

  @override
  String reportDownloadedAt(String dateTime) {
    return 'डाउनलोड: $dateTime';
  }

  @override
  String get reportReadyLabel => 'तयार';

  @override
  String get contactUs => 'आमच्याशी संपर्क साधा';

  @override
  String get contactWhatsApp => 'WhatsApp वर संदेश पाठवा';

  @override
  String get contactCall => 'आम्हाला कॉल करा';

  @override
  String get contactEmail => 'आम्हाला ईमेल करा';

  @override
  String get cannotOpenLink => 'हे उघडू शकणारे कोणतेही अॅप या डिव्हाइसवर नाही.';

  @override
  String get supportWhatsAppPrefill => 'नमस्कार MolBhav, मला यात मदत हवी आहे:';

  @override
  String get supportEmailSubject => 'MolBhav सहाय्य विनंती';

  @override
  String get supportEmailIntro => 'कृपया तुम्हाला कशात मदत हवी आहे ते सांगा:';

  @override
  String get appVersionLabel => 'अॅप आवृत्ती';

  @override
  String get accountLabel => 'खाते';

  @override
  String get faqTitle => 'नेहमीचे प्रश्न';

  @override
  String get faqEmpty => 'सध्या कोणतेही प्रश्न उपलब्ध नाहीत.';

  @override
  String get raiseTicket => 'तिकीट तयार करा';

  @override
  String get myTickets => 'माझी तिकिटे';

  @override
  String get ticketsEmpty => 'तुम्ही अद्याप कोणतेही तिकीट तयार केलेले नाही.';

  @override
  String get ticketTitle => 'तिकीट';

  @override
  String get ticketRaised => 'तिकीट तयार झाले. आम्ही येथेच उत्तर देऊ.';

  @override
  String get submitTicket => 'तिकीट सबमिट करा';

  @override
  String get ticketCategoryLabel => 'हे कशाबद्दल आहे?';

  @override
  String get ticketCategoryAccount => 'खाते';

  @override
  String get ticketCategoryPayment => 'पेमेंट';

  @override
  String get ticketCategoryData => 'भाव आणि डेटा';

  @override
  String get ticketCategoryOther => 'इतर काही';

  @override
  String get ticketSubjectLabel => 'विषय';

  @override
  String get ticketSubjectHint => 'APMC पुणे मधील कांद्याचा भाव चुकीचा दिसतो';

  @override
  String ticketSubjectHelper(int count) {
    return 'किमान $count अक्षरे.';
  }

  @override
  String get ticketMessageLabel => 'संदेश';

  @override
  String get ticketMessageHint =>
      'काय झाले आणि तुम्हाला काय अपेक्षित होते ते सांगा.';

  @override
  String get ticketStatusOpen => 'उघडे';

  @override
  String get ticketStatusInProgress => 'प्रक्रियेत';

  @override
  String get ticketStatusResolved => 'सोडवले';

  @override
  String get ticketStatusClosed => 'बंद';

  @override
  String ticketUpdatedAt(String dateTime) {
    return 'अपडेट: $dateTime';
  }

  @override
  String get ticketAuthorYou => 'तुम्ही';

  @override
  String get ticketAuthorSupport => 'सहाय्य टीम';

  @override
  String get ticketReplyHint => 'उत्तर लिहा';

  @override
  String get sendReply => 'उत्तर पाठवा';

  @override
  String get ticketClosedNotice =>
      'हे तिकीट बंद आहे. आणखी मदत हवी असल्यास नवीन तिकीट तयार करा.';

  @override
  String get sharePrice => 'भाव शेअर करा';

  @override
  String get shareModalLabel => 'मॉडल भाव';

  @override
  String shareModalLine(String price) {
    return 'मॉडल: $price';
  }

  @override
  String sharePriceHeadline(String product, String market) {
    return '$market मधील $product';
  }

  @override
  String shareRange(String min, String max) {
    return 'श्रेणी: $min – $max';
  }

  @override
  String sourceLine(String source) {
    return 'स्रोत: $source';
  }

  @override
  String get shareImageSaved => 'भाव कार्ड तुमच्या डाउनलोडमध्ये सेव्ह झाले.';

  @override
  String get fromLink => 'शेअर केलेले';

  @override
  String get inviteFriend => 'मित्राला आमंत्रित करा';

  @override
  String get inviteFriendSubtitle => 'MolBhav इतर खरेदीदारांसोबत शेअर करा';

  @override
  String get inviteMessage =>
      'मी खरेदीपूर्वी रोजचे मंडी आणि साहित्याचे भाव पाहण्यासाठी MolBhav वापरतो. तुम्हीही वापरून पहा:';

  @override
  String get myRulesAction => 'माझे नियम';

  @override
  String get alertRulesTitle => 'माझे अलर्ट नियम';

  @override
  String get alertRulesEmpty =>
      'अजून एकही अलर्ट नियम नाही. नवीन जोडण्यासाठी “अलर्ट तयार करा” दाबा.';

  @override
  String get alertRuleDeleted => 'अलर्ट नियम हटवला.';

  @override
  String get alertRuleActiveLabel => 'सुरू';

  @override
  String get alertRuleInactiveLabel => 'थांबवलेला';

  @override
  String alertRuleConditionBelow(String price) {
    return 'भाव $price च्या खाली';
  }

  @override
  String alertRuleConditionAbove(String price) {
    return 'भाव $price च्या वर';
  }

  @override
  String alertRuleConditionDrop(String percent) {
    return '$percent% घसरण';
  }

  @override
  String alertRuleConditionSpike(String percent) {
    return '$percent% उसळी';
  }

  @override
  String get alertRulesEditTitle => 'अलर्ट नियम बदला';

  @override
  String get alertRulesThresholdPercentLabel => 'मर्यादा (%)';

  @override
  String alertRulesThresholdPriceLabel(String unit) {
    return 'मर्यादा (₹/$unit)';
  }

  @override
  String get alertRulesActiveLabel => 'सुरू';

  @override
  String get alertRulesCancel => 'रद्द करा';

  @override
  String get alertRulesSave => 'सेव्ह करा';

  @override
  String get changeNumberAction => 'नंबर बदला';

  @override
  String resendOtpIn(int seconds) {
    return '$seconds सेकंदांत OTP पुन्हा पाठवा';
  }

  @override
  String get resendOtpAction => 'OTP पुन्हा पाठवा';

  @override
  String otpAutoFillHint(String phone) {
    return '$phone वर पाठवलेला OTP टाका';
  }

  @override
  String get notificationSettingsTitle => 'नोटिफिकेशन सेटिंग';

  @override
  String get pushNotificationsLabel => 'पुश नोटिफिकेशन';

  @override
  String get alertPushLabel => 'भाव अलर्ट पुश';

  @override
  String get priceUpdatePushLabel => 'रोजचे भाव अपडेट पुश';

  @override
  String get whatsappNotificationsLabel => 'WhatsApp नोटिफिकेशन';

  @override
  String get alertWhatsappLabel => 'WhatsApp वर भाव अलर्ट';

  @override
  String get notificationSettingsAction => 'नोटिफिकेशन सेटिंग';

  @override
  String get monthlyBilling => 'मासिक';

  @override
  String get yearlyBillingPlain => 'वार्षिक';

  @override
  String yearlyBilling(int percent) {
    return 'वार्षिक ($percent% बचत)';
  }

  @override
  String get upgradeToPro => 'Pro मध्ये अपग्रेड करा';

  @override
  String get renewPro => 'Pro रिन्यू करा';

  @override
  String get mySubscription => 'माझी सदस्यता';

  @override
  String subscriptionActive(String date) {
    return 'सुरू — $date रोजी रिन्यू होईल';
  }

  @override
  String get subscriptionExpired => 'कालबाह्य';

  @override
  String get subscriptionCancelled => 'रद्द';

  @override
  String get subscriptionPending => 'पेमेंट बाकी';

  @override
  String get subscriptionFree => 'फ्री प्लॅन';

  @override
  String get cancelSubscription => 'सदस्यता रद्द करा';

  @override
  String get cancelSubscriptionConfirm =>
      'Pro सदस्यता रद्द करायची? Pro सुविधा लगेच बंद होतील आणि उरलेल्या कालावधीचे पैसे परत मिळणार नाहीत.';

  @override
  String get keepSubscription => 'Pro ठेवा';

  @override
  String get checkoutTitle => 'चेकआउट';

  @override
  String get summaryPlan => 'प्लॅन';

  @override
  String get summaryDiscount => 'कूपन सवलत';

  @override
  String get summaryTotal => 'एकूण';

  @override
  String get couponCode => 'कूपन कोड';

  @override
  String couponApplied(String amount) {
    return 'कूपन लागू झाला! तुमची $amount बचत';
  }

  @override
  String get couponInvalid => 'कूपन अवैध किंवा कालबाह्य आहे';

  @override
  String proceedToPay(String amount) {
    return '$amount भरा';
  }

  @override
  String get confirmingPayment => 'पेमेंटची खात्री होत आहे…';

  @override
  String get paymentSuccess => 'पेमेंट यशस्वी!';

  @override
  String get paymentSuccessMessage =>
      'आता तुम्ही Pro सदस्य आहात. सर्व प्रीमियम सुविधांचा आनंद घ्या.';

  @override
  String get exploreProFeatures => 'Pro सुविधा पहा';

  @override
  String get paymentFailed => 'पेमेंट अयशस्वी';

  @override
  String get paymentsMobileOnly => 'पेमेंट मोबाइल अॅपमध्ये उपलब्ध आहे';

  @override
  String get paymentActivationPending =>
      'पेमेंट मिळाले — सक्रियता बाकी आहे. एका मिनिटाने रिफ्रेश करा.';

  @override
  String get externalWalletUnsupported =>
      'बाह्य वॉलेट समर्थित नाहीत. दुसरी पेमेंट पद्धत निवडा.';

  @override
  String get upgradeToUnlock => 'ही सुविधा वापरण्यासाठी Pro मध्ये अपग्रेड करा';

  @override
  String get seePlans => 'प्लॅन पहा';

  @override
  String get proFeatureReports => 'भाव इतिहास एक्सपोर्ट (CSV)';

  @override
  String get proFeatureAlerts => 'भाव अलर्ट नियम';

  @override
  String get proFeatureProcurement => 'खरेदी खर्च अंदाज';

  @override
  String get proFeatureComparison => 'मंडी भाव तुलना';

  @override
  String get freeFeatureBasicPrices => 'रोजचे मूलभूत भाव';

  @override
  String get freeFeatureWatchlist => 'वैयक्तिक वॉचलिस्ट';

  @override
  String get proFeatureEverythingInFree => 'फ्रीमधील सर्व सुविधा';

  @override
  String get passwordLabel => 'पासवर्ड';

  @override
  String get confirmPasswordLabel => 'पासवर्ड पुन्हा टाका';

  @override
  String get passwordLoginSubtitle => 'तुमचा मोबाइल नंबर आणि पासवर्ड टाका.';

  @override
  String get registerTitle => 'तुमचे खाते तयार करा';

  @override
  String get registerSubtitle =>
      'मोबाइल नंबरने लॉग इन करण्यासाठी पासवर्ड निवडा.';

  @override
  String get loginAction => 'लॉग इन करा';

  @override
  String get createAccountAction => 'खाते तयार करा';

  @override
  String get switchToRegister => 'MolBhav वर नवीन आहात? खाते तयार करा';

  @override
  String get switchToLogin => 'आधीच खाते आहे? लॉग इन करा';

  @override
  String get passwordRequired => 'तुमचा पासवर्ड टाका.';

  @override
  String get passwordTooWeak =>
      'किमान 8 अक्षरे वापरा, त्यात एक अक्षर आणि एक अंक असावा.';

  @override
  String get passwordsDoNotMatch => 'पासवर्ड जुळत नाहीत.';

  @override
  String get invalidCredentials => 'मोबाइल नंबर किंवा पासवर्ड चुकीचा आहे.';

  @override
  String get accountExists => 'या नंबरचे खाते आधीच आहे. कृपया लॉग इन करा.';

  @override
  String get useOtpInstead => 'OTP ने लॉग इन करा';

  @override
  String get usePasswordInstead => 'पासवर्डने लॉग इन करा';

  @override
  String get showPassword => 'पासवर्ड दाखवा';

  @override
  String get hidePassword => 'पासवर्ड लपवा';
}
