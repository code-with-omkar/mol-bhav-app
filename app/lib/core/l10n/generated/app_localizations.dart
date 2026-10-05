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

  /// No description provided for @navAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get navAlerts;

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

  /// No description provided for @browseByMandi.
  ///
  /// In en, this message translates to:
  /// **'Browse by mandi'**
  String get browseByMandi;

  /// No description provided for @browseByCommodity.
  ///
  /// In en, this message translates to:
  /// **'Browse by commodity'**
  String get browseByCommodity;

  /// No description provided for @mandiLabel.
  ///
  /// In en, this message translates to:
  /// **'Mandi'**
  String get mandiLabel;

  /// No description provided for @mandiPricesHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a state, district and mandi to see its latest prices.'**
  String get mandiPricesHint;

  /// No description provided for @mandiPricesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recent prices at this mandi.'**
  String get mandiPricesEmpty;

  /// No description provided for @mandisEmpty.
  ///
  /// In en, this message translates to:
  /// **'No mandis in this district yet.'**
  String get mandisEmpty;

  /// No description provided for @priceDate.
  ///
  /// In en, this message translates to:
  /// **'Price date: {date}'**
  String priceDate(String date);

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

  /// No description provided for @yourNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourNameLabel;

  /// No description provided for @yourNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ramesh Patil'**
  String get yourNameHint;

  /// No description provided for @nameErrorLength.
  ///
  /// In en, this message translates to:
  /// **'Enter 2–60 characters.'**
  String get nameErrorLength;

  /// No description provided for @nameErrorCharacters.
  ///
  /// In en, this message translates to:
  /// **'Use letters, spaces and . \' - only.'**
  String get nameErrorCharacters;

  /// No description provided for @addYourName.
  ///
  /// In en, this message translates to:
  /// **'Add your name'**
  String get addYourName;

  /// No description provided for @addToWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Add to watchlist'**
  String get addToWatchlist;

  /// No description provided for @addToWatchlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to watchlist'**
  String get addToWatchlistTitle;

  /// No description provided for @removeFromWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Remove from watchlist'**
  String get removeFromWatchlist;

  /// No description provided for @addedToWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Added to watchlist.'**
  String get addedToWatchlist;

  /// No description provided for @alreadyInWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Already in watchlist.'**
  String get alreadyInWatchlist;

  /// No description provided for @removedFromWatchlist.
  ///
  /// In en, this message translates to:
  /// **'{name} removed from watchlist.'**
  String removedFromWatchlist(String name);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @searchWatchlistHint.
  ///
  /// In en, this message translates to:
  /// **'Search your watchlist'**
  String get searchWatchlistHint;

  /// No description provided for @searchProductsHint.
  ///
  /// In en, this message translates to:
  /// **'Search products'**
  String get searchProductsHint;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches your search.'**
  String get noMatches;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @allVarieties.
  ///
  /// In en, this message translates to:
  /// **'All varieties'**
  String get allVarieties;

  /// No description provided for @quickCostEstimate.
  ///
  /// In en, this message translates to:
  /// **'Cost Estimate'**
  String get quickCostEstimate;

  /// No description provided for @estimateSavedLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get estimateSavedLabel;

  /// No description provided for @unitLockedHelper.
  ///
  /// In en, this message translates to:
  /// **'Prices are quoted in this unit.'**
  String get unitLockedHelper;

  /// No description provided for @anyDistrict.
  ///
  /// In en, this message translates to:
  /// **'Any district'**
  String get anyDistrict;

  /// No description provided for @estimateNoPrices.
  ///
  /// In en, this message translates to:
  /// **'No recent prices for this material here. Try another district or material.'**
  String get estimateNoPrices;

  /// No description provided for @estimateSavingsVsAverage.
  ///
  /// In en, this message translates to:
  /// **'Saves {amount} vs. the average of compared locations ({average}). Includes applicable charges.'**
  String estimateSavingsVsAverage(String amount, String average);

  /// No description provided for @savedEstimates.
  ///
  /// In en, this message translates to:
  /// **'Saved estimates'**
  String get savedEstimates;

  /// No description provided for @savedEstimatesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved estimates yet.'**
  String get savedEstimatesEmpty;

  /// No description provided for @deleteEstimate.
  ///
  /// In en, this message translates to:
  /// **'Delete estimate'**
  String get deleteEstimate;

  /// No description provided for @generateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate a report'**
  String get generateReport;

  /// No description provided for @reportTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Report type'**
  String get reportTypeLabel;

  /// No description provided for @reportWeeklySummaryPdf.
  ///
  /// In en, this message translates to:
  /// **'Weekly summary (PDF)'**
  String get reportWeeklySummaryPdf;

  /// No description provided for @reportPriceHistoryCsv.
  ///
  /// In en, this message translates to:
  /// **'Price history (CSV)'**
  String get reportPriceHistoryCsv;

  /// No description provided for @reportWeeklySummary.
  ///
  /// In en, this message translates to:
  /// **'Weekly summary'**
  String get reportWeeklySummary;

  /// No description provided for @reportPriceHistory.
  ///
  /// In en, this message translates to:
  /// **'Price history'**
  String get reportPriceHistory;

  /// No description provided for @reportPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get reportPeriodLabel;

  /// No description provided for @lastDays.
  ///
  /// In en, this message translates to:
  /// **'Last {days} days'**
  String lastDays(int days);

  /// No description provided for @customRange.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customRange;

  /// No description provided for @reportLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Report language'**
  String get reportLanguageLabel;

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// No description provided for @reportGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating…'**
  String get reportGenerating;

  /// No description provided for @reportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get reportFailed;

  /// No description provided for @reportReady.
  ///
  /// In en, this message translates to:
  /// **'Your report is ready. Tap it to download.'**
  String get reportReady;

  /// No description provided for @reportNeedsPro.
  ///
  /// In en, this message translates to:
  /// **'Price history exports need MolBhav Pro.'**
  String get reportNeedsPro;

  /// No description provided for @yourReports.
  ///
  /// In en, this message translates to:
  /// **'Your reports'**
  String get yourReports;

  /// No description provided for @optionalAllMandis.
  ///
  /// In en, this message translates to:
  /// **'All mandis (optional)'**
  String get optionalAllMandis;

  /// No description provided for @allMandis.
  ///
  /// In en, this message translates to:
  /// **'All mandis'**
  String get allMandis;

  /// No description provided for @csvProNote.
  ///
  /// In en, this message translates to:
  /// **'Daily prices for one product, ready for Excel.'**
  String get csvProNote;

  /// No description provided for @fileSavedNoViewer.
  ///
  /// In en, this message translates to:
  /// **'Saved {name}, but no app here can open it.'**
  String fileSavedNoViewer(String name);

  /// No description provided for @alertRose.
  ///
  /// In en, this message translates to:
  /// **'{product} rose {percent}%'**
  String alertRose(String product, String percent);

  /// No description provided for @alertDropped.
  ///
  /// In en, this message translates to:
  /// **'{product} dropped {percent}%'**
  String alertDropped(String product, String percent);

  /// No description provided for @alertRoseIn.
  ///
  /// In en, this message translates to:
  /// **'{product} rose {percent}% in {market}'**
  String alertRoseIn(String product, String percent, String market);

  /// No description provided for @alertDroppedIn.
  ///
  /// In en, this message translates to:
  /// **'{product} dropped {percent}% in {market}'**
  String alertDroppedIn(String product, String percent, String market);

  /// No description provided for @alertPreviousPrice.
  ///
  /// In en, this message translates to:
  /// **'Previous: {price}'**
  String alertPreviousPrice(String price);

  /// No description provided for @alertCurrentPrice.
  ///
  /// In en, this message translates to:
  /// **'Current: {price}'**
  String alertCurrentPrice(String price);

  /// No description provided for @showAllStates.
  ///
  /// In en, this message translates to:
  /// **'Show mandis from all states'**
  String get showAllStates;

  /// No description provided for @reportRequestedAt.
  ///
  /// In en, this message translates to:
  /// **'Requested {dateTime}'**
  String reportRequestedAt(String dateTime);

  /// No description provided for @reportGeneratedAt.
  ///
  /// In en, this message translates to:
  /// **'Generated {dateTime}'**
  String reportGeneratedAt(String dateTime);

  /// No description provided for @reportNotDownloadedYet.
  ///
  /// In en, this message translates to:
  /// **'Not downloaded yet'**
  String get reportNotDownloadedYet;

  /// No description provided for @reportDownloadedAt.
  ///
  /// In en, this message translates to:
  /// **'Downloaded {dateTime}'**
  String reportDownloadedAt(String dateTime);

  /// No description provided for @reportReadyLabel.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get reportReadyLabel;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUs;

  /// No description provided for @contactWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp us'**
  String get contactWhatsApp;

  /// No description provided for @contactCall.
  ///
  /// In en, this message translates to:
  /// **'Call us'**
  String get contactCall;

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'Email us'**
  String get contactEmail;

  /// No description provided for @cannotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'No app on this device can open that.'**
  String get cannotOpenLink;

  /// No description provided for @supportWhatsAppPrefill.
  ///
  /// In en, this message translates to:
  /// **'Hello MolBhav, I need help with'**
  String get supportWhatsAppPrefill;

  /// No description provided for @supportEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'MolBhav support request'**
  String get supportEmailSubject;

  /// No description provided for @supportEmailIntro.
  ///
  /// In en, this message translates to:
  /// **'Please describe what you need help with:'**
  String get supportEmailIntro;

  /// No description provided for @appVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersionLabel;

  /// No description provided for @accountLabel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountLabel;

  /// No description provided for @faqTitle.
  ///
  /// In en, this message translates to:
  /// **'Common questions'**
  String get faqTitle;

  /// No description provided for @faqEmpty.
  ///
  /// In en, this message translates to:
  /// **'No questions are available right now.'**
  String get faqEmpty;

  /// No description provided for @raiseTicket.
  ///
  /// In en, this message translates to:
  /// **'Raise a ticket'**
  String get raiseTicket;

  /// No description provided for @myTickets.
  ///
  /// In en, this message translates to:
  /// **'My tickets'**
  String get myTickets;

  /// No description provided for @ticketsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have not raised a ticket yet.'**
  String get ticketsEmpty;

  /// No description provided for @ticketTitle.
  ///
  /// In en, this message translates to:
  /// **'Ticket'**
  String get ticketTitle;

  /// No description provided for @ticketRaised.
  ///
  /// In en, this message translates to:
  /// **'Ticket raised. We will reply here.'**
  String get ticketRaised;

  /// No description provided for @submitTicket.
  ///
  /// In en, this message translates to:
  /// **'Submit ticket'**
  String get submitTicket;

  /// No description provided for @ticketCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'What is it about?'**
  String get ticketCategoryLabel;

  /// No description provided for @ticketCategoryAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get ticketCategoryAccount;

  /// No description provided for @ticketCategoryPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get ticketCategoryPayment;

  /// No description provided for @ticketCategoryData.
  ///
  /// In en, this message translates to:
  /// **'Prices & data'**
  String get ticketCategoryData;

  /// No description provided for @ticketCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get ticketCategoryOther;

  /// No description provided for @ticketSubjectLabel.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get ticketSubjectLabel;

  /// No description provided for @ticketSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'Onion price for APMC Pune looks wrong'**
  String get ticketSubjectHint;

  /// No description provided for @ticketSubjectHelper.
  ///
  /// In en, this message translates to:
  /// **'At least {count} characters.'**
  String ticketSubjectHelper(int count);

  /// No description provided for @ticketMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get ticketMessageLabel;

  /// No description provided for @ticketMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us what happened, and what you expected instead.'**
  String get ticketMessageHint;

  /// No description provided for @ticketStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get ticketStatusOpen;

  /// No description provided for @ticketStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get ticketStatusInProgress;

  /// No description provided for @ticketStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get ticketStatusResolved;

  /// No description provided for @ticketStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get ticketStatusClosed;

  /// No description provided for @ticketUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated {dateTime}'**
  String ticketUpdatedAt(String dateTime);

  /// No description provided for @ticketAuthorYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get ticketAuthorYou;

  /// No description provided for @ticketAuthorSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get ticketAuthorSupport;

  /// No description provided for @ticketReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Write a reply'**
  String get ticketReplyHint;

  /// No description provided for @sendReply.
  ///
  /// In en, this message translates to:
  /// **'Send reply'**
  String get sendReply;

  /// No description provided for @ticketClosedNotice.
  ///
  /// In en, this message translates to:
  /// **'This ticket is closed. Raise a new one if you still need help.'**
  String get ticketClosedNotice;

  /// No description provided for @sharePrice.
  ///
  /// In en, this message translates to:
  /// **'Share price'**
  String get sharePrice;

  /// No description provided for @shareModalLabel.
  ///
  /// In en, this message translates to:
  /// **'Modal price'**
  String get shareModalLabel;

  /// No description provided for @shareModalLine.
  ///
  /// In en, this message translates to:
  /// **'Modal: {price}'**
  String shareModalLine(String price);

  /// No description provided for @sharePriceHeadline.
  ///
  /// In en, this message translates to:
  /// **'{product} at {market}'**
  String sharePriceHeadline(String product, String market);

  /// No description provided for @shareRange.
  ///
  /// In en, this message translates to:
  /// **'Range: {min} – {max}'**
  String shareRange(String min, String max);

  /// No description provided for @sourceLine.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String sourceLine(String source);

  /// No description provided for @shareImageSaved.
  ///
  /// In en, this message translates to:
  /// **'Price card saved to your downloads.'**
  String get shareImageSaved;

  /// No description provided for @fromLink.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get fromLink;

  /// No description provided for @inviteFriend.
  ///
  /// In en, this message translates to:
  /// **'Invite a friend'**
  String get inviteFriend;

  /// No description provided for @inviteFriendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share MolBhav with other buyers'**
  String get inviteFriendSubtitle;

  /// No description provided for @inviteMessage.
  ///
  /// In en, this message translates to:
  /// **'I use MolBhav to check daily mandi and material prices before I buy. Try it:'**
  String get inviteMessage;

  /// No description provided for @myRulesAction.
  ///
  /// In en, this message translates to:
  /// **'My Rules'**
  String get myRulesAction;

  /// No description provided for @alertRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'My Alert Rules'**
  String get alertRulesTitle;

  /// No description provided for @alertRulesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No alert rules yet. Tap “Create alert” to add one.'**
  String get alertRulesEmpty;

  /// No description provided for @alertRuleDeleted.
  ///
  /// In en, this message translates to:
  /// **'Alert rule deleted.'**
  String get alertRuleDeleted;

  /// No description provided for @alertRuleActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get alertRuleActiveLabel;

  /// No description provided for @alertRuleInactiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get alertRuleInactiveLabel;

  /// No description provided for @alertRuleConditionBelow.
  ///
  /// In en, this message translates to:
  /// **'Price below {price}'**
  String alertRuleConditionBelow(String price);

  /// No description provided for @alertRuleConditionAbove.
  ///
  /// In en, this message translates to:
  /// **'Price above {price}'**
  String alertRuleConditionAbove(String price);

  /// No description provided for @alertRuleConditionDrop.
  ///
  /// In en, this message translates to:
  /// **'Drops by {percent}%'**
  String alertRuleConditionDrop(String percent);

  /// No description provided for @alertRuleConditionSpike.
  ///
  /// In en, this message translates to:
  /// **'Spikes by {percent}%'**
  String alertRuleConditionSpike(String percent);

  /// No description provided for @alertRulesEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Alert Rule'**
  String get alertRulesEditTitle;

  /// No description provided for @alertRulesThresholdPercentLabel.
  ///
  /// In en, this message translates to:
  /// **'Threshold (%)'**
  String get alertRulesThresholdPercentLabel;

  /// No description provided for @alertRulesThresholdPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Threshold (₹/{unit})'**
  String alertRulesThresholdPriceLabel(String unit);

  /// No description provided for @alertRulesActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get alertRulesActiveLabel;

  /// No description provided for @alertRulesCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get alertRulesCancel;

  /// No description provided for @alertRulesSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get alertRulesSave;

  /// No description provided for @changeNumberAction.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get changeNumberAction;

  /// No description provided for @resendOtpIn.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP in {seconds}s'**
  String resendOtpIn(int seconds);

  /// No description provided for @resendOtpAction.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtpAction;

  /// No description provided for @otpAutoFillHint.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP sent to {phone}'**
  String otpAutoFillHint(String phone);

  /// No description provided for @notificationSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettingsTitle;

  /// No description provided for @pushNotificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushNotificationsLabel;

  /// No description provided for @alertPushLabel.
  ///
  /// In en, this message translates to:
  /// **'Price alert push'**
  String get alertPushLabel;

  /// No description provided for @priceUpdatePushLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily price update push'**
  String get priceUpdatePushLabel;

  /// No description provided for @whatsappNotificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp notifications'**
  String get whatsappNotificationsLabel;

  /// No description provided for @alertWhatsappLabel.
  ///
  /// In en, this message translates to:
  /// **'Price alert on WhatsApp'**
  String get alertWhatsappLabel;

  /// No description provided for @notificationSettingsAction.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notificationSettingsAction;

  /// No description provided for @monthlyBilling.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlyBilling;

  /// No description provided for @yearlyBillingPlain.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearlyBillingPlain;

  /// No description provided for @yearlyBilling.
  ///
  /// In en, this message translates to:
  /// **'Yearly (Save {percent}%)'**
  String yearlyBilling(int percent);

  /// No description provided for @upgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToPro;

  /// No description provided for @renewPro.
  ///
  /// In en, this message translates to:
  /// **'Renew Pro'**
  String get renewPro;

  /// No description provided for @mySubscription.
  ///
  /// In en, this message translates to:
  /// **'My Subscription'**
  String get mySubscription;

  /// No description provided for @subscriptionActive.
  ///
  /// In en, this message translates to:
  /// **'Active — renews {date}'**
  String subscriptionActive(String date);

  /// No description provided for @subscriptionExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get subscriptionExpired;

  /// No description provided for @subscriptionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get subscriptionCancelled;

  /// No description provided for @subscriptionPending.
  ///
  /// In en, this message translates to:
  /// **'Payment pending'**
  String get subscriptionPending;

  /// No description provided for @subscriptionFree.
  ///
  /// In en, this message translates to:
  /// **'Free Plan'**
  String get subscriptionFree;

  /// No description provided for @cancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel Subscription'**
  String get cancelSubscription;

  /// No description provided for @cancelSubscriptionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel your Pro subscription? Pro features stop right away and the rest of the period is not refunded.'**
  String get cancelSubscriptionConfirm;

  /// No description provided for @keepSubscription.
  ///
  /// In en, this message translates to:
  /// **'Keep Pro'**
  String get keepSubscription;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutTitle;

  /// No description provided for @summaryPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get summaryPlan;

  /// No description provided for @summaryDiscount.
  ///
  /// In en, this message translates to:
  /// **'Coupon discount'**
  String get summaryDiscount;

  /// No description provided for @summaryTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get summaryTotal;

  /// No description provided for @couponCode.
  ///
  /// In en, this message translates to:
  /// **'Coupon Code'**
  String get couponCode;

  /// No description provided for @couponApplied.
  ///
  /// In en, this message translates to:
  /// **'Coupon applied! You save {amount}'**
  String couponApplied(String amount);

  /// No description provided for @couponInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired coupon'**
  String get couponInvalid;

  /// No description provided for @proceedToPay.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String proceedToPay(String amount);

  /// No description provided for @confirmingPayment.
  ///
  /// In en, this message translates to:
  /// **'Confirming payment…'**
  String get confirmingPayment;

  /// No description provided for @paymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful!'**
  String get paymentSuccess;

  /// No description provided for @paymentSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'You are now a Pro subscriber. Enjoy all premium features.'**
  String get paymentSuccessMessage;

  /// No description provided for @exploreProFeatures.
  ///
  /// In en, this message translates to:
  /// **'Explore Pro Features'**
  String get exploreProFeatures;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment Failed'**
  String get paymentFailed;

  /// No description provided for @paymentsMobileOnly.
  ///
  /// In en, this message translates to:
  /// **'Payments are available in the mobile app'**
  String get paymentsMobileOnly;

  /// No description provided for @paymentActivationPending.
  ///
  /// In en, this message translates to:
  /// **'Payment received — activation pending. Pull to refresh in a minute.'**
  String get paymentActivationPending;

  /// No description provided for @externalWalletUnsupported.
  ///
  /// In en, this message translates to:
  /// **'External wallets are not supported. Choose another payment method.'**
  String get externalWalletUnsupported;

  /// No description provided for @upgradeToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro to unlock this feature'**
  String get upgradeToUnlock;

  /// No description provided for @seePlans.
  ///
  /// In en, this message translates to:
  /// **'See Plans'**
  String get seePlans;

  /// No description provided for @proFeatureReports.
  ///
  /// In en, this message translates to:
  /// **'Price history export (CSV)'**
  String get proFeatureReports;

  /// No description provided for @proFeatureAlerts.
  ///
  /// In en, this message translates to:
  /// **'Price alert rules'**
  String get proFeatureAlerts;

  /// No description provided for @proFeatureProcurement.
  ///
  /// In en, this message translates to:
  /// **'Procurement cost estimator'**
  String get proFeatureProcurement;

  /// No description provided for @proFeatureComparison.
  ///
  /// In en, this message translates to:
  /// **'Mandi price comparison'**
  String get proFeatureComparison;

  /// No description provided for @freeFeatureBasicPrices.
  ///
  /// In en, this message translates to:
  /// **'Basic daily prices'**
  String get freeFeatureBasicPrices;

  /// No description provided for @freeFeatureWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Personal watchlist'**
  String get freeFeatureWatchlist;

  /// No description provided for @proFeatureEverythingInFree.
  ///
  /// In en, this message translates to:
  /// **'Everything in Free'**
  String get proFeatureEverythingInFree;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number and password.'**
  String get passwordLoginSubtitle;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a password to log in with your mobile number.'**
  String get registerSubtitle;

  /// No description provided for @loginAction.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginAction;

  /// No description provided for @createAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountAction;

  /// No description provided for @switchToRegister.
  ///
  /// In en, this message translates to:
  /// **'New to MolBhav? Create an account'**
  String get switchToRegister;

  /// No description provided for @switchToLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get switchToLogin;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get passwordRequired;

  /// No description provided for @passwordTooWeak.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters with a letter and a number.'**
  String get passwordTooWeak;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect mobile number or password.'**
  String get invalidCredentials;

  /// No description provided for @accountExists.
  ///
  /// In en, this message translates to:
  /// **'This number already has an account. Log in instead.'**
  String get accountExists;

  /// No description provided for @useOtpInstead.
  ///
  /// In en, this message translates to:
  /// **'Log in with OTP instead'**
  String get useOtpInstead;

  /// No description provided for @usePasswordInstead.
  ///
  /// In en, this message translates to:
  /// **'Log in with password instead'**
  String get usePasswordInstead;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @unlockWatchlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Your free watchlist is full'**
  String get unlockWatchlistTitle;

  /// No description provided for @unlockAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used your free alerts'**
  String get unlockAlertsTitle;

  /// No description provided for @unlockReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock this report'**
  String get unlockReportTitle;

  /// No description provided for @unlockWatchlistBody.
  ///
  /// In en, this message translates to:
  /// **'Watch a short ad to add {slots} more items, or go Pro for an unlimited watchlist.'**
  String unlockWatchlistBody(int slots);

  /// No description provided for @unlockAlertsBody.
  ///
  /// In en, this message translates to:
  /// **'Watch a short ad to add {slots} more alerts, or go Pro for unlimited alerts.'**
  String unlockAlertsBody(int slots);

  /// No description provided for @unlockReportBody.
  ///
  /// In en, this message translates to:
  /// **'Watch short ads to get this report free, or go Pro for unlimited reports.'**
  String get unlockReportBody;

  /// No description provided for @unlockLimitUsed.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the free limit for now. Go Pro for unlimited access.'**
  String get unlockLimitUsed;

  /// No description provided for @unlockProOnly.
  ///
  /// In en, this message translates to:
  /// **'Ads aren\'t available here. Go Pro for unlimited access.'**
  String get unlockProOnly;

  /// No description provided for @watchAdsButton.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Watch 1 ad} other{Watch {count} ads}}'**
  String watchAdsButton(num count);

  /// No description provided for @goProNoAds.
  ///
  /// In en, this message translates to:
  /// **'Go Pro – no ads'**
  String get goProNoAds;

  /// No description provided for @unlockAdProgress.
  ///
  /// In en, this message translates to:
  /// **'Ad {current} of {total}'**
  String unlockAdProgress(int current, int total);

  /// No description provided for @unlockVerifying.
  ///
  /// In en, this message translates to:
  /// **'Confirming…'**
  String get unlockVerifying;

  /// No description provided for @unlockGranted.
  ///
  /// In en, this message translates to:
  /// **'Unlocked! Trying again…'**
  String get unlockGranted;

  /// No description provided for @unlockFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t confirm the ad. Please try again.'**
  String get unlockFailed;

  /// No description provided for @reportFreeUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Free plan: unlock price history by watching short ads, a few times a day. Pro: unlimited.'**
  String get reportFreeUnlockHint;

  /// No description provided for @adsPersonalisedTitle.
  ///
  /// In en, this message translates to:
  /// **'Personalised ads'**
  String get adsPersonalisedTitle;

  /// No description provided for @adsPersonalisedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show ads based on how you use MolBhav. Off: ads still appear but aren\'t based on you.'**
  String get adsPersonalisedSubtitle;

  /// Label on a paid advertiser's card.
  ///
  /// In en, this message translates to:
  /// **'Sponsored'**
  String get promotionSponsored;

  /// No description provided for @adminSchedulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Data pull schedules'**
  String get adminSchedulesTitle;

  /// No description provided for @adminSchedulesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When government prices are pulled automatically'**
  String get adminSchedulesSubtitle;

  /// No description provided for @adminSchedulesHint.
  ///
  /// In en, this message translates to:
  /// **'Times are India Standard Time. A source without a schedule is pulled only when you tap Run now.'**
  String get adminSchedulesHint;

  /// No description provided for @adminNoSources.
  ///
  /// In en, this message translates to:
  /// **'No price sources yet.'**
  String get adminNoSources;

  /// No description provided for @scheduleDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily at {time} IST'**
  String scheduleDaily(String time);

  /// No description provided for @scheduleWeekly.
  ///
  /// In en, this message translates to:
  /// **'Every {day} at {time} IST'**
  String scheduleWeekly(String day, String time);

  /// No description provided for @scheduleEveryNHours.
  ///
  /// In en, this message translates to:
  /// **'Every {hours} h from {time} IST'**
  String scheduleEveryNHours(String hours, String time);

  /// No description provided for @scheduleNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not scheduled'**
  String get scheduleNotConfigured;

  /// No description provided for @scheduleStatusOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get scheduleStatusOn;

  /// No description provided for @scheduleStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get scheduleStatusPaused;

  /// No description provided for @scheduleStatusNone.
  ///
  /// In en, this message translates to:
  /// **'Not scheduled'**
  String get scheduleStatusNone;

  /// No description provided for @sourceInactive.
  ///
  /// In en, this message translates to:
  /// **'Source inactive'**
  String get sourceInactive;

  /// No description provided for @scheduleNextRun.
  ///
  /// In en, this message translates to:
  /// **'Next run: {when}'**
  String scheduleNextRun(String when);

  /// No description provided for @scheduleLastRun.
  ///
  /// In en, this message translates to:
  /// **'Last run: {when} · {status}'**
  String scheduleLastRun(String when, String status);

  /// No description provided for @jobStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get jobStatusRunning;

  /// No description provided for @jobStatusSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Succeeded'**
  String get jobStatusSucceeded;

  /// No description provided for @jobStatusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partly saved'**
  String get jobStatusPartial;

  /// No description provided for @jobStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get jobStatusFailed;

  /// No description provided for @jobCounts.
  ///
  /// In en, this message translates to:
  /// **'{saved} saved, {failed} failed'**
  String jobCounts(String saved, String failed);

  /// No description provided for @runNowAction.
  ///
  /// In en, this message translates to:
  /// **'Run now'**
  String get runNowAction;

  /// No description provided for @editScheduleAction.
  ///
  /// In en, this message translates to:
  /// **'Edit schedule'**
  String get editScheduleAction;

  /// No description provided for @saveScheduleAction.
  ///
  /// In en, this message translates to:
  /// **'Save schedule'**
  String get saveScheduleAction;

  /// No description provided for @scheduleFrequencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get scheduleFrequencyLabel;

  /// No description provided for @frequencyDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get frequencyDaily;

  /// No description provided for @frequencyWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get frequencyWeekly;

  /// No description provided for @frequencyEveryNHours.
  ///
  /// In en, this message translates to:
  /// **'Every few hours'**
  String get frequencyEveryNHours;

  /// No description provided for @scheduleTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time (IST)'**
  String get scheduleTimeLabel;

  /// No description provided for @scheduleDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get scheduleDayLabel;

  /// No description provided for @scheduleIntervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat every'**
  String get scheduleIntervalLabel;

  /// No description provided for @intervalHoursOption.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours'**
  String intervalHoursOption(String hours);

  /// No description provided for @scheduleEnabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Run automatically'**
  String get scheduleEnabledLabel;

  /// No description provided for @scheduleSaved.
  ///
  /// In en, this message translates to:
  /// **'Schedule saved.'**
  String get scheduleSaved;

  /// No description provided for @runCompleted.
  ///
  /// In en, this message translates to:
  /// **'Run finished. See the last run on the card.'**
  String get runCompleted;

  /// No description provided for @backfillAction.
  ///
  /// In en, this message translates to:
  /// **'Pull past days'**
  String get backfillAction;

  /// No description provided for @backfillPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Market days to pull'**
  String get backfillPickerTitle;

  /// No description provided for @backfillTooLong.
  ///
  /// In en, this message translates to:
  /// **'Pick at most {max} days at a time.'**
  String backfillTooLong(String max);

  /// No description provided for @backfillQueued.
  ///
  /// In en, this message translates to:
  /// **'{days} day(s) queued. Pull down to refresh as they finish.'**
  String backfillQueued(String days);

  /// No description provided for @jobMarketDay.
  ///
  /// In en, this message translates to:
  /// **'Market day: {date}'**
  String jobMarketDay(String date);

  /// No description provided for @jobUnchanged.
  ///
  /// In en, this message translates to:
  /// **'{count} unchanged'**
  String jobUnchanged(String count);

  /// No description provided for @uploadCsvAction.
  ///
  /// In en, this message translates to:
  /// **'Upload CSV'**
  String get uploadCsvAction;

  /// No description provided for @uploadCompleted.
  ///
  /// In en, this message translates to:
  /// **'CSV imported. See the last run on the card.'**
  String get uploadCompleted;

  /// No description provided for @uploadTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The file is larger than 10 MB. Split it by date or state.'**
  String get uploadTooLarge;

  /// No description provided for @jobFromUpload.
  ///
  /// In en, this message translates to:
  /// **'from CSV upload'**
  String get jobFromUpload;

  /// No description provided for @adminAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get adminAllCategories;

  /// No description provided for @runAllAction.
  ///
  /// In en, this message translates to:
  /// **'Run all'**
  String get runAllAction;

  /// No description provided for @categoryRunQueued.
  ///
  /// In en, this message translates to:
  /// **'{count} source(s) queued. Pull down to refresh as they finish.'**
  String categoryRunQueued(String count);

  /// No description provided for @addSourceAction.
  ///
  /// In en, this message translates to:
  /// **'Add source'**
  String get addSourceAction;

  /// No description provided for @editSourceAction.
  ///
  /// In en, this message translates to:
  /// **'Edit source'**
  String get editSourceAction;

  /// No description provided for @sourceCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get sourceCodeLabel;

  /// No description provided for @sourceCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. cpwd-dsr. Cannot be changed later.'**
  String get sourceCodeHint;

  /// No description provided for @sourceCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use lowercase letters, digits and hyphens, starting with a letter.'**
  String get sourceCodeInvalid;

  /// No description provided for @sourceNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sourceNameLabel;

  /// No description provided for @sourceNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get sourceNameRequired;

  /// No description provided for @sourceCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get sourceCategoryLabel;

  /// No description provided for @sourceActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get sourceActiveLabel;

  /// No description provided for @saveSourceAction.
  ///
  /// In en, this message translates to:
  /// **'Save source'**
  String get saveSourceAction;

  /// No description provided for @sourceCreated.
  ///
  /// In en, this message translates to:
  /// **'Source added.'**
  String get sourceCreated;

  /// No description provided for @sourceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Source updated.'**
  String get sourceUpdated;

  /// No description provided for @categoryNoSources.
  ///
  /// In en, this message translates to:
  /// **'No sources in this category yet.'**
  String get categoryNoSources;

  /// No description provided for @csvTemplateAction.
  ///
  /// In en, this message translates to:
  /// **'CSV format'**
  String get csvTemplateAction;

  /// No description provided for @csvTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'CSV template'**
  String get csvTemplateTitle;

  /// No description provided for @csvTemplateBody.
  ///
  /// In en, this message translates to:
  /// **'Every source accepts a CSV whose first line is this header. Use MolBhav product codes and mandi or supplier codes; location_kind is mandi or supplier; dates as yyyy-MM-dd. Rows for products outside the source\'s category are rejected. Agmarknet also accepts the data.gov.in and portal exports.'**
  String get csvTemplateBody;

  /// No description provided for @csvTemplateCopied.
  ///
  /// In en, this message translates to:
  /// **'Header copied.'**
  String get csvTemplateCopied;

  /// No description provided for @weatherTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weatherTitle;

  /// No description provided for @weatherToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get weatherToday;

  /// No description provided for @weatherTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get weatherTomorrow;

  /// No description provided for @weatherSevenDay.
  ///
  /// In en, this message translates to:
  /// **'7-day forecast'**
  String get weatherSevenDay;

  /// No description provided for @weatherSelectDay.
  ///
  /// In en, this message translates to:
  /// **'Select day'**
  String get weatherSelectDay;

  /// No description provided for @weatherStation.
  ///
  /// In en, this message translates to:
  /// **'IMD · {station}'**
  String weatherStation(String station);

  /// No description provided for @weatherRainChance.
  ///
  /// In en, this message translates to:
  /// **'{percent}% rain'**
  String weatherRainChance(String percent);

  /// No description provided for @weatherHumidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get weatherHumidity;

  /// No description provided for @weatherWind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get weatherWind;

  /// No description provided for @weatherWindValue.
  ///
  /// In en, this message translates to:
  /// **'{speed} km/h'**
  String weatherWindValue(String speed);

  /// No description provided for @weatherTempRange.
  ///
  /// In en, this message translates to:
  /// **'{min}° / {max}°'**
  String weatherTempRange(String min, String max);

  /// No description provided for @weatherTempDegrees.
  ///
  /// In en, this message translates to:
  /// **'{temp}°'**
  String weatherTempDegrees(String temp);

  /// No description provided for @weatherUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String weatherUpdated(String time);

  /// No description provided for @weatherClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get weatherClear;

  /// No description provided for @weatherPartlyCloudy.
  ///
  /// In en, this message translates to:
  /// **'Partly cloudy'**
  String get weatherPartlyCloudy;

  /// No description provided for @weatherCloudy.
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get weatherCloudy;

  /// No description provided for @weatherRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherRain;

  /// No description provided for @weatherThunderstorm.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get weatherThunderstorm;

  /// No description provided for @weatherPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Show weather for your area?'**
  String get weatherPermissionTitle;

  /// No description provided for @weatherPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'MolBhav uses your approximate location once to find the nearest IMD weather station. It stays on this device.'**
  String get weatherPermissionBody;

  /// No description provided for @weatherAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get weatherAllow;

  /// No description provided for @weatherNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get weatherNotNow;

  /// No description provided for @weatherEnableLocation.
  ///
  /// In en, this message translates to:
  /// **'Enable location'**
  String get weatherEnableLocation;

  /// No description provided for @weatherOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get weatherOpenSettings;

  /// No description provided for @weatherNoForecast.
  ///
  /// In en, this message translates to:
  /// **'No forecast'**
  String get weatherNoForecast;

  /// No description provided for @weatherNoForecastBody.
  ///
  /// In en, this message translates to:
  /// **'Allow location to see the weather for your area.'**
  String get weatherNoForecastBody;

  /// No description provided for @weatherServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Location is turned off. Turn it on to see the weather for your area.'**
  String get weatherServiceOff;

  /// No description provided for @weatherDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission is blocked. Allow it in settings to see the weather.'**
  String get weatherDeniedForever;

  /// No description provided for @weatherOutOfCoverage.
  ///
  /// In en, this message translates to:
  /// **'No IMD weather station near you.'**
  String get weatherOutOfCoverage;

  /// No description provided for @weatherUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not find your location.'**
  String get weatherUnavailable;

  /// No description provided for @alertRuleConditionChange.
  ///
  /// In en, this message translates to:
  /// **'Changes by {percent}% (up or down)'**
  String alertRuleConditionChange(String percent);

  /// No description provided for @savePasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get savePasswordLabel;

  /// No description provided for @savePasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Stored securely on this phone. Turn off on shared phones.'**
  String get savePasswordHint;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @googlePhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'One more step'**
  String get googlePhoneTitle;

  /// No description provided for @googlePhoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number. We use it for WhatsApp price alerts and support.'**
  String get googlePhoneSubtitle;

  /// No description provided for @googlePhoneContinue.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get googlePhoneContinue;

  /// No description provided for @googleAccountExists.
  ///
  /// In en, this message translates to:
  /// **'This mobile number already has an account. Log in with your password, then link Google from More.'**
  String get googleAccountExists;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in did not work. Please try again.'**
  String get googleSignInFailed;

  /// No description provided for @googleSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in'**
  String get googleSignInTitle;

  /// No description provided for @googleLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked'**
  String get googleLinked;

  /// No description provided for @googleLinkedAs.
  ///
  /// In en, this message translates to:
  /// **'Linked: {email}'**
  String googleLinkedAs(String email);

  /// No description provided for @googleUnlinkAction.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get googleUnlinkAction;

  /// No description provided for @googleLinkAction.
  ///
  /// In en, this message translates to:
  /// **'Link Google account'**
  String get googleLinkAction;

  /// No description provided for @googleLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google next time instead of your password.'**
  String get googleLinkHint;

  /// No description provided for @googleLinkedElsewhere.
  ///
  /// In en, this message translates to:
  /// **'This Google account is already linked to another MolBhav account.'**
  String get googleLinkedElsewhere;

  /// No description provided for @googleLastSignInMethod.
  ///
  /// In en, this message translates to:
  /// **'Set a password before unlinking Google — it is your only way to sign in.'**
  String get googleLastSignInMethod;
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
