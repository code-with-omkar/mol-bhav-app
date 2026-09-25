// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Gujarati (`gu`).
class AppLocalizationsGu extends AppLocalizations {
  AppLocalizationsGu([String locale = 'gu']) : super(locale);

  @override
  String get appTitle => 'MolBhav';

  @override
  String get retry => 'Retry';

  @override
  String get back => 'Back';

  @override
  String get loading => 'Loading';

  @override
  String get errorNetwork =>
      'No internet connection. Check your network and try again.';

  @override
  String get errorServer =>
      'Something went wrong on our side. Please try again.';

  @override
  String get errorSession => 'Your session has expired. Please log in again.';

  @override
  String get errorUnexpected => 'Something went wrong. Please try again.';

  @override
  String get taglineTranslation =>
      'Know the value. Compare the price. Buy better.';

  @override
  String get loginTitle => 'Log in with your mobile';

  @override
  String get loginSubtitle =>
      'We\'ll send a 6-digit OTP to verify your number.';

  @override
  String get mobileNumberLabel => 'Mobile number';

  @override
  String get mobileNumberHint => '98765 43210';

  @override
  String get mobileNumberInvalid => 'Enter a valid 10-digit mobile number.';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get appLanguage => 'App language';

  @override
  String get loginPrivacyNote => 'Your number is only used to sign you in.';

  @override
  String get otpTitle => 'Enter the OTP';

  @override
  String otpSentTo(String phone) {
    return 'Sent to $phone';
  }

  @override
  String get otpChangeNumber => 'Change';

  @override
  String otpResendIn(String time) {
    return 'Resend OTP in $time';
  }

  @override
  String get otpResend => 'Resend OTP';

  @override
  String get otpResent => 'A new OTP has been sent.';

  @override
  String get otpVerify => 'Verify & Continue';

  @override
  String get otpInvalid => 'The OTP is incorrect or has expired.';

  @override
  String get otpFieldLabel => 'One-time password';

  @override
  String get profileTitle => 'Your business';

  @override
  String get profileStep =>
      'Step 1 of 2 · Helps us show prices from the markets you buy in.';

  @override
  String get businessTypeLabel => 'Business type';

  @override
  String get stateLabel => 'State';

  @override
  String get districtLabel => 'District';

  @override
  String get selectPlaceholder => 'Select';

  @override
  String get selectStateFirst => 'Select a state first';

  @override
  String get preferredLanguageLabel => 'Preferred language';

  @override
  String get preferredLanguageHelper =>
      'Alerts, WhatsApp messages and reports use this language.';

  @override
  String get districtsLoadError => 'Couldn\'t load districts.';

  @override
  String get continueAction => 'Continue';

  @override
  String get selectCategoryTitle => 'Select Category';

  @override
  String get selectCategorySubtitle =>
      'Choose your procurement categories to get started. You can add more later.';

  @override
  String continueSelected(int count) {
    return 'Continue ($count selected)';
  }

  @override
  String get categoryComingSoon => 'Coming soon';

  @override
  String get categoriesEmpty => 'No categories are available right now.';

  @override
  String get navHome => 'Home';

  @override
  String get navMarkets => 'Markets';

  @override
  String get navWatchlist => 'Watchlist';

  @override
  String get navOpportunities => 'Opportunities';

  @override
  String get navMore => 'More';

  @override
  String get priceUp => 'Price up';

  @override
  String get priceDown => 'Price down';

  @override
  String get priceFlat => 'No change';

  @override
  String timeToday(String time) {
    return 'Today, $time';
  }

  @override
  String timeYesterday(String time) {
    return 'Yesterday, $time';
  }

  @override
  String timeOnDate(String date, String time) {
    return '$date, $time';
  }

  @override
  String updatedAt(String when) {
    return 'Updated $when';
  }

  @override
  String get greetingMorning => 'Good Morning,';

  @override
  String get greetingAfternoon => 'Good Afternoon,';

  @override
  String get greetingEvening => 'Good Evening,';

  @override
  String get homeSubtitle =>
      'Find the best buying opportunity for your business today.';

  @override
  String get homeBuyingToday => 'What are you buying today?';

  @override
  String get homeTopOpportunities => 'Today\'s Top Opportunities';

  @override
  String get viewAll => 'View All';

  @override
  String get homeMyWatchlist => 'My Watchlist';

  @override
  String get compareMarkets => 'Compare Markets';

  @override
  String get alertsLabel => 'Alerts';

  @override
  String bestPriceIn(String market) {
    return 'Best price in $market';
  }

  @override
  String get homeNoOpportunity => 'No new opportunities right now.';

  @override
  String get watchlistEmpty => 'Your watchlist is empty.';

  @override
  String get marketComparisonTitle => 'Market Comparison';

  @override
  String get share => 'Share';

  @override
  String get commodityLabel => 'Commodity';

  @override
  String get marketsLabel => 'Markets';

  @override
  String get columnMarket => 'Market';

  @override
  String columnPricePer(String unit) {
    return 'Price (₹/$unit)';
  }

  @override
  String get columnChange => 'Change';

  @override
  String arrivals(String quantity) {
    return 'Arrivals $quantity';
  }

  @override
  String bestMarket(String market) {
    return 'Best Market · $market';
  }

  @override
  String lowerThanYourMarket(String amount, String market) {
    return '$amount lower than $market (your market)';
  }

  @override
  String get comparisonEmpty => 'No prices for these markets yet.';

  @override
  String get priceTrendsTitle => 'Price Trends';

  @override
  String get createAlertAction => 'Create alert';

  @override
  String trendTitle(String commodity, String market, String unit) {
    return '$commodity — $market (₹/$unit)';
  }

  @override
  String get statMin => 'Min';

  @override
  String get statModal => 'Modal';

  @override
  String get statMax => 'Max';

  @override
  String get relatedMarkets => 'Related Markets';

  @override
  String get trendsEmpty => 'No price history for this range.';

  @override
  String get buyingOpportunityTitle => 'Buying Opportunity';

  @override
  String get editRequirement => 'Edit requirement';

  @override
  String requirementLine(String quantity, String place) {
    return 'Required quantity · $quantity · Deliver to $place';
  }

  @override
  String get bestPriceBadge => 'Best Price';

  @override
  String get potentialDifference => 'Potential Difference';

  @override
  String differenceCaption(String quantity, String market) {
    return 'on $quantity vs. buying in $market';
  }

  @override
  String get howCalculated => 'How we calculated this';

  @override
  String calculationLine(
    String reference,
    String best,
    String quantity,
    String total,
  ) {
    return '($reference − $best) × $quantity = $total. Freight and handling are not included yet.';
  }

  @override
  String viewSuppliers(String market) {
    return 'View $market Suppliers';
  }

  @override
  String get watchlistTitle => 'My Watchlist';

  @override
  String get search => 'Search';

  @override
  String get addItem => 'Add item';

  @override
  String get filterAll => 'All';

  @override
  String alertBelow(String price) {
    return 'alert below $price';
  }

  @override
  String alertAbove(String price) {
    return 'alert above $price';
  }

  @override
  String get alertsTitle => 'Alerts';

  @override
  String get alertSettings => 'Alert settings';

  @override
  String get filterPriceSignals => 'Price Signals';

  @override
  String get filterOpportunities => 'Opportunities';

  @override
  String get kindSignal => 'Price Signal';

  @override
  String get kindOpportunity => 'Opportunity';

  @override
  String get kindSpike => 'Price Spike';

  @override
  String get sentOnWhatsApp => 'Sent on WhatsApp';

  @override
  String get sentAsPush => 'Push notification';

  @override
  String get viewOpportunity => 'View Opportunity';

  @override
  String get viewDetails => 'View Details';

  @override
  String get alertsEmpty => 'No alerts yet.';

  @override
  String get createAlertTitle => 'Create Alert';

  @override
  String get productLabel => 'Product';

  @override
  String get marketLabel => 'Market';

  @override
  String get notifyWhen => 'Notify me when price';

  @override
  String get conditionBelow => 'Drops below';

  @override
  String get conditionAbove => 'Rises above';

  @override
  String get conditionPercent => 'Changes by %';

  @override
  String get priceLabel => 'Price';

  @override
  String get changeLabel => 'Change';

  @override
  String currentPriceIn(String market, String price) {
    return 'Current price in $market: $price';
  }

  @override
  String get sendVia => 'Send alert via';

  @override
  String get pushNotification => 'Push notification';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String whatsappTarget(String phone, String language) {
    return '$phone · in $language';
  }

  @override
  String get saveAlert => 'Save Alert';

  @override
  String get alertSaved => 'Alert saved.';

  @override
  String get costEstimatorTitle => 'Cost Estimator';

  @override
  String get materialLabel => 'Material';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get unitLabel => 'Unit';

  @override
  String get deliverToLabel => 'Deliver to';

  @override
  String get estimatedCost => 'Estimated cost';

  @override
  String estimateCaption(
    String quantity,
    String unit,
    String price,
    String source,
  ) {
    return '$quantity $unit × $price (lowest benchmark, $source)';
  }

  @override
  String estimateSavings(String amount, String average) {
    return 'Saves $amount vs. district average $average. Freight, handling and GST not included.';
  }

  @override
  String get columnSource => 'Source';

  @override
  String columnRupeePer(String unit) {
    return '₹/$unit';
  }

  @override
  String get saveEstimate => 'Save Estimate';

  @override
  String get estimateSaved => 'Estimate saved.';

  @override
  String get estimatePrompt => 'Enter a quantity to see the estimated cost.';

  @override
  String get reportsTitle => 'Reports';

  @override
  String thisWeek(String range) {
    return 'This week · $range';
  }

  @override
  String potentialSavingsFound(String amount) {
    return '$amount potential savings found';
  }

  @override
  String weekStats(String items, String alerts, String opportunities) {
    return '$items watchlist items · $alerts alerts · $opportunities opportunities';
  }

  @override
  String downloadPdf(String language) {
    return 'Download PDF ($language)';
  }

  @override
  String get weeklySummaries => 'Weekly summaries';

  @override
  String summaryTitle(String range) {
    return '$range summary';
  }

  @override
  String summaryMeta(String language, String pages) {
    return 'PDF · $language · $pages pages';
  }

  @override
  String get exportsTitle => 'Exports';

  @override
  String get proBadge => 'Pro';

  @override
  String get download => 'Download';

  @override
  String get reportsEmpty => 'No reports yet.';

  @override
  String get moreTitle => 'More';

  @override
  String get molbhavPro => 'MolBhav Pro';

  @override
  String get proSubtitle => 'Advanced alerts, exports, 1-year history';

  @override
  String pricePerMonth(String price) {
    return '$price/mo';
  }

  @override
  String get myCategories => 'My categories';

  @override
  String get languageLabel => 'Language';

  @override
  String get pushNotifications => 'Push notifications';

  @override
  String get whatsappAlerts => 'WhatsApp alerts';

  @override
  String get helpSupport => 'Help & support';

  @override
  String get logOut => 'Log out';

  @override
  String placeLine(String district, String state) {
    return '$district, $state';
  }

  @override
  String get choosePlanTitle => 'Choose your plan';

  @override
  String get currentPlan => 'Current plan';

  @override
  String get perMonth => '/ month';

  @override
  String get perYear => '/ year';

  @override
  String upgradeTo(String plan) {
    return 'Upgrade to $plan';
  }

  @override
  String get cancelAnytime => 'Cancel anytime. Prices include GST.';
}
