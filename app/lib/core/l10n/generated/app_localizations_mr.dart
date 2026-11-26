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
  String get priceDataDelayed =>
      'बाजारभाव येण्यास उशीर होऊ शकतो — आमच्या डेटा स्रोतात अडचण आहे.';

  @override
  String get priceDataDismiss => 'बंद करा';

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
    return '($reference − $best) × $quantity = $total. इतर जिल्ह्यांच्या भावात वाहतूक आणि हाताळणी खर्च समाविष्ट आहे.';
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
  String freightLabel(String unit) {
    return 'वाहतूक (₹ प्रति $unit)';
  }

  @override
  String get handlingLabel => 'लोडिंग आणि हाताळणी (₹, एकूण)';

  @override
  String get landedOptionalHelper =>
      'ऐच्छिक. हे याच फोनवर मोजले जाते आणि अंदाजासोबत जतन होत नाही.';

  @override
  String get landedCostTitle => 'पोहोच खर्च (डिलिव्हर्ड)';

  @override
  String landedBreakdown(String goods, String freight, String handling) {
    return 'माल $goods + वाहतूक $freight + हाताळणी $handling';
  }

  @override
  String get suppliersTitle => 'पुरवठादार';

  @override
  String get suppliersSubtitle => 'प्रादेशिक पुरवठादार आणि हब, कॉल बटणासह';

  @override
  String get suppliersSearchHint => 'नावाने पुरवठादार शोधा';

  @override
  String get suppliersEmpty => 'कोणताही पुरवठादार सापडला नाही.';

  @override
  String get supplierCall => 'कॉल करा';

  @override
  String get supplierCallFailed => 'फोन अ‍ॅप उघडता आले नाही.';

  @override
  String get permissionsTitle => 'काही परवानग्या द्या';

  @override
  String get permissionsIntro =>
      'या दोन परवानग्यांसह MolBhav सर्वोत्तम काम करते. तुमचा फोन प्रत्येकासाठी विचारेल.';

  @override
  String get permissionsNotificationsTitle => 'सूचना';

  @override
  String get permissionsNotificationsBody =>
      'भाव अलर्ट आणि खरेदीच्या संधी, त्या येताच.';

  @override
  String get permissionsLocationTitle => 'स्थान';

  @override
  String get permissionsLocationBody =>
      'तुमच्या भागाचे हवामान दाखवण्यासाठी. फक्त अंदाजे स्थान वापरले जाते.';

  @override
  String get permissionsAllow => 'परवानगी द्या';

  @override
  String get permissionsNotNow => 'आता नको';

  @override
  String get permissionsChangeLater =>
      'तुम्ही हे केव्हाही फोनच्या सेटिंगमध्ये बदलू शकता.';

  @override
  String get adminMarketsAddAll => 'फीडमधील सर्व बाजार जोडा';

  @override
  String get adminMarketsAddAllHint =>
      'किंवा सर्व राज्ये आणि बाजार एकाच वेळी जोडा. कॅटलॉगमध्ये नसलेली राज्ये तयार केली जातात.';

  @override
  String get adminMarketsAddAllTitle => 'सर्व बाजार जोडायचे?';

  @override
  String get adminMarketsAddAllBody =>
      'शेवटच्या संपूर्ण पुलमधील प्रत्येक राज्य आणि बाजार कॅटलॉगमध्ये जोडला जाईल, जे हजारापेक्षा जास्त बाजार असू शकतात. आधीपासून असलेल्यांना हात लावला जात नाही. यास थोडा वेळ लागतो.';

  @override
  String get adminMarketsAddAllConfirm => 'सर्व जोडा';

  @override
  String adminMarketsAllDone(int markets, int states) {
    return '$markets बाजार आणि $states राज्ये जोडली';
  }

  @override
  String adminMarketsAllDetail(int already, int other) {
    return '$already आधीपासून होते, $other जोडता आले नाहीत (जिल्हा नाही किंवा अवैध नाव).';
  }

  @override
  String get forgotPasswordAction => 'पासवर्ड विसरलात?';

  @override
  String get forgotPasswordTitle => 'पासवर्ड विसरलात';

  @override
  String get forgotPasswordIntro =>
      'तुमचा मोबाइल नंबर टाका. या नंबरचे खाते असल्यास आम्ही WhatsApp वर कोड पाठवू.';

  @override
  String forgotPasswordSent(String number) {
    return '$number या नंबरचे खाते असल्यास कोड पाठवला जात आहे. कोड टाका आणि नवीन पासवर्ड निवडा.';
  }

  @override
  String get forgotPasswordSendCode => 'कोड पाठवा';

  @override
  String get forgotPasswordCode => 'कोड';

  @override
  String get forgotPasswordCodeRequired => 'कोड टाका.';

  @override
  String get forgotPasswordReset => 'नवीन पासवर्ड सेट करा';

  @override
  String get forgotPasswordResend => 'कोड पुन्हा पाठवा';

  @override
  String get forgotPasswordChangeNumber => 'दुसरा नंबर टाका';

  @override
  String get copyAction => 'कॉपी करा';

  @override
  String get doneAction => 'ठीक आहे';

  @override
  String get adminUserResetPasswordAction => 'पासवर्ड रीसेट करा';

  @override
  String get adminUserResetPasswordTitle =>
      'या वापरकर्त्याचा पासवर्ड रीसेट करायचा?';

  @override
  String get adminUserResetPasswordBody =>
      'एक नवीन रँडम पासवर्ड तयार होईल आणि जुना बंद होईल. तुम्हाला तो फक्त एकदाच दिसेल. तो वापरकर्त्याला द्या आणि बदलण्यास सांगा.';

  @override
  String get adminUserResetPasswordConfirm => 'रीसेट करा';

  @override
  String get adminUserResetPasswordDone => 'नवीन पासवर्ड';

  @override
  String get adminUserResetPasswordShownOnce =>
      'फक्त एकदाच दिसेल. तो वापरकर्त्याला प्रत्यक्ष किंवा फोनवर सांगा.';

  @override
  String get changePasswordTitle => 'पासवर्ड बदला';

  @override
  String get changePasswordSubtitle => 'साइन इनसाठी नवीन पासवर्ड निवडा';

  @override
  String get currentPasswordLabel => 'सध्याचा पासवर्ड';

  @override
  String get currentPasswordRequired => 'तुमचा सध्याचा पासवर्ड टाका.';

  @override
  String get newPasswordLabel => 'नवीन पासवर्ड';

  @override
  String get passwordsDontMatch => 'पासवर्ड जुळत नाहीत.';

  @override
  String get passwordSameAsCurrent =>
      'सध्याच्या पासवर्डपेक्षा वेगळा पासवर्ड निवडा.';

  @override
  String get changePasswordAction => 'पासवर्ड बदला';

  @override
  String get passwordChanged => 'पासवर्ड बदलला. कृपया पुन्हा साइन इन करा.';

  @override
  String landedPerUnit(String amount, String unit) {
    return '$amount प्रति $unit डिलिव्हर्ड';
  }

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

  @override
  String get unlockWatchlistTitle => 'तुमची मोफत वॉचलिस्ट भरली आहे';

  @override
  String get unlockAlertsTitle => 'तुम्ही तुमचे मोफत अलर्ट वापरले आहेत';

  @override
  String get unlockReportTitle => 'हा अहवाल अनलॉक करा';

  @override
  String unlockWatchlistBody(int slots) {
    return 'आणखी $slots आयटम जोडण्यासाठी एक छोटी जाहिरात पहा, किंवा अमर्याद वॉचलिस्टसाठी Pro घ्या.';
  }

  @override
  String unlockAlertsBody(int slots) {
    return 'आणखी $slots अलर्ट जोडण्यासाठी एक छोटी जाहिरात पहा, किंवा अमर्याद अलर्टसाठी Pro घ्या.';
  }

  @override
  String get unlockReportBody =>
      'हा अहवाल मोफत मिळवण्यासाठी छोट्या जाहिराती पहा, किंवा अमर्याद अहवालांसाठी Pro घ्या.';

  @override
  String get unlockLimitUsed =>
      'सध्या मोफत मर्यादा पूर्ण झाली आहे. अमर्याद वापरासाठी Pro घ्या.';

  @override
  String get unlockProOnly =>
      'इथे जाहिराती उपलब्ध नाहीत. अमर्याद वापरासाठी Pro घ्या.';

  @override
  String watchAdsButton(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString जाहिराती पहा',
      one: '1 जाहिरात पहा',
    );
    return '$_temp0';
  }

  @override
  String get goProNoAds => 'Pro घ्या – जाहिराती नाहीत';

  @override
  String unlockAdProgress(int current, int total) {
    return 'जाहिरात $current / $total';
  }

  @override
  String get unlockVerifying => 'खात्री करत आहोत…';

  @override
  String get unlockGranted => 'अनलॉक झाले! पुन्हा प्रयत्न करत आहोत…';

  @override
  String get unlockFailed =>
      'आम्ही जाहिरातीची खात्री करू शकलो नाही. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get reportFreeUnlockHint =>
      'मोफत प्लॅन: छोट्या जाहिराती पाहून दिवसातून काही वेळा किंमत इतिहास अनलॉक करा. Pro: अमर्याद.';

  @override
  String get adsPersonalisedTitle => 'वैयक्तिक जाहिराती';

  @override
  String get adsPersonalisedSubtitle =>
      'तुम्ही MolBhav कसे वापरता त्यानुसार जाहिराती दाखवा. बंद असताना जाहिराती दिसतील, पण तुमच्यावर आधारित नसतील.';

  @override
  String get homeWeatherAnimationTitle => 'होम हवामान ॲनिमेशन';

  @override
  String get homeWeatherAnimationSubtitle =>
      'होम हेडरमागे हलणारे ढग, पाऊस आणि ऊन. बंद असतानाही हवामान आयकॉनवर दिसेल.';

  @override
  String get promotionSponsored => 'प्रायोजित';

  @override
  String get adminSchedulesTitle => 'डेटा पुल वेळापत्रक';

  @override
  String get adminSchedulesSubtitle => 'सरकारी भाव आपोआप कधी आणायचे';

  @override
  String get adminDashboardTitle => 'ॲडमिन डॅशबोर्ड';

  @override
  String get adminAppTitle => 'ॲप व्यवस्थापन';

  @override
  String get adminTabDashboard => 'डॅशबोर्ड';

  @override
  String get adminTabApp => 'ॲप';

  @override
  String get adminTabAds => 'जाहिराती';

  @override
  String get adminTicketsTitle => 'सपोर्ट तिकिटे';

  @override
  String get adminSupportSubtitle =>
      'वापरकर्त्यांची तिकिटे वाचा आणि उत्तर द्या';

  @override
  String get adminSupportEmpty => 'येथे एकही तिकीट नाही.';

  @override
  String get adminSupportTicketTitle => 'तिकीट';

  @override
  String get adminSupportStatus => 'स्थिती';

  @override
  String get adminSupportAuthorUser => 'वापरकर्ता';

  @override
  String get adminSupportClosedNotice =>
      'हे तिकीट बंद आहे. यावर उत्तर देता येत नाही आणि ते पुन्हा उघडता येत नाही.';

  @override
  String get adminSupportCloseTitle => 'हे तिकीट बंद करायचे?';

  @override
  String get adminSupportCloseBody =>
      'बंद तिकीट अंतिम असते: कोणीही त्यावर उत्तर देऊ शकत नाही किंवा ते पुन्हा उघडू शकत नाही. वापरकर्ता पुन्हा लिहू शकत असेल तर ते निराकरण झालेले म्हणून चिन्हांकित करा.';

  @override
  String get adminSupportCloseConfirm => 'तिकीट बंद करा';

  @override
  String get adminCampaignsTitle => 'मोहिमा';

  @override
  String get adminCampaignsManage => 'मोहिमा व्यवस्थापित करा';

  @override
  String get adminCampaignsNew => 'नवी मोहीम';

  @override
  String get adminCampaignsEmpty => 'येथे एकही मोहीम नाही.';

  @override
  String get adminCampaignEditTitle => 'मोहीम बदला';

  @override
  String get adminPlacementHomeFeed => 'होम फीड';

  @override
  String get adminPlacementMandiPrices => 'मंडी भाव';

  @override
  String get adminPlacementMarketComparison => 'बाजार तुलना';

  @override
  String get adminCampaignAdvertiser => 'जाहिरातदार';

  @override
  String get adminCampaignChooseAdvertiser => 'जाहिरातदार निवडा';

  @override
  String get adminCampaignAddAdvertiser => 'जाहिरातदार जोडा';

  @override
  String get adminCampaignName => 'मोहिमेचे नाव';

  @override
  String get adminCampaignPlacement => 'कुठे दिसेल';

  @override
  String get adminCampaignAdTitle => 'जाहिरात';

  @override
  String get adminCampaignHeadline => 'शीर्षक';

  @override
  String get adminCampaignText => 'मजकूर';

  @override
  String get adminCampaignButton => 'बटणाचे नाव';

  @override
  String get adminCampaignLink => 'बटणाची लिंक';

  @override
  String get adminCampaignImage => 'इमेज लिंक (ऐच्छिक)';

  @override
  String get adminCampaignWhenTitle => 'कधी चालेल';

  @override
  String get adminCampaignStarts => 'सुरू';

  @override
  String get adminCampaignEnds => 'संपते';

  @override
  String get adminCampaignPickDate => 'तारीख निवडा';

  @override
  String get adminCampaignPriority => 'प्राधान्य';

  @override
  String get adminCampaignPriorityHint =>
      '0 ते 100. दोन मोहिमा जुळल्यास मोठा आकडा असलेली आधी दिसते.';

  @override
  String get adminCampaignCap => 'दररोज दिसण्याची मर्यादा (ऐच्छिक)';

  @override
  String get adminCampaignCapHint =>
      'एका दिवसात, सर्व वापरकर्त्यांत मिळून, जास्तीत जास्त किती वेळा दिसेल. मर्यादा नको असल्यास रिकामे ठेवा.';

  @override
  String get adminCampaignAudienceTitle => 'कोणाला दिसेल';

  @override
  String get adminCampaignCategories => 'श्रेणी';

  @override
  String get adminCampaignChooseCategories => 'श्रेणी निवडा';

  @override
  String get adminCampaignStates => 'राज्ये (कोणतेही न निवडल्यास सर्व राज्ये)';

  @override
  String get adminCampaignPreview => 'पूर्वावलोकन';

  @override
  String adminCampaignStatusTitle(String status) {
    return 'स्थिती: $status';
  }

  @override
  String get adminCampaignActivate => 'सुरू करा';

  @override
  String get adminCampaignPause => 'थांबवा';

  @override
  String get adminCampaignEnd => 'मोहीम संपवा';

  @override
  String get adminCampaignEndTitle => 'ही मोहीम संपवायची?';

  @override
  String get adminCampaignEndBody =>
      'संपलेली मोहीम कायमची दिसायची थांबते आणि ती बदलता किंवा पुन्हा सुरू करता येत नाही.';

  @override
  String get adminCampaignEndConfirm => 'मोहीम संपवा';

  @override
  String get adminCampaignEndedNote =>
      'ही मोहीम संपली आहे. आता ती बदलता येत नाही.';

  @override
  String get adminCampaignTargetsReset =>
      'या मोहिमेचे लक्ष्य या फॉर्मपेक्षा अधिक तपशीलवार आहे. जतन केल्यावर तिचे प्रेक्षक येथे निवडलेल्या श्रेणी आणि राज्यांचे होतील.';

  @override
  String get adminCampaignSave => 'मोहीम जतन करा';

  @override
  String get adminCampaignCreated =>
      'मोहीम ड्राफ्ट म्हणून तयार झाली. दिसायला सुरू करण्यासाठी ती सुरू करा.';

  @override
  String get adminCampaignErrRequired => 'आवश्यक';

  @override
  String get adminCampaignErrLink => 'https:// ने सुरू होणारा वेब पत्ता लिहा';

  @override
  String get adminCampaignErrDates => 'शेवटची तारीख सुरुवातीआधी असू शकत नाही';

  @override
  String get adminCampaignErrPriority => '0 ते 100 मधील पूर्ण संख्या लिहा';

  @override
  String get adminCampaignErrCap => '1 किंवा त्याहून अधिक पूर्ण संख्या लिहा';

  @override
  String get adminCampaignErrCategories => 'किमान एक श्रेणी निवडा';

  @override
  String get adminAdvertiserTitle => 'जाहिरातदार जोडा';

  @override
  String get adminAdvertiserName => 'व्यवसायाचे नाव';

  @override
  String get adminAdvertiserContact => 'संपर्काचे नाव (ऐच्छिक)';

  @override
  String get adminAdvertiserPhone => 'संपर्क फोन (ऐच्छिक)';

  @override
  String get adminAdvertiserGst => 'GST क्रमांक (ऐच्छिक, 15 अक्षरे)';

  @override
  String get adminAdvertiserSave => 'जोडा';

  @override
  String get adminPlansTitle => 'प्लॅन';

  @override
  String get adminPlansSubtitle => 'सबस्क्रिप्शन प्लॅनची किंमत आणि चालू/बंद';

  @override
  String get adminPlansIntro =>
      'किंमत बदलल्यास नवीन ग्राहकांकडून घेतले जाणारे शुल्क बदलते.';

  @override
  String get adminPlansNew => 'नवीन प्लॅन';

  @override
  String get adminPlansEmpty => 'अजून कोणताही प्लॅन नाही.';

  @override
  String get adminPlanEditTitle => 'प्लॅन बदला';

  @override
  String get adminPlanCode => 'प्लॅन कोड';

  @override
  String get adminPlanCodeHint => 'प्लॅन तयार झाल्यानंतर बदलता येत नाही.';

  @override
  String get adminPlanName => 'नाव';

  @override
  String get adminPlanPrice => 'किंमत (₹)';

  @override
  String get adminPlanPeriod => 'बिलिंग';

  @override
  String get adminPlanMonthly => 'मासिक';

  @override
  String get adminPlanYearly => 'वार्षिक';

  @override
  String adminPlanPerMonth(String price) {
    return '$price / महिना';
  }

  @override
  String adminPlanPerYear(String price) {
    return '$price / वर्ष';
  }

  @override
  String get adminPlanActive => 'खरेदीसाठी उपलब्ध';

  @override
  String get adminPlanOff => 'बंद';

  @override
  String get adminPlanSave => 'प्लॅन जतन करा';

  @override
  String get adminPlanErrCode => 'अक्षरे, अंक, - किंवा _ वापरा (32 पर्यंत)';

  @override
  String get adminPlanErrName => 'आवश्यक (100 अक्षरांपर्यंत)';

  @override
  String get adminPlanErrPrice => '149 किंवा 149.50 सारखी किंमत लिहा';

  @override
  String get adminCouponsTitle => 'कूपन';

  @override
  String get adminCouponsSubtitle => 'सबस्क्रिप्शनसाठी सवलत कोड';

  @override
  String get adminCouponsNew => 'नवीन कूपन';

  @override
  String get adminCouponsEmpty => 'अजून कोणतेही कूपन नाही.';

  @override
  String get adminCouponCode => 'कूपन कोड';

  @override
  String get adminCouponPercent => 'टक्के सवलत';

  @override
  String get adminCouponFixed => 'रकमेची सवलत';

  @override
  String get adminCouponValuePercent => 'टक्के सवलत (1 ते 100)';

  @override
  String get adminCouponValueFixed => 'सवलतीची रक्कम (₹)';

  @override
  String get adminCouponPlan => 'कशावर चालेल';

  @override
  String get adminCouponAnyPlan => 'कोणताही प्लॅन';

  @override
  String get adminCouponMin => 'किमान किंमत (₹, ऐच्छिक)';

  @override
  String get adminCouponMaxUses => 'वापर मर्यादा (ऐच्छिक)';

  @override
  String adminCouponMaxUsesNote(int used) {
    return 'आतापर्यंत $used वेळा वापरले. मर्यादा नको असल्यास रिकामे ठेवा.';
  }

  @override
  String get adminCouponStarts => 'सुरू';

  @override
  String get adminCouponEnds => 'संपते (ऐच्छिक)';

  @override
  String get adminCouponNoEnd => 'शेवटची तारीख नाही';

  @override
  String get adminCouponClearEnd => 'शेवटची तारीख काढा';

  @override
  String get adminCouponActive => 'चालू आहे';

  @override
  String get adminCouponSave => 'कूपन जतन करा';

  @override
  String get adminCouponOff => 'बंद';

  @override
  String get adminCouponExpired => 'कालबाह्य';

  @override
  String get adminCouponUsedUp => 'पूर्ण वापरले';

  @override
  String adminCouponPercentOff(int percent) {
    return '$percent% सवलत';
  }

  @override
  String adminCouponAmountOff(String amount) {
    return '$amount सवलत';
  }

  @override
  String adminCouponMinNote(String amount) {
    return '$amount पासून';
  }

  @override
  String adminCouponFrom(String date) {
    return '$date पासून';
  }

  @override
  String adminCouponUsed(int used) {
    return '$used वेळा वापरले';
  }

  @override
  String adminCouponUsedOf(int used, int max) {
    return '$max पैकी $used वापरले';
  }

  @override
  String get adminCouponErrCode => 'अक्षरे, अंक, - किंवा _ वापरा (50 पर्यंत)';

  @override
  String get adminCouponErrPercent => '1 ते 100 मधील पूर्ण संख्या लिहा';

  @override
  String get adminCouponErrAmount => '50 किंवा 49.50 सारखी रक्कम लिहा';

  @override
  String get adminCouponErrMaxUses => '1 किंवा त्याहून अधिक पूर्ण संख्या लिहा';

  @override
  String adminCouponErrMaxUsesBelow(int used) {
    return 'पूर्ण संख्या लिहा, आतापर्यंतच्या $used वापरांपेक्षा कमी नाही';
  }

  @override
  String get adminCouponErrDates => 'शेवटची तारीख सुरुवातीआधी असू शकत नाही';

  @override
  String get adminCouponErrMin => '100 किंवा 99.50 सारखी रक्कम लिहा';

  @override
  String get adminSubsTitle => 'सबस्क्रिप्शन';

  @override
  String get adminSubsSubtitle =>
      'कोणाकडे प्लॅन आहे ते पहा, आणि एखादा लवकर संपवा';

  @override
  String get adminSubsEmpty => 'येथे एकही सबस्क्रिप्शन नाही.';

  @override
  String get adminSubPending => 'पेमेंटची प्रतीक्षा';

  @override
  String get adminSubCancelled => 'रद्द';

  @override
  String get adminSubExpired => 'कालबाह्य';

  @override
  String get adminSubUnknownUser => 'अज्ञात वापरकर्ता';

  @override
  String adminSubStarted(String date) {
    return '$date रोजी सुरू';
  }

  @override
  String adminSubEnds(String date) {
    return '$date रोजी संपते';
  }

  @override
  String adminSubCancelledOn(String date) {
    return '$date रोजी रद्द';
  }

  @override
  String adminSubEndedOn(String date) {
    return '$date रोजी संपले';
  }

  @override
  String get adminSubAutoRenew => 'आपोआप नूतनीकरण';

  @override
  String get adminSubWaiting => 'पेमेंट निश्चित होण्याची प्रतीक्षा';

  @override
  String get adminSubEndNow => 'आता संपवा';

  @override
  String get adminSubEndTitle => 'हे सबस्क्रिप्शन संपवायचे?';

  @override
  String get adminSubEndBody =>
      'त्यांचा प्लॅन लगेच बंद होतो आणि ते मोफत प्लॅनवर परत जातात. हे परत करता येत नाही.';

  @override
  String get adminSubEndConfirm => 'सबस्क्रिप्शन संपवा';

  @override
  String get adminSubEnded => 'सबस्क्रिप्शन संपले.';

  @override
  String get adminAuditTitle => 'क्रियाकलाप नोंद';

  @override
  String get adminAuditSubtitle => 'अ‍ॅडमिन अ‍ॅपमध्ये कोणी काय आणि कधी बदलले';

  @override
  String get adminAuditEmpty =>
      'अजून काहीही नोंदवलेले नाही. अ‍ॅडमिनचे बदल येथे दिसतील.';

  @override
  String adminAuditBy(String actor) {
    return '$actor यांनी';
  }

  @override
  String get adminAuditUnknownActor => 'आता अस्तित्वात नसलेले खाते';

  @override
  String get adminMarketsTitle => 'बाजार जोडा';

  @override
  String get adminMarketsSubtitle => 'प्राइस फीडमधील बाजार कॅटलॉगमध्ये जोडा';

  @override
  String get adminMarketsIntro =>
      'मागील संपूर्ण पुलमधून एक राज्य आणि त्याचे बाजार निवडा. प्रत्येक बाजार त्याच्या जिल्ह्यासह कॅटलॉगमध्ये जोडला जातो, म्हणजे पुढील पुलमध्ये त्याचे भाव जतन होऊ शकतात. भाव फक्त कॅटलॉगमध्ये आधीपासून असलेल्या उत्पादनांचे दिसतात.';

  @override
  String get adminMarketsNoFeed =>
      'प्राइस फीडमधील बाजार अजून नोंदवलेले नाहीत. फीडमध्ये डेटा असलेल्या दिवशी संपूर्ण पुल (फिल्टरशिवाय आता चालवा) चालवा, मग परत या.';

  @override
  String get adminMarketsOpenSchedules => 'डेटा पुल उघडा';

  @override
  String get adminMarketsState => 'राज्य';

  @override
  String get adminMarketsMarkets => 'बाजार';

  @override
  String get adminMarketsChoose => 'बाजार निवडा';

  @override
  String get adminMarketsChooseState => 'राज्य निवडा';

  @override
  String adminMarketsAdd(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बाजार जोडा',
      one: '1 बाजार जोडा',
      zero: 'बाजार जोडा',
    );
    return '$_temp0';
  }

  @override
  String adminMarketsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बाजार जोडले',
      one: '1 बाजार जोडला',
      zero: 'एकही बाजार जोडला नाही',
    );
    return '$_temp0';
  }

  @override
  String get adminMarketsAddedHint => 'त्यांचे भाव पुढील पुलपासून जतन होतील.';

  @override
  String get adminMarketsNotAdded => 'जोडले नाहीत';

  @override
  String get adminMarketsSkipNotInFeed => 'या राज्याच्या फीड यादीत नाही';

  @override
  String get adminMarketsSkipAlreadyInCatalog => 'कॅटलॉगमध्ये आधीच आहे';

  @override
  String get adminMarketsSkipCodeInvalid =>
      'नाव कोड म्हणून वापरता येत नाही (अक्षराने सुरू व्हायला हवे)';

  @override
  String get adminMarketsSkipDistrictUnknown =>
      'फीडने जिल्हा दिला नाही. संपूर्ण पुल पुन्हा चालवा.';

  @override
  String get adminMarketsSkipNameInvalid => 'कॅटलॉगच्या नाव नियमांनी नाकारले';

  @override
  String get adminProductsTitle => 'उत्पादने';

  @override
  String get adminProductsSubtitle =>
      'कॅटलॉगमध्ये शोधा आणि उत्पादनांची नावे बदला';

  @override
  String get adminProductsSearchHint => 'नाव किंवा कोडने शोधा';

  @override
  String get adminProductsEmpty => 'कोणतेही उत्पादन सापडले नाही.';

  @override
  String get adminProductsHint => 'नावे बदलण्यासाठी उत्पादनावर टॅप करा.';

  @override
  String get adminProductEditTitle => 'उत्पादन बदला';

  @override
  String get adminProductNameEn => 'इंग्रजीतील नाव';

  @override
  String get adminProductNameHi => 'हिंदीतील नाव';

  @override
  String get adminProductNameMr => 'मराठीतील नाव';

  @override
  String get adminProductNameOptional =>
      'ऐच्छिक. रिकामे असल्यास त्या भाषेचे वापरकर्ते इंग्रजी नाव पाहतात.';

  @override
  String get adminProductErrEnglish => 'इंग्रजी नाव लिहा.';

  @override
  String get adminProductActive => 'अ‍ॅपमध्ये दिसावे';

  @override
  String get adminProductActiveHint =>
      'बंद केल्यास उत्पादन वापरकर्त्यांपासून लपते; त्याचे भाव राहतात.';

  @override
  String get adminProductSave => 'उत्पादन जतन करा';

  @override
  String get adminProductNew => 'नवीन उत्पादन';

  @override
  String adminVariantsButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'प्रकार ($count)',
      one: 'प्रकार (1)',
      zero: 'प्रकार',
    );
    return '$_temp0';
  }

  @override
  String get adminVariantsTitle => 'प्रकार';

  @override
  String get adminVariantsIntro =>
      'या उत्पादनाचे ग्रेड किंवा रूपे, जसे मोठा किंवा सुका. नाव बदलण्यासाठी किंवा बंद करण्यासाठी टॅप करा.';

  @override
  String get adminVariantsEmpty => 'या उत्पादनाला कोणताही प्रकार नाही.';

  @override
  String get adminVariantNew => 'नवीन प्रकार';

  @override
  String get adminVariantEdit => 'प्रकार बदला';

  @override
  String get adminProductCode => 'कोड';

  @override
  String get adminProductCodeHint =>
      'इंग्रजी लहान अक्षरे, अंक आणि हायफन; अक्षराने सुरू व्हावे. प्राइस फीडमधील वस्तूसाठी तिचे नाव ठेवा, जसे red-onion. हे नंतर बदलता येत नाही.';

  @override
  String get adminProductErrCode =>
      'इंग्रजी लहान अक्षरे, अंक आणि हायफन वापरा, अक्षराने सुरू करा.';

  @override
  String get adminProductErrSubCategory => 'उप-श्रेणी निवडा.';

  @override
  String get adminProductErrUnit => 'एकक निवडा.';

  @override
  String get adminCategoriesTitle => 'श्रेणी';

  @override
  String get adminCategoriesSubtitle => 'श्रेणी आणि उप-श्रेणी जोडा व नाव बदला';

  @override
  String get adminCategoriesIntro =>
      'नाव बदलण्यासाठी किंवा बंद करण्यासाठी श्रेणी किंवा उप-श्रेणीवर टॅप करा. उत्पादने उप-श्रेणीच्या आत असतात.';

  @override
  String get adminCategoriesEmpty => 'अजून कोणतीही श्रेणी नाही.';

  @override
  String get adminCategoryNew => 'नवीन श्रेणी';

  @override
  String get adminCategoryEdit => 'श्रेणी बदला';

  @override
  String get adminSubCategoryNew => 'नवीन उप-श्रेणी';

  @override
  String get adminSubCategoryEdit => 'उप-श्रेणी बदला';

  @override
  String get adminCategoryCodeHint =>
      'इंग्रजी लहान अक्षरे, अंक आणि हायफन; अक्षराने सुरू व्हावे. हे नंतर बदलता येत नाही.';

  @override
  String get adminCategoryActiveHint =>
      'बंद केल्यास ती वापरकर्त्यांपासून लपते; तिच्या आतले सर्व राहते.';

  @override
  String get adminCategorySave => 'जतन करा';

  @override
  String get adminUnitsTitle => 'एकके';

  @override
  String get adminUnitsSubtitle => 'मापाची एकके जोडा व नाव बदला';

  @override
  String get adminUnitsIntro =>
      'नाव बदलण्यासाठी किंवा बंद करण्यासाठी एककावर टॅप करा. उत्पादनांचे भाव एखाद्या एककात असतात.';

  @override
  String get adminUnitsEmpty => 'अजून कोणतेही एकक नाही.';

  @override
  String get adminUnitNew => 'नवीन एकक';

  @override
  String get adminUnitEdit => 'एकक बदला';

  @override
  String get adminUnitSymbol => 'चिन्ह';

  @override
  String get adminUnitErrSymbol => 'लहान चिन्ह लिहा, जास्तीत जास्त 16 अक्षरे.';

  @override
  String get adminUnitDimension => 'ते काय मोजते';

  @override
  String get adminUnitChooseDimension => 'ते काय मोजते ते निवडा';

  @override
  String get adminUnitErrDimension => 'एकक काय मोजते ते निवडा.';

  @override
  String get adminUnitFactor => 'किती मूळ एकके';

  @override
  String adminUnitFactorIn(String unit) {
    return '$unit मधील प्रमाण';
  }

  @override
  String get adminUnitFactorHint =>
      'या एककाचे एक किती असते, उदा. क्विंटलसाठी किलोमध्ये 100. हे नंतर बदलता येत नाही.';

  @override
  String get adminUnitErrFactor =>
      'शून्यापेक्षा मोठी संख्या लिहा, जास्तीत जास्त 6 दशांश.';

  @override
  String get adminUnitActiveHint =>
      'बंद केल्यास नवीन उत्पादनांसाठी दिसत नाही; सध्याचे भाव राहतात.';

  @override
  String get adminUnitDimMass => 'वजन';

  @override
  String get adminUnitDimVolume => 'आकारमान';

  @override
  String get adminUnitDimCount => 'संख्या';

  @override
  String get adminUnitDimLength => 'लांबी';

  @override
  String get adminUnitDimArea => 'क्षेत्रफळ';

  @override
  String get adminMandisTitle => 'मंडया';

  @override
  String get adminMandisSubtitle =>
      'मंडया शोधा, जोडा, नाव बदला आणि जिल्हा बदला';

  @override
  String get adminMandisEmpty => 'कोणतीही मंडी सापडली नाही.';

  @override
  String get adminMandiNew => 'नवीन मंडी';

  @override
  String get adminMandiEdit => 'मंडी बदला';

  @override
  String get adminMandiName => 'नाव';

  @override
  String get adminMandiErrName => 'मंडीचे नाव लिहा.';

  @override
  String get adminMandiDistrict => 'जिल्हा';

  @override
  String get adminMandiChooseDistrict => 'जिल्हा निवडा';

  @override
  String get adminMandiErrDistrict => 'जिल्हा निवडा.';

  @override
  String get adminMandiCodeHint =>
      'इंग्रजी लहान अक्षरे, अंक आणि हायफन; अक्षराने सुरू व्हावे. प्राइस फीडमधील बाजारासाठी त्याचे नाव ठेवा, जसे rajkot. हे नंतर बदलता येत नाही.';

  @override
  String get adminMandiActiveHint =>
      'बंद केल्यास ती वापरकर्त्यांपासून लपते; तिचे भाव राहतात.';

  @override
  String get adminStatesTitle => 'राज्ये आणि जिल्हे';

  @override
  String get adminStatesSubtitle => 'राज्ये आणि जिल्हे जोडा व नाव बदला';

  @override
  String get adminStatesIntro =>
      'नाव बदलण्यासाठी किंवा बंद करण्यासाठी राज्य किंवा जिल्ह्यावर टॅप करा. मंडया जिल्ह्यात असतात.';

  @override
  String get adminStatesEmpty => 'अजून कोणतेही राज्य नाही.';

  @override
  String get adminStateNew => 'नवीन राज्य';

  @override
  String get adminStateEdit => 'राज्य बदला';

  @override
  String get adminDistrictNew => 'नवीन जिल्हा';

  @override
  String get adminDistrictEdit => 'जिल्हा बदला';

  @override
  String get adminPlaceErrName => 'नाव लिहा.';

  @override
  String get adminStateCodeHint =>
      '2 ते 10 अक्षरे किंवा अंक, जसे MH. हे नंतर बदलता येत नाही.';

  @override
  String get adminStateErrCode => '2 ते 10 अक्षरे किंवा अंक वापरा.';

  @override
  String get adminPlaceActiveHint =>
      'बंद केल्यास ते वापरकर्त्यांपासून लपते; त्याच्या आतले सर्व राहते.';

  @override
  String get adminSuppliersTitle => 'पुरवठादार आणि हब';

  @override
  String get adminSuppliersSubtitle => 'पुरवठादार आणि हब शोधा, जोडा आणि बदला';

  @override
  String get adminSuppliersEmpty => 'कोणताही पुरवठादार सापडला नाही.';

  @override
  String get adminSupplierNew => 'नवीन पुरवठादार';

  @override
  String get adminSupplierEdit => 'पुरवठादार बदला';

  @override
  String get adminSupplierPhone => 'संपर्क फोन';

  @override
  String get adminSupplierPhoneHint => 'ऐच्छिक. अंक, देश कोडसाठी + सह.';

  @override
  String get adminSupplierErrPhone => 'योग्य फोन नंबर लिहा, किंवा रिकामा सोडा.';

  @override
  String get adminSupplierActiveHint =>
      'बंद केल्यास तो वापरकर्त्यांपासून लपतो.';

  @override
  String get adminCommoditiesTitle => 'वस्तू जोडा';

  @override
  String get adminCommoditiesSubtitle =>
      'प्राइस फीडमधील वस्तू कॅटलॉगमध्ये जोडा';

  @override
  String get adminCommoditiesIntro =>
      'उप-श्रेणी आणि एकक निवडा, मग मागील पूर्ण पुलमधून वस्तू निवडा. प्रत्येक वस्तू फीडच्या इंग्रजी नावासह उत्पादन म्हणून जोडली जाते, म्हणजे पुढच्या पुलमध्ये तिचे भाव सेव्ह करता येतील. हिंदी आणि मराठी नावे नंतर कॅटलॉगमध्ये जोडा.';

  @override
  String get adminCommoditiesNoFeed =>
      'प्राइस फीडमधील वस्तू अजून नोंदवल्या गेल्या नाहीत. फीडमध्ये डेटा असलेल्या दिवशी पूर्ण पुल (फिल्टरशिवाय आता चालवा) चालवा, मग परत या.';

  @override
  String get adminCommoditiesSubCategory => 'उप-श्रेणी';

  @override
  String get adminCommoditiesChooseSubCategory => 'उप-श्रेणी निवडा';

  @override
  String get adminCommoditiesUnit => 'एकक';

  @override
  String get adminCommoditiesChooseUnit => 'एकक निवडा';

  @override
  String get adminCommoditiesCommodities => 'वस्तू';

  @override
  String get adminCommoditiesChoose => 'वस्तू निवडा';

  @override
  String adminCommoditiesAdd(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count वस्तू जोडा',
      one: '1 वस्तू जोडा',
      zero: 'वस्तू जोडा',
    );
    return '$_temp0';
  }

  @override
  String adminCommoditiesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count वस्तू जोडल्या',
      one: '1 वस्तू जोडली',
      zero: 'कोणतीही वस्तू जोडली नाही',
    );
    return '$_temp0';
  }

  @override
  String get adminCommoditiesAddedHint =>
      'त्यांचे भाव पुढच्या पुलपासून सेव्ह होतील.';

  @override
  String get adminCommoditiesSkipNotInFeed => 'फीड यादीत नाही';

  @override
  String get appVersionTitle => 'कृपया MolBhav अपडेट करा';

  @override
  String get appVersionBody =>
      'अ‍ॅपची ही आवृत्ती आता समर्थित नाही. MolBhav वापरणे सुरू ठेवण्यासाठी अपडेट करा.';

  @override
  String appVersionYours(String installed, String minimum) {
    return 'तुमची आवृत्ती $installed · आवश्यक $minimum किंवा नवीन';
  }

  @override
  String get appVersionUpdate => 'आता अपडेट करा';

  @override
  String get adminVersionTitle => 'किमान अ‍ॅप आवृत्ती';

  @override
  String get adminVersionSubtitle =>
      'जुन्या बिल्डना वापरण्याआधी अपडेट करायला लावा';

  @override
  String get adminVersionIntro =>
      'यापेक्षा जुन्या बिल्डमध्ये अ‍ॅपऐवजी अपडेट पेज दिसते. प्रत्येक बिल्डला परवानगी देण्यासाठी आवृत्ती रिकामी ठेवा. अ‍ॅडमिन कधीही ब्लॉक होत नाहीत, त्यामुळे चूक नेहमी सुधारता येते.';

  @override
  String adminVersionThisApp(String version) {
    return 'हे अ‍ॅप आवृत्ती $version आहे.';
  }

  @override
  String get adminVersionMinimum => 'किमान आवृत्ती';

  @override
  String get adminVersionLink => 'अपडेट लिंक';

  @override
  String get adminVersionInvalid => '1.2.0 सारखी आवृत्ती लिहा.';

  @override
  String get adminVersionLinkInvalid =>
      'https:// ने सुरू होणारा वेब पत्ता लिहा.';

  @override
  String get adminFeaturesTitle => 'फीचर स्विच';

  @override
  String get adminFeaturesSubtitle =>
      'सर्वांसाठी अ‍ॅपचे भाग चालू किंवा बंद करा';

  @override
  String get adminFeaturesIntro =>
      'सर्व काही आपोआप चालू असते. तुम्ही बंद केलेला भाग सुमारे दहा मिनिटांत, किंवा अ‍ॅप पुन्हा उघडल्यावर, सर्व वापरकर्त्यांसाठी गायब होतो.';

  @override
  String get adminFeatureAds => 'जाहिराती';

  @override
  String get adminFeatureAdsHint =>
      'स्क्रीनमधील स्पॉन्सर्ड कार्ड आणि जाहिरात जागा. बॅनर आणि रिवॉर्ड जाहिरातींवर परिणाम होत नाही.';

  @override
  String get adminFeatureReports => 'अहवाल';

  @override
  String get adminFeatureReportsHint => 'अहवाल स्क्रीन आणि त्याचे शॉर्टकट';

  @override
  String get adminFeatureCostEstimator => 'खर्च अंदाजक';

  @override
  String get adminFeatureCostEstimatorHint => 'खर्च अंदाजक आणि त्याचे शॉर्टकट';

  @override
  String get appNoticeDismiss => 'संदेश बंद करा';

  @override
  String get appNoticeMaintenanceTitle => 'आम्ही लवकरच परत येऊ';

  @override
  String get appNoticeCheckAgain => 'पुन्हा तपासा';

  @override
  String get adminNoticeTitle => 'अ‍ॅप संदेश';

  @override
  String get adminNoticeSubtitle =>
      'सर्व वापरकर्त्यांना सूचना किंवा देखभाल पेज दाखवा';

  @override
  String get adminNoticeIntro =>
      'अ‍ॅपच्या प्रत्येक वापरकर्त्याला दिसणारा एक संदेश. गरज संपली की तो बंद करा; मजकूर जतन राहतो.';

  @override
  String get adminNoticeShow => 'वापरकर्त्यांना दाखवा';

  @override
  String get adminNoticeType => 'प्रकार';

  @override
  String get adminNoticeInfo => 'सूचना';

  @override
  String get adminNoticeWarning => 'इशारा';

  @override
  String get adminNoticeMaintenance => 'देखभाल';

  @override
  String get adminNoticeMaintenanceHint =>
      'देखभाल चालू असताना अ‍ॅपच्या जागी \"लवकरच परत\" पेज दिसते, तुम्ही ते बंद करेपर्यंत. अ‍ॅडमिन अ‍ॅप सुरू राहते.';

  @override
  String get adminNoticeMessage => 'संदेश';

  @override
  String get adminNoticeMessageHint => 'वापरकर्त्यांनी काय वाचावे?';

  @override
  String get adminNoticePreview => 'पूर्वावलोकन';

  @override
  String get adminNoticeSave => 'जतन करा';

  @override
  String get adminNoticeSaved => 'जतन केले';

  @override
  String get adminNoticeMessageRequired =>
      'वापरकर्त्यांसाठी संदेश लिहा, किंवा तो बंद करा.';

  @override
  String get adminHistoryTitle => 'पुल इतिहास';

  @override
  String get adminHistorySubtitle => 'अलीकडील रन आणि अयशस्वी झालेल्या ओळी';

  @override
  String get adminHistoryEmpty => 'अद्याप कोणताही रन नाही.';

  @override
  String get adminTriggerScheduled => 'वेळापत्रक';

  @override
  String get adminTriggerManual => 'मॅन्युअल';

  @override
  String get adminTriggerUpload => 'अपलोड';

  @override
  String get adminJobTitle => 'पुल रन';

  @override
  String get adminJobErrorsTitle => 'अयशस्वी ओळी';

  @override
  String get adminJobErrorsFailed => 'अयशस्वी ओळी लोड करता आल्या नाहीत.';

  @override
  String get adminJobShowMore => 'आणखी दाखवा';

  @override
  String get adminTabUsers => 'वापरकर्ते';

  @override
  String get cancelAction => 'रद्द करा';

  @override
  String get adminUsersSearchHint => 'फोन नंबर किंवा नाव शोधा';

  @override
  String get adminUsersEmpty => 'कोणताही वापरकर्ता सापडला नाही.';

  @override
  String get adminUserActive => 'सक्रिय';

  @override
  String get adminUserAdminBadge => 'ॲडमिन';

  @override
  String get adminUserDetailTitle => 'वापरकर्ता';

  @override
  String get adminUserPhone => 'फोन';

  @override
  String get adminUserLocation => 'ठिकाण';

  @override
  String get adminUserBusiness => 'व्यवसाय';

  @override
  String get adminUserCategories => 'श्रेणी';

  @override
  String get adminUserJoined => 'सामील झाले';

  @override
  String get adminUserLastLogin => 'शेवटचा लॉगिन';

  @override
  String get adminUserNever => 'कधीच नाही';

  @override
  String get adminUserSubscription => 'शेवटचे सदस्यत्व';

  @override
  String get adminUserSubscriptionNone => 'काहीही नाही';

  @override
  String adminUserSubscriptionValue(String plan, String status, String date) {
    return '$plan · $status · $date पर्यंत';
  }

  @override
  String get adminUserTickets => 'मदत तिकिटे';

  @override
  String adminUserTicketsValue(int total, int open) {
    return 'एकूण $total · उघडी $open';
  }

  @override
  String get adminUserSuspendAction => 'खाते निलंबित करा';

  @override
  String get adminUserReinstateAction => 'खाते पुन्हा सुरू करा';

  @override
  String get adminUserSuspendTitle => 'हे खाते निलंबित करायचे?';

  @override
  String get adminUserSuspendBody =>
      'तुम्ही पुन्हा सुरू करेपर्यंत त्यांना साइन इन करता येणार नाही आणि सत्र नूतनीकरण करता येणार नाही.';

  @override
  String get adminUserSuspendConfirm => 'निलंबित करा';

  @override
  String adminRangeDays(int days) {
    return '$days दिवस';
  }

  @override
  String get adminAdsTotalsTitle => 'डिलिव्हरी';

  @override
  String get adminAdsClicks => 'क्लिक';

  @override
  String get adminAdsImpressions => 'इम्प्रेशन';

  @override
  String get adminAdsClickRateShort => 'क्लिक दर';

  @override
  String get adminAdsDailyClicks => 'रोजचे क्लिक';

  @override
  String get adminAdsCampaignsTitle => 'मोहिमा';

  @override
  String get adminAdsNoCampaigns => 'अद्याप कोणतीही मोहीम नाही.';

  @override
  String adminAdsChangeNote(int days) {
    return 'मागील $days दिवसांच्या तुलनेत बदल.';
  }

  @override
  String get adminAdsPlacementsTitle => 'प्लेसमेंट';

  @override
  String adminAdsCampaignCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count मोहिमा',
      one: '1 मोहीम',
    );
    return '$_temp0';
  }

  @override
  String get adminAdsChangeNew => 'नवीन';

  @override
  String adminAdsChangePoints(String value) {
    return '$value गुण';
  }

  @override
  String get adminAdsDailyImpressions => 'रोजचे इंप्रेशन';

  @override
  String get adminAdsDailyClickRate => 'रोजचा क्लिक दर';

  @override
  String get adminCampaignTitle => 'मोहीम';

  @override
  String get adminCampaignNoDelivery =>
      'या कालावधीत या मोहिमेची कोणतीही जाहिरात दाखवली गेली नाही.';

  @override
  String get campaignStatusDraft => 'मसुदा';

  @override
  String get campaignStatusActive => 'सुरू';

  @override
  String get campaignStatusPaused => 'थांबवलेली';

  @override
  String get campaignStatusEnded => 'संपलेली';

  @override
  String get adminSwitchToUserView => 'वापरकर्त्याप्रमाणे पहा';

  @override
  String get adminSwitchToAdminView => 'ॲडमिन व्ह्यू';

  @override
  String get adminSwitchToAdminViewSubtitle =>
      'डॅशबोर्ड, जाहिराती, वापरकर्ते आणि ॲप व्यवस्थापन';

  @override
  String get adminUsersTitle => 'वापरकर्ते';

  @override
  String get adminUsersTotal => 'एकूण वापरकर्ते';

  @override
  String get adminUsersNew => 'नवीन (7 दिवस)';

  @override
  String get adminUsersActive => 'सक्रिय (7 दिवस)';

  @override
  String get adminUsersPro => 'प्रो';

  @override
  String get adminUsersFree => 'फ्री';

  @override
  String get adminUsersSuspended => 'निलंबित';

  @override
  String get adminAdsTitle => 'जाहिराती';

  @override
  String get adminAdsClicksToday => 'आजचे क्लिक';

  @override
  String get adminAdsImpressionsToday => 'आजचे इम्प्रेशन';

  @override
  String get adminAdsClickRate => 'क्लिक दर (7 दिवस)';

  @override
  String get adminAdsCampaigns => 'सुरू मोहिमा';

  @override
  String get adminAdsRewarded => 'रिवॉर्ड व्ह्यू (7 दिवस)';

  @override
  String get adminAdsNote =>
      'आम्ही दाखवलेल्या स्पॉन्सर्ड जाहिराती आणि रिवॉर्ड व्ह्यू. AdMob बॅनरचे क्लिक AdMob मध्ये दिसतात.';

  @override
  String get adminFeedsTitle => 'भाव डेटा';

  @override
  String get adminFeedsOk => 'अद्ययावत';

  @override
  String get adminFeedsDelayed => 'उशीर';

  @override
  String get adminFeedsLastUpdated => 'शेवटचे अपडेट';

  @override
  String get adminFeedsLastAttempt => 'शेवटचा पुल';

  @override
  String get adminSupportTitle => 'मदत';

  @override
  String get adminSupportOpen => 'उघडी तिकिटे';

  @override
  String get adminSchedulesHint =>
      'वेळ भारतीय प्रमाण वेळेनुसार आहे. वेळापत्रक नसलेला स्रोत फक्त \'आता चालवा\' दाबल्यावर आणला जातो.';

  @override
  String get adminNoSources => 'अद्याप कोणताही भाव स्रोत नाही.';

  @override
  String scheduleDaily(String time) {
    return 'दररोज $time IST ला';
  }

  @override
  String scheduleWeekly(String day, String time) {
    return 'दर $day $time IST ला';
  }

  @override
  String scheduleEveryNHours(String hours, String time) {
    return '$time IST पासून दर $hours तासांनी';
  }

  @override
  String get scheduleNotConfigured => 'वेळापत्रक नाही';

  @override
  String get scheduleStatusOn => 'चालू';

  @override
  String get scheduleStatusPaused => 'थांबवले';

  @override
  String get scheduleStatusNone => 'वेळापत्रक नाही';

  @override
  String get sourceInactive => 'स्रोत बंद आहे';

  @override
  String scheduleNextRun(String when) {
    return 'पुढील वेळ: $when';
  }

  @override
  String scheduleLastRun(String when, String status) {
    return 'मागील वेळ: $when · $status';
  }

  @override
  String get jobStatusRunning => 'चालू आहे';

  @override
  String get jobStatusSucceeded => 'यशस्वी';

  @override
  String get jobStatusPartial => 'अंशतः सेव्ह';

  @override
  String get jobStatusFailed => 'अयशस्वी';

  @override
  String jobCounts(String saved, String failed) {
    return '$saved सेव्ह, $failed अयशस्वी';
  }

  @override
  String get runNowAction => 'आता चालवा';

  @override
  String get editScheduleAction => 'वेळापत्रक बदला';

  @override
  String get saveScheduleAction => 'वेळापत्रक सेव्ह करा';

  @override
  String get scheduleFrequencyLabel => 'किती वेळा';

  @override
  String get frequencyDaily => 'दररोज';

  @override
  String get frequencyWeekly => 'दर आठवड्याला';

  @override
  String get frequencyEveryNHours => 'काही तासांनी';

  @override
  String get scheduleTimeLabel => 'वेळ (IST)';

  @override
  String get scheduleDayLabel => 'दिवस';

  @override
  String get scheduleIntervalLabel => 'इतक्या वेळाने';

  @override
  String intervalHoursOption(String hours) {
    return '$hours तास';
  }

  @override
  String get scheduleEnabledLabel => 'आपोआप चालवा';

  @override
  String get scheduleFilterTitle => 'काय आणायचे';

  @override
  String get scheduleFilterHint =>
      'काय आणायचे ते निवडा. सर्व काही आणण्यासाठी बॉक्स \"सर्व\" वरच ठेवा.';

  @override
  String get filterStatesLabel => 'राज्ये';

  @override
  String get filterCommoditiesLabel => 'शेतमाल';

  @override
  String get filterMarketsLabel => 'बाजार समित्या';

  @override
  String get filterAllOption => 'सर्व';

  @override
  String filterSelectedCount(int count) {
    return '$count निवडले';
  }

  @override
  String get filterSearchHint => 'शोधा';

  @override
  String get filterOptionsEmpty =>
      'पहिल्या पूर्ण पुलनंतर याद्या भरतात. त्यासाठी सर्व काही \"सर्व\" वर ठेवून आता चालवा.';

  @override
  String get filterOptionsError =>
      'पर्याय लोड करता आले नाहीत. हे बंद करून पुन्हा प्रयत्न करा.';

  @override
  String get runFilterNote =>
      'फिल्टर फक्त याच वेळेसाठी आहे. वेळापत्रकानुसार होणारे रन नेहमी सर्व काही आणतात.';

  @override
  String get scheduleSaved => 'वेळापत्रक सेव्ह झाले.';

  @override
  String get runCompleted => 'चालवणे पूर्ण झाले. कार्डवर मागील वेळ पहा.';

  @override
  String get backfillAction => 'मागील दिवसांचा डेटा आणा';

  @override
  String get backfillPickerTitle => 'कोणते बाजार दिवस आणायचे';

  @override
  String backfillTooLong(String max) {
    return 'एका वेळी जास्तीत जास्त $max दिवस निवडा.';
  }

  @override
  String backfillQueued(String days) {
    return '$days दिवस रांगेत आहेत. पूर्ण झाल्यावर खाली ओढून रिफ्रेश करा.';
  }

  @override
  String jobMarketDay(String date) {
    return 'बाजार दिवस: $date';
  }

  @override
  String jobUnchanged(String count) {
    return '$count बदल नाही';
  }

  @override
  String get uploadCsvAction => 'CSV अपलोड करा';

  @override
  String get uploadCompleted => 'CSV आयात झाले. कार्डवर मागील वेळ पहा.';

  @override
  String get uploadTooLarge =>
      'फाइल 10 MB पेक्षा मोठी आहे. ती तारीख किंवा राज्यानुसार विभागा.';

  @override
  String get jobFromUpload => 'CSV अपलोडमधून';

  @override
  String get adminAllCategories => 'सर्व';

  @override
  String get runAllAction => 'सर्व चालवा';

  @override
  String categoryRunQueued(String count) {
    return '$count स्रोत रांगेत. पूर्ण झाल्यावर पाहण्यासाठी खाली ओढा.';
  }

  @override
  String get addSourceAction => 'स्रोत जोडा';

  @override
  String get editSourceAction => 'स्रोत बदला';

  @override
  String get sourceCodeLabel => 'कोड';

  @override
  String get sourceCodeHint => 'उदा. cpwd-dsr. नंतर बदलता येत नाही.';

  @override
  String get sourceCodeInvalid =>
      'लहान इंग्रजी अक्षरे, अंक आणि हायफन वापरा, सुरुवात अक्षराने.';

  @override
  String get sourceNameLabel => 'नाव';

  @override
  String get sourceNameRequired => 'नाव लिहा.';

  @override
  String get sourceCategoryLabel => 'श्रेणी';

  @override
  String get sourceActiveLabel => 'सक्रिय';

  @override
  String get saveSourceAction => 'स्रोत जतन करा';

  @override
  String get sourceCreated => 'स्रोत जोडला.';

  @override
  String get sourceUpdated => 'स्रोत अपडेट झाला.';

  @override
  String get categoryNoSources => 'या श्रेणीत अजून स्रोत नाही.';

  @override
  String get csvTemplateAction => 'CSV स्वरूप';

  @override
  String get csvTemplateTitle => 'CSV टेम्पलेट';

  @override
  String get csvTemplateBody =>
      'प्रत्येक स्रोत अशी CSV घेतो जिची पहिली ओळ हा हेडर असेल. MolBhav उत्पादन कोड आणि बाजार किंवा पुरवठादार कोड वापरा; location_kind मध्ये mandi किंवा supplier; तारीख yyyy-MM-dd. स्रोताच्या श्रेणीबाहेरील उत्पादनांच्या ओळी नाकारल्या जातात. Agmarknet, data.gov.in आणि पोर्टलच्या फाइल्सही घेतो.';

  @override
  String get csvTemplateCopied => 'हेडर कॉपी झाला.';

  @override
  String get weatherTitle => 'हवामान';

  @override
  String get weatherToday => 'आज';

  @override
  String get weatherTomorrow => 'उद्या';

  @override
  String get weatherSevenDay => '7 दिवसांचा अंदाज';

  @override
  String get weatherSelectDay => 'दिवस निवडा';

  @override
  String weatherStation(String station) {
    return 'IMD · $station';
  }

  @override
  String weatherRainChance(String percent) {
    return '$percent% पाऊस';
  }

  @override
  String get weatherHumidity => 'आर्द्रता';

  @override
  String get weatherWind => 'वारा';

  @override
  String weatherWindValue(String speed) {
    return '$speed किमी/तास';
  }

  @override
  String weatherTempRange(String min, String max) {
    return '$min° / $max°';
  }

  @override
  String weatherTempDegrees(String temp) {
    return '$temp°';
  }

  @override
  String weatherUpdated(String time) {
    return 'अपडेट: $time';
  }

  @override
  String get weatherClear => 'निरभ्र';

  @override
  String get weatherPartlyCloudy => 'अंशतः ढगाळ';

  @override
  String get weatherCloudy => 'ढगाळ';

  @override
  String get weatherRain => 'पाऊस';

  @override
  String get weatherThunderstorm => 'वादळी पाऊस';

  @override
  String get weatherPermissionTitle => 'तुमच्या भागाचे हवामान दाखवायचे?';

  @override
  String get weatherPermissionBody =>
      'जवळचे IMD हवामान केंद्र शोधण्यासाठी MolBhav एकदा तुमचे अंदाजे लोकेशन वापरते. ते याच डिव्हाइसवर राहते.';

  @override
  String get weatherAllow => 'परवानगी द्या';

  @override
  String get weatherNotNow => 'आत्ता नको';

  @override
  String get weatherEnableLocation => 'लोकेशन सुरू करा';

  @override
  String get weatherOpenSettings => 'सेटिंग्ज उघडा';

  @override
  String get weatherNoForecast => 'अंदाज नाही';

  @override
  String get weatherNoForecastBody =>
      'तुमच्या भागाचे हवामान पाहण्यासाठी लोकेशनला परवानगी द्या.';

  @override
  String get weatherServiceOff =>
      'लोकेशन बंद आहे. तुमच्या भागाचे हवामान पाहण्यासाठी ते सुरू करा.';

  @override
  String get weatherDeniedForever =>
      'लोकेशन परवानगी बंद आहे. हवामान पाहण्यासाठी सेटिंग्जमध्ये परवानगी द्या.';

  @override
  String get weatherOutOfCoverage => 'तुमच्याजवळ IMD हवामान केंद्र नाही.';

  @override
  String get weatherUnavailable => 'तुमचे लोकेशन सापडले नाही.';

  @override
  String alertRuleConditionChange(String percent) {
    return '$percent% बदल (वर किंवा खाली)';
  }

  @override
  String get savePasswordLabel => 'पासवर्ड जतन करा';

  @override
  String get savePasswordHint =>
      'या फोनवर सुरक्षितपणे ठेवला जातो. सामायिक फोनवर बंद करा.';

  @override
  String get continueWithGoogle => 'Google ने पुढे जा';

  @override
  String get orDivider => 'किंवा';

  @override
  String get googlePhoneTitle => 'अजून एक पायरी';

  @override
  String get googlePhoneSubtitle =>
      'तुमचा मोबाइल नंबर टाका. तो WhatsApp भाव अलर्ट आणि मदतीसाठी वापरला जातो.';

  @override
  String get googlePhoneContinue => 'खाते तयार करा';

  @override
  String get googleAccountExists =>
      'या मोबाइल नंबरचे खाते आधीच आहे. पासवर्डने लॉग इन करा, नंतर More मध्ये Google जोडा.';

  @override
  String get googleSignInFailed =>
      'Google ने साइन-इन झाले नाही. पुन्हा प्रयत्न करा.';

  @override
  String get googleSignInTitle => 'Google साइन-इन';

  @override
  String get googleLinked => 'जोडलेले';

  @override
  String googleLinkedAs(String email) {
    return 'जोडलेले: $email';
  }

  @override
  String get googleUnlinkAction => 'काढा';

  @override
  String get googleLinkAction => 'Google खाते जोडा';

  @override
  String get googleLinkHint =>
      'पुढच्या वेळी पासवर्डऐवजी Google ने साइन-इन करा.';

  @override
  String get googleLinkedElsewhere =>
      'हे Google खाते दुसऱ्या MolBhav खात्याशी जोडलेले आहे.';

  @override
  String get googleLastSignInMethod =>
      'Google काढण्यापूर्वी पासवर्ड सेट करा — साइन-इनचा हाच एक मार्ग आहे.';

  @override
  String get weatherHomePrompt => 'तुमच्या भागाचे हवामान पाहण्यासाठी टॅप करा';

  @override
  String get weatherHomeLoading => 'हवामानाचा अंदाज आणत आहोत…';

  @override
  String get notificationPrefsSaveFailed =>
      'तुमची नोटिफिकेशन सेटिंग सेव्ह झाली नाही. कृपया पुन्हा प्रयत्न करा.';

  @override
  String opportunityTitle(String product, String percent, String market) {
    return '$product $market मध्ये $percent% स्वस्त आहे';
  }

  @override
  String opportunityHomePrice(String market, String price) {
    return '$market: $price';
  }

  @override
  String opportunityLandedPrice(String price) {
    return 'खर्चासह भाव: $price';
  }

  @override
  String opportunityMeta(String percent, String market) {
    return 'खर्चानंतर $market पेक्षा $percent% स्वस्त';
  }

  @override
  String get adminFindOpportunities => 'आता संधी शोधा';

  @override
  String adminOpportunitiesResult(int found, int compared) {
    return '$found नवीन संधी ($compared वॉचलिस्ट आयटमची तुलना)';
  }

  @override
  String get adminOpportunitiesFailed => 'संधी शोध चालवता आला नाही.';

  @override
  String get alertRuleDeleteFailed =>
      'हा अलर्ट हटवता आला नाही. कृपया पुन्हा प्रयत्न करा.';

  @override
  String homeOpportunityPosition(int index, int count) {
    return 'संधी $index / $count';
  }

  @override
  String comparisonMarketsSelected(int count, int total) {
    return '$total पैकी $count बाजार';
  }

  @override
  String get comparisonChooseMarkets => 'बाजार निवडा';

  @override
  String get searchMarketsHint => 'बाजार शोधा';

  @override
  String get selectAllAction => 'सर्व निवडा';

  @override
  String get clearSelectionAction => 'काढा';

  @override
  String get applyAction => 'लागू करा';

  @override
  String comparisonShowAll(int count) {
    return 'सर्व $count बाजार दाखवा';
  }

  @override
  String get comparisonShowFewer => 'कमी दाखवा';

  @override
  String get opportunitiesEmpty =>
      'अजून खरेदीची संधी नाही. तुमच्या वॉचलिस्टमधील उत्पादन खर्चानंतर दुसऱ्या बाजारात किमान 10% स्वस्त असेल तेव्हा इथे दिसेल.';

  @override
  String opportunityShareText(
    String product,
    String price,
    String unit,
    String market,
    String saving,
    String quantity,
    String reference,
  ) {
    return '$product: $market येथे $price/$unit — $quantity वर $reference पेक्षा $saving स्वस्त (खर्चानंतर). MolBhav वर मिळाले.';
  }

  @override
  String get editQuantityTitle => 'आवश्यक प्रमाण';

  @override
  String get editQuantityHelper => 'या प्रमाणासाठी बचत पुन्हा मोजते.';
}
