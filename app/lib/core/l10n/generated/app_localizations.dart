import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
    Locale('kn'),
    Locale('mr'),
    Locale('ta'),
    Locale('te'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MolBhav'**
  String get appTitle;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network and try again.'**
  String get errorNetwork;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Please try again.'**
  String get errorServer;

  /// No description provided for @errorSession.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please log in again.'**
  String get errorSession;

  /// No description provided for @errorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnexpected;

  /// Translation of the Hindi brand tagline, shown under it.
  ///
  /// In en, this message translates to:
  /// **'Know the value. Compare the price. Buy better.'**
  String get taglineTranslation;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in with your mobile'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a 6-digit OTP to verify your number.'**
  String get loginSubtitle;

  /// No description provided for @mobileNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobileNumberLabel;

  /// Placeholder showing the 5+5 digit grouping.
  ///
  /// In en, this message translates to:
  /// **'98765 43210'**
  String get mobileNumberHint;

  /// No description provided for @mobileNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit mobile number.'**
  String get mobileNumberInvalid;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguage;

  /// No description provided for @loginPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your number is only used to sign you in.'**
  String get loginPrivacyNote;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the OTP'**
  String get otpTitle;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Sent to {phone}'**
  String otpSentTo(String phone);

  /// No description provided for @otpChangeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get otpChangeNumber;

  /// No description provided for @otpResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP in {time}'**
  String otpResendIn(String time);

  /// No description provided for @otpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get otpResend;

  /// No description provided for @otpResent.
  ///
  /// In en, this message translates to:
  /// **'A new OTP has been sent.'**
  String get otpResent;

  /// No description provided for @otpVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify & Continue'**
  String get otpVerify;

  /// No description provided for @otpInvalid.
  ///
  /// In en, this message translates to:
  /// **'The OTP is incorrect or has expired.'**
  String get otpInvalid;

  /// No description provided for @otpFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'One-time password'**
  String get otpFieldLabel;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your business'**
  String get profileTitle;

  /// No description provided for @profileStep.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 2 · Helps us show prices from the markets you buy in.'**
  String get profileStep;

  /// No description provided for @businessTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Business type'**
  String get businessTypeLabel;

  /// No description provided for @stateLabel.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get stateLabel;

  /// No description provided for @districtLabel.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get districtLabel;

  /// No description provided for @selectPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectPlaceholder;

  /// No description provided for @selectStateFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a state first'**
  String get selectStateFirst;

  /// No description provided for @preferredLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred language'**
  String get preferredLanguageLabel;

  /// No description provided for @preferredLanguageHelper.
  ///
  /// In en, this message translates to:
  /// **'Alerts, WhatsApp messages and reports use this language.'**
  String get preferredLanguageHelper;

  /// No description provided for @districtsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load districts.'**
  String get districtsLoadError;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @selectCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategoryTitle;

  /// No description provided for @selectCategorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your procurement categories to get started. You can add more later.'**
  String get selectCategorySubtitle;

  /// No description provided for @continueSelected.
  ///
  /// In en, this message translates to:
  /// **'Continue ({count} selected)'**
  String continueSelected(int count);

  /// No description provided for @categoryComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get categoryComingSoon;

  /// No description provided for @categoriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No categories are available right now.'**
  String get categoriesEmpty;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMarkets.
  ///
  /// In en, this message translates to:
  /// **'Markets'**
  String get navMarkets;

  /// No description provided for @navWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Watchlist'**
  String get navWatchlist;

  /// No description provided for @navOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Opportunities'**
  String get navOpportunities;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @priceUp.
  ///
  /// In en, this message translates to:
  /// **'Price up'**
  String get priceUp;

  /// No description provided for @priceDown.
  ///
  /// In en, this message translates to:
  /// **'Price down'**
  String get priceDown;

  /// No description provided for @priceFlat.
  ///
  /// In en, this message translates to:
  /// **'No change'**
  String get priceFlat;

  /// No description provided for @timeToday.
  ///
  /// In en, this message translates to:
  /// **'Today, {time}'**
  String timeToday(String time);

  /// No description provided for @timeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday, {time}'**
  String timeYesterday(String time);

  /// No description provided for @timeOnDate.
  ///
  /// In en, this message translates to:
  /// **'{date}, {time}'**
  String timeOnDate(String date, String time);

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated {when}'**
  String updatedAt(String when);

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning,'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon,'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening,'**
  String get greetingEvening;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find the best buying opportunity for your business today.'**
  String get homeSubtitle;

  /// No description provided for @homeBuyingToday.
  ///
  /// In en, this message translates to:
  /// **'What are you buying today?'**
  String get homeBuyingToday;

  /// No description provided for @homeTopOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Top Opportunities'**
  String get homeTopOpportunities;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @homeMyWatchlist.
  ///
  /// In en, this message translates to:
  /// **'My Watchlist'**
  String get homeMyWatchlist;

  /// No description provided for @compareMarkets.
  ///
  /// In en, this message translates to:
  /// **'Compare Markets'**
  String get compareMarkets;

  /// No description provided for @alertsLabel.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsLabel;

  /// No description provided for @bestPriceIn.
  ///
  /// In en, this message translates to:
  /// **'Best price in {market}'**
  String bestPriceIn(String market);

  /// No description provided for @homeNoOpportunity.
  ///
  /// In en, this message translates to:
  /// **'No new opportunities right now.'**
  String get homeNoOpportunity;

  /// No description provided for @watchlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your watchlist is empty.'**
  String get watchlistEmpty;

  /// No description provided for @marketComparisonTitle.
  ///
  /// In en, this message translates to:
  /// **'Market Comparison'**
  String get marketComparisonTitle;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @commodityLabel.
  ///
  /// In en, this message translates to:
  /// **'Commodity'**
  String get commodityLabel;

  /// No description provided for @marketsLabel.
  ///
  /// In en, this message translates to:
  /// **'Markets'**
  String get marketsLabel;

  /// No description provided for @columnMarket.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get columnMarket;

  /// No description provided for @columnPricePer.
  ///
  /// In en, this message translates to:
  /// **'Price (₹/{unit})'**
  String columnPricePer(String unit);

  /// No description provided for @columnChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get columnChange;

  /// No description provided for @arrivals.
  ///
  /// In en, this message translates to:
  /// **'Arrivals {quantity}'**
  String arrivals(String quantity);

  /// No description provided for @bestMarket.
  ///
  /// In en, this message translates to:
  /// **'Best Market · {market}'**
  String bestMarket(String market);

  /// No description provided for @lowerThanYourMarket.
  ///
  /// In en, this message translates to:
  /// **'{amount} lower than {market} (your market)'**
  String lowerThanYourMarket(String amount, String market);

  /// No description provided for @comparisonEmpty.
  ///
  /// In en, this message translates to:
  /// **'No prices for these markets yet.'**
  String get comparisonEmpty;

  /// No description provided for @priceTrendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Price Trends'**
  String get priceTrendsTitle;

  /// No description provided for @createAlertAction.
  ///
  /// In en, this message translates to:
  /// **'Create alert'**
  String get createAlertAction;

  /// No description provided for @trendTitle.
  ///
  /// In en, this message translates to:
  /// **'{commodity} — {market} (₹/{unit})'**
  String trendTitle(String commodity, String market, String unit);

  /// No description provided for @statMin.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get statMin;

  /// No description provided for @statModal.
  ///
  /// In en, this message translates to:
  /// **'Modal'**
  String get statModal;

  /// No description provided for @statMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get statMax;

  /// No description provided for @relatedMarkets.
  ///
  /// In en, this message translates to:
  /// **'Related Markets'**
  String get relatedMarkets;

  /// No description provided for @trendsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No price history for this range.'**
  String get trendsEmpty;

  /// No description provided for @buyingOpportunityTitle.
  ///
  /// In en, this message translates to:
  /// **'Buying Opportunity'**
  String get buyingOpportunityTitle;

  /// No description provided for @editRequirement.
  ///
  /// In en, this message translates to:
  /// **'Edit requirement'**
  String get editRequirement;

  /// No description provided for @requirementLine.
  ///
  /// In en, this message translates to:
  /// **'Required quantity · {quantity} · Deliver to {place}'**
  String requirementLine(String quantity, String place);

  /// No description provided for @bestPriceBadge.
  ///
  /// In en, this message translates to:
  /// **'Best Price'**
  String get bestPriceBadge;

  /// No description provided for @potentialDifference.
  ///
  /// In en, this message translates to:
  /// **'Potential Difference'**
  String get potentialDifference;

  /// No description provided for @differenceCaption.
  ///
  /// In en, this message translates to:
  /// **'on {quantity} vs. buying in {market}'**
  String differenceCaption(String quantity, String market);

  /// No description provided for @howCalculated.
  ///
  /// In en, this message translates to:
  /// **'How we calculated this'**
  String get howCalculated;

  /// No description provided for @calculationLine.
  ///
  /// In en, this message translates to:
  /// **'({reference} − {best}) × {quantity} = {total}. Freight and handling are not included yet.'**
  String calculationLine(
    String reference,
    String best,
    String quantity,
    String total,
  );

  /// No description provided for @viewSuppliers.
  ///
  /// In en, this message translates to:
  /// **'View {market} Suppliers'**
  String viewSuppliers(String market);

  /// No description provided for @watchlistTitle.
  ///
  /// In en, this message translates to:
  /// **'My Watchlist'**
  String get watchlistTitle;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @alertBelow.
  ///
  /// In en, this message translates to:
  /// **'alert below {price}'**
  String alertBelow(String price);

  /// No description provided for @alertAbove.
  ///
  /// In en, this message translates to:
  /// **'alert above {price}'**
  String alertAbove(String price);

  /// No description provided for @alertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsTitle;

  /// No description provided for @alertSettings.
  ///
  /// In en, this message translates to:
  /// **'Alert settings'**
  String get alertSettings;

  /// No description provided for @filterPriceSignals.
  ///
  /// In en, this message translates to:
  /// **'Price Signals'**
  String get filterPriceSignals;

  /// No description provided for @filterOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Opportunities'**
  String get filterOpportunities;

  /// No description provided for @kindSignal.
  ///
  /// In en, this message translates to:
  /// **'Price Signal'**
  String get kindSignal;

  /// No description provided for @kindOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Opportunity'**
  String get kindOpportunity;

  /// No description provided for @kindSpike.
  ///
  /// In en, this message translates to:
  /// **'Price Spike'**
  String get kindSpike;

  /// No description provided for @sentOnWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Sent on WhatsApp'**
  String get sentOnWhatsApp;

  /// No description provided for @sentAsPush.
  ///
  /// In en, this message translates to:
  /// **'Push notification'**
  String get sentAsPush;

  /// No description provided for @viewOpportunity.
  ///
  /// In en, this message translates to:
  /// **'View Opportunity'**
  String get viewOpportunity;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @alertsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No alerts yet.'**
  String get alertsEmpty;

  /// No description provided for @createAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Alert'**
  String get createAlertTitle;

  /// No description provided for @productLabel.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get productLabel;

  /// No description provided for @marketLabel.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get marketLabel;

  /// No description provided for @notifyWhen.
  ///
  /// In en, this message translates to:
  /// **'Notify me when price'**
  String get notifyWhen;

  /// No description provided for @conditionBelow.
  ///
  /// In en, this message translates to:
  /// **'Drops below'**
  String get conditionBelow;

  /// No description provided for @conditionAbove.
  ///
  /// In en, this message translates to:
  /// **'Rises above'**
  String get conditionAbove;

  /// No description provided for @conditionPercent.
  ///
  /// In en, this message translates to:
  /// **'Changes by %'**
  String get conditionPercent;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @changeLabel.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeLabel;

  /// No description provided for @currentPriceIn.
  ///
  /// In en, this message translates to:
  /// **'Current price in {market}: {price}'**
  String currentPriceIn(String market, String price);

  /// No description provided for @sendVia.
  ///
  /// In en, this message translates to:
  /// **'Send alert via'**
  String get sendVia;

  /// No description provided for @pushNotification.
  ///
  /// In en, this message translates to:
  /// **'Push notification'**
  String get pushNotification;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @whatsappTarget.
  ///
  /// In en, this message translates to:
  /// **'{phone} · in {language}'**
  String whatsappTarget(String phone, String language);

  /// No description provided for @saveAlert.
  ///
  /// In en, this message translates to:
  /// **'Save Alert'**
  String get saveAlert;

  /// No description provided for @alertSaved.
  ///
  /// In en, this message translates to:
  /// **'Alert saved.'**
  String get alertSaved;

  /// No description provided for @costEstimatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Cost Estimator'**
  String get costEstimatorTitle;

  /// No description provided for @materialLabel.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get materialLabel;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// No description provided for @deliverToLabel.
  ///
  /// In en, this message translates to:
  /// **'Deliver to'**
  String get deliverToLabel;

  /// No description provided for @estimatedCost.
  ///
  /// In en, this message translates to:
  /// **'Estimated cost'**
  String get estimatedCost;

  /// No description provided for @estimateCaption.
  ///
  /// In en, this message translates to:
  /// **'{quantity} {unit} × {price} (lowest benchmark, {source})'**
  String estimateCaption(
    String quantity,
    String unit,
    String price,
    String source,
  );

  /// No description provided for @estimateSavings.
  ///
  /// In en, this message translates to:
  /// **'Saves {amount} vs. district average {average}. Freight, handling and GST not included.'**
  String estimateSavings(String amount, String average);

  /// No description provided for @columnSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get columnSource;

  /// No description provided for @columnRupeePer.
  ///
  /// In en, this message translates to:
  /// **'₹/{unit}'**
  String columnRupeePer(String unit);

  /// No description provided for @saveEstimate.
  ///
  /// In en, this message translates to:
  /// **'Save Estimate'**
  String get saveEstimate;

  /// No description provided for @estimateSaved.
  ///
  /// In en, this message translates to:
  /// **'Estimate saved.'**
  String get estimateSaved;

  /// No description provided for @estimatePrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter a quantity to see the estimated cost.'**
  String get estimatePrompt;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week · {range}'**
  String thisWeek(String range);

  /// No description provided for @potentialSavingsFound.
  ///
  /// In en, this message translates to:
  /// **'{amount} potential savings found'**
  String potentialSavingsFound(String amount);

  /// No description provided for @weekStats.
  ///
  /// In en, this message translates to:
  /// **'{items} watchlist items · {alerts} alerts · {opportunities} opportunities'**
  String weekStats(String items, String alerts, String opportunities);

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF ({language})'**
  String downloadPdf(String language);

  /// No description provided for @weeklySummaries.
  ///
  /// In en, this message translates to:
  /// **'Weekly summaries'**
  String get weeklySummaries;

  /// No description provided for @summaryTitle.
  ///
  /// In en, this message translates to:
  /// **'{range} summary'**
  String summaryTitle(String range);

  /// No description provided for @summaryMeta.
  ///
  /// In en, this message translates to:
  /// **'PDF · {language} · {pages} pages'**
  String summaryMeta(String language, String pages);

  /// No description provided for @exportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Exports'**
  String get exportsTitle;

  /// No description provided for @proBadge.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get proBadge;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @reportsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reports yet.'**
  String get reportsEmpty;

  /// No description provided for @moreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// No description provided for @molbhavPro.
  ///
  /// In en, this message translates to:
  /// **'MolBhav Pro'**
  String get molbhavPro;

  /// No description provided for @proSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced alerts, exports, 1-year history'**
  String get proSubtitle;

  /// No description provided for @pricePerMonth.
  ///
  /// In en, this message translates to:
  /// **'{price}/mo'**
  String pricePerMonth(String price);

  /// No description provided for @myCategories.
  ///
  /// In en, this message translates to:
  /// **'My categories'**
  String get myCategories;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushNotifications;

  /// No description provided for @whatsappAlerts.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp alerts'**
  String get whatsappAlerts;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get helpSupport;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @placeLine.
  ///
  /// In en, this message translates to:
  /// **'{district}, {state}'**
  String placeLine(String district, String state);

  /// No description provided for @choosePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your plan'**
  String get choosePlanTitle;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get currentPlan;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get perMonth;

  /// No description provided for @perYear.
  ///
  /// In en, this message translates to:
  /// **'/ year'**
  String get perYear;

  /// No description provided for @upgradeTo.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to {plan}'**
  String upgradeTo(String plan);

  /// No description provided for @cancelAnytime.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime. Prices include GST.'**
  String get cancelAnytime;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'gu',
    'hi',
    'kn',
    'mr',
    'ta',
    'te',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'mr':
      return AppLocalizationsMr();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
