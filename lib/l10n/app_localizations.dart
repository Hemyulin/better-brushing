import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @chooseYourCharacter.
  ///
  /// In en, this message translates to:
  /// **'Choose your character'**
  String get chooseYourCharacter;

  /// No description provided for @characterSelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a brushing buddy and begin your calm two-minute clean.'**
  String get characterSelectionSubtitle;

  /// No description provided for @foxName.
  ///
  /// In en, this message translates to:
  /// **'Fox'**
  String get foxName;

  /// No description provided for @gatorName.
  ///
  /// In en, this message translates to:
  /// **'Gator'**
  String get gatorName;

  /// No description provided for @foxDescription.
  ///
  /// In en, this message translates to:
  /// **'Warm, cheerful, and ready to swish away snack crumbs.'**
  String get foxDescription;

  /// No description provided for @gatorDescription.
  ///
  /// In en, this message translates to:
  /// **'Cool, steady, and happy to help with every side.'**
  String get gatorDescription;

  /// No description provided for @letsCleanThisSide.
  ///
  /// In en, this message translates to:
  /// **'Let\'s clean this side!'**
  String get letsCleanThisSide;

  /// No description provided for @greatJob.
  ///
  /// In en, this message translates to:
  /// **'Great job!'**
  String get greatJob;

  /// No description provided for @keepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going!'**
  String get keepGoing;

  /// No description provided for @almostDone.
  ///
  /// In en, this message translates to:
  /// **'Almost done!'**
  String get almostDone;

  /// No description provided for @nowItsYourParentsTurn.
  ///
  /// In en, this message translates to:
  /// **'Now it\'s your parent\'s turn!'**
  String get nowItsYourParentsTurn;

  /// No description provided for @plusThirtySeconds.
  ///
  /// In en, this message translates to:
  /// **'+30 seconds'**
  String get plusThirtySeconds;

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Finished!'**
  String get finished;

  /// No description provided for @parentsTurnNow.
  ///
  /// In en, this message translates to:
  /// **'Parent check time'**
  String get parentsTurnNow;

  /// No description provided for @keepBrushingTogether.
  ///
  /// In en, this message translates to:
  /// **'Keep brushing together for a little longer.'**
  String get keepBrushingTogether;

  /// No description provided for @zoneProgressHint.
  ///
  /// In en, this message translates to:
  /// **'Keep brushing this side and it will sparkle clean.'**
  String get zoneProgressHint;

  /// No description provided for @sessionComplete.
  ///
  /// In en, this message translates to:
  /// **'All clean for now.'**
  String get sessionComplete;

  /// No description provided for @timeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time left'**
  String get timeRemaining;

  /// No description provided for @currentZone.
  ///
  /// In en, this message translates to:
  /// **'Current zone'**
  String get currentZone;

  /// No description provided for @parentsTurn.
  ///
  /// In en, this message translates to:
  /// **'Parent turn'**
  String get parentsTurn;

  /// No description provided for @backToCharacters.
  ///
  /// In en, this message translates to:
  /// **'Back to characters'**
  String get backToCharacters;

  /// No description provided for @cameraPreviewFallback.
  ///
  /// In en, this message translates to:
  /// **'Camera preview is not available right now, but the brushing game can still run.'**
  String get cameraPreviewFallback;

  /// No description provided for @banubaTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Add a Banuba trial token via --dart-define=BANUBA_CLIENT_TOKEN=... to enable AR filters.'**
  String get banubaTokenHint;

  /// No description provided for @banubaArUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Banuba AR could not start yet.'**
  String get banubaArUnavailable;

  /// No description provided for @banubaPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera access is required for AR preview.'**
  String get banubaPermissionRequired;

  /// No description provided for @zoneTopLeft.
  ///
  /// In en, this message translates to:
  /// **'Top left'**
  String get zoneTopLeft;

  /// No description provided for @zoneTopRight.
  ///
  /// In en, this message translates to:
  /// **'Top right'**
  String get zoneTopRight;

  /// No description provided for @zoneBottomLeft.
  ///
  /// In en, this message translates to:
  /// **'Bottom left'**
  String get zoneBottomLeft;

  /// No description provided for @zoneBottomRight.
  ///
  /// In en, this message translates to:
  /// **'Bottom right'**
  String get zoneBottomRight;

  /// No description provided for @cleanZoneInstruction.
  ///
  /// In en, this message translates to:
  /// **'Clean the {zone} side.'**
  String cleanZoneInstruction(String zone);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
