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
}
