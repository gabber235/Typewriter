import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

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
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'TypeWriter'**
  String get appTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your journey starts here'**
  String get homeTitle;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Run the following command on your server to start editing'**
  String get homeSubtitle;

  /// No description provided for @connectToTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to'**
  String get connectToTitle;

  /// No description provided for @connectToHint.
  ///
  /// In en, this message translates to:
  /// **'Fill in the url to connect to'**
  String get connectToHint;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred, please report on the Typewriter Discord'**
  String get unexpectedError;

  /// No description provided for @noSkinDataError.
  ///
  /// In en, this message translates to:
  /// **'Could not find the skin data in the response'**
  String get noSkinDataError;

  /// No description provided for @invalidTextureDataError.
  ///
  /// In en, this message translates to:
  /// **'Invalid texture data in response'**
  String get invalidTextureDataError;

  /// No description provided for @textureAndSignatureMustBeStrings.
  ///
  /// In en, this message translates to:
  /// **'Invalid texture or signature in response'**
  String get textureAndSignatureMustBeStrings;

  /// No description provided for @noEntryChecked.
  ///
  /// In en, this message translates to:
  /// **'Currently not inspecting an entry'**
  String get noEntryChecked;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addNew.
  ///
  /// In en, this message translates to:
  /// **'Add new {item}'**
  String addNew(Object item);

  /// No description provided for @trueValue.
  ///
  /// In en, this message translates to:
  /// **'True'**
  String get trueValue;

  /// No description provided for @falseValue.
  ///
  /// In en, this message translates to:
  /// **'False'**
  String get falseValue;

  /// No description provided for @hexCode.
  ///
  /// In en, this message translates to:
  /// **'Hex Code'**
  String get hexCode;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @stagingProduction.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get stagingProduction;

  /// No description provided for @stagingStaging.
  ///
  /// In en, this message translates to:
  /// **'Staging'**
  String get stagingStaging;

  /// No description provided for @stagingPublishing.
  ///
  /// In en, this message translates to:
  /// **'Publishing'**
  String get stagingPublishing;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteThis.
  ///
  /// In en, this message translates to:
  /// **'Remove {item}?'**
  String deleteThis(Object item);

  /// No description provided for @deleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete entry?'**
  String get deleteEntry;

  /// No description provided for @deleteEntryConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {entry}?'**
  String deleteEntryConfirmation(Object entry);

  /// No description provided for @replaceEntry.
  ///
  /// In en, this message translates to:
  /// **'Replace Entry'**
  String get replaceEntry;

  /// No description provided for @replaceEntryConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Replacing entries is not reversible.\nIt may result in data loss or data corruption.\nAre you sure you want to replace {entry}?'**
  String replaceEntryConfirmation(Object entry);

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @duplicateThis.
  ///
  /// In en, this message translates to:
  /// **'Duplicate {item}'**
  String duplicateThis(Object item);

  /// No description provided for @fetchSkin.
  ///
  /// In en, this message translates to:
  /// **'Fetch Skin'**
  String get fetchSkin;

  /// No description provided for @fetch.
  ///
  /// In en, this message translates to:
  /// **'Fetch'**
  String get fetch;

  /// No description provided for @fetchSkinHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the {bodyKey} to fetch the skin'**
  String fetchSkinHint(Object bodyKey);

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @thisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get thisActionCannotBeUndone;

  /// No description provided for @connectLocalhost.
  ///
  /// In en, this message translates to:
  /// **'Connect Localhost'**
  String get connectLocalhost;

  /// No description provided for @connectCustom.
  ///
  /// In en, this message translates to:
  /// **'Connect Custom'**
  String get connectCustom;

  /// No description provided for @waitingForConnection.
  ///
  /// In en, this message translates to:
  /// **'Waiting for connection'**
  String get waitingForConnection;

  /// No description provided for @errorConnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Communication error'**
  String get errorConnectTitle;

  /// No description provided for @errorConnectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'There was an error while communicating to the server.\nPlease check your connection and try again.'**
  String get errorConnectSubtitle;

  /// No description provided for @placeholderInfo.
  ///
  /// In en, this message translates to:
  /// **'Placeholders like %player_name% are supported. Click for more info.'**
  String get placeholderInfo;

  /// No description provided for @regexInfo.
  ///
  /// In en, this message translates to:
  /// **'Regular expressions are supported. Click for more info.'**
  String get regexInfo;

  /// No description provided for @coloredInfo.
  ///
  /// In en, this message translates to:
  /// **'Adventure Mini Format is supported. Click for more info.'**
  String get coloredInfo;

  /// No description provided for @pageSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get pageSearch;

  /// No description provided for @fields.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get fields;

  /// No description provided for @entry.
  ///
  /// In en, this message translates to:
  /// **'Entry'**
  String get entry;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get nameHint;

  /// No description provided for @algebraicEditorInvalidData.
  ///
  /// In en, this message translates to:
  /// **'This field contains invalid data. '**
  String get algebraicEditorInvalidData;

  /// No description provided for @algebraicEditorCaseNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not find a case for {name}. '**
  String algebraicEditorCaseNotFound(Object name);

  /// No description provided for @selectCase.
  ///
  /// In en, this message translates to:
  /// **'Select Case'**
  String get selectCase;

  /// No description provided for @valueReset.
  ///
  /// In en, this message translates to:
  /// **'Click to reset it to the default value.'**
  String get valueReset;

  /// No description provided for @setCaseType.
  ///
  /// In en, this message translates to:
  /// **'Set {name} as the type of the field'**
  String setCaseType(Object name);

  /// No description provided for @newEntries.
  ///
  /// In en, this message translates to:
  /// **'New Entries'**
  String get newEntries;

  /// No description provided for @entries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get entries;

  /// No description provided for @material.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get material;

  /// No description provided for @materials.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get materials;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemName;

  /// No description provided for @sounds.
  ///
  /// In en, this message translates to:
  /// **'Sounds'**
  String get sounds;

  /// No description provided for @selectSound.
  ///
  /// In en, this message translates to:
  /// **'Select Sound'**
  String get selectSound;

  /// No description provided for @removeSound.
  ///
  /// In en, this message translates to:
  /// **'Remove Sound'**
  String get removeSound;

  /// No description provided for @loadingSounds.
  ///
  /// In en, this message translates to:
  /// **'Loading Sounds...'**
  String get loadingSounds;

  /// No description provided for @faledToLoadSounds.
  ///
  /// In en, this message translates to:
  /// **'Failed to load sounds'**
  String get faledToLoadSounds;

  /// No description provided for @soundDescription.
  ///
  /// In en, this message translates to:
  /// **'{category} ({trackCount} Sound {trackWord})'**
  String soundDescription(Object category, Object trackCount, Object trackWord);

  /// No description provided for @texture.
  ///
  /// In en, this message translates to:
  /// **'Texture'**
  String get texture;

  /// No description provided for @signature.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get signature;

  /// No description provided for @pages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pages;

  /// No description provided for @unknownPage.
  ///
  /// In en, this message translates to:
  /// **'Unknown page'**
  String get unknownPage;

  /// No description provided for @invalidPageType.
  ///
  /// In en, this message translates to:
  /// **'Invalid page type'**
  String get invalidPageType;

  /// No description provided for @selectAPage.
  ///
  /// In en, this message translates to:
  /// **'Select a {type} page'**
  String selectAPage(Object type);

  /// No description provided for @pageNotAllowedHere.
  ///
  /// In en, this message translates to:
  /// **'Page is not allowed here'**
  String get pageNotAllowedHere;

  /// No description provided for @newPage.
  ///
  /// In en, this message translates to:
  /// **'New Page'**
  String get newPage;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @changePriority.
  ///
  /// In en, this message translates to:
  /// **'Change Priority'**
  String get changePriority;

  /// No description provided for @reconnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection lost, Reconnecting...'**
  String get reconnectTitle;

  /// No description provided for @reloadBookResyncDescription.
  ///
  /// In en, this message translates to:
  /// **'Reloading the full book to resync with the server.'**
  String get reloadBookResyncDescription;

  /// No description provided for @joinDiscord.
  ///
  /// In en, this message translates to:
  /// **'Join Discord'**
  String get joinDiscord;

  /// No description provided for @openWiki.
  ///
  /// In en, this message translates to:
  /// **'Open Wiki'**
  String get openWiki;

  /// No description provided for @reloadData.
  ///
  /// In en, this message translates to:
  /// **'Reload Data'**
  String get reloadData;

  /// No description provided for @fetchFromURL.
  ///
  /// In en, this message translates to:
  /// **'Fetch from URL'**
  String get fetchFromURL;

  /// No description provided for @fetchFromUUID.
  ///
  /// In en, this message translates to:
  /// **'Fetch from UUID'**
  String get fetchFromUUID;

  /// No description provided for @yawFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Yaw'**
  String get yawFieldLabel;

  /// No description provided for @pitchFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Pitch'**
  String get pitchFieldLabel;

  /// No description provided for @componentsCinematicDeleteSegment.
  ///
  /// In en, this message translates to:
  /// **'Delete Segment'**
  String get componentsCinematicDeleteSegment;

  /// No description provided for @componentsCinematicDuplicateSegment.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Segment'**
  String get componentsCinematicDuplicateSegment;

  /// No description provided for @componentsCinematicNoSegments.
  ///
  /// In en, this message translates to:
  /// **'No segments'**
  String get componentsCinematicNoSegments;

  /// No description provided for @establishingInterstellarConnection.
  ///
  /// In en, this message translates to:
  /// **'Establishing interstellar connection'**
  String get establishingInterstellarConnection;

  /// No description provided for @tuningCommunicationFrequency.
  ///
  /// In en, this message translates to:
  /// **'Tuning communication frequency'**
  String get tuningCommunicationFrequency;

  /// No description provided for @initiatingCommunicationProtocol.
  ///
  /// In en, this message translates to:
  /// **'Initiating communication protocol'**
  String get initiatingCommunicationProtocol;

  /// No description provided for @negotiatingConnectionParameters.
  ///
  /// In en, this message translates to:
  /// **'Negotiating connection parameters'**
  String get negotiatingConnectionParameters;

  /// No description provided for @analyzingNetworkTraffic.
  ///
  /// In en, this message translates to:
  /// **'Analyzing network traffic'**
  String get analyzingNetworkTraffic;

  /// No description provided for @establishingTelepathicLink.
  ///
  /// In en, this message translates to:
  /// **'Establishing telepathic link'**
  String get establishingTelepathicLink;

  /// No description provided for @activatingQuantumCommunication.
  ///
  /// In en, this message translates to:
  /// **'Activating quantum communication'**
  String get activatingQuantumCommunication;

  /// No description provided for @settingUpVirtualPrivateConnection.
  ///
  /// In en, this message translates to:
  /// **'Setting up virtual private connection'**
  String get settingUpVirtualPrivateConnection;

  /// No description provided for @checkingForNetworkInterference.
  ///
  /// In en, this message translates to:
  /// **'Checking for network interference'**
  String get checkingForNetworkInterference;

  /// No description provided for @hackingIntoTheMatrix.
  ///
  /// In en, this message translates to:
  /// **'Hacking into the matrix'**
  String get hackingIntoTheMatrix;

  /// No description provided for @summoningTheInterdimensionalPortal.
  ///
  /// In en, this message translates to:
  /// **'Summoning the interdimensional portal'**
  String get summoningTheInterdimensionalPortal;

  /// No description provided for @openingTheGatewayToTheAstralPlane.
  ///
  /// In en, this message translates to:
  /// **'Opening the gateway to the astral plane'**
  String get openingTheGatewayToTheAstralPlane;

  /// No description provided for @establishingConnectionToTheOtherSide.
  ///
  /// In en, this message translates to:
  /// **'Establishing connection to the other side'**
  String get establishingConnectionToTheOtherSide;

  /// No description provided for @connectingToTheCosmicMind.
  ///
  /// In en, this message translates to:
  /// **'Connecting to the cosmic mind'**
  String get connectingToTheCosmicMind;

  /// No description provided for @contactingExtraterrestrialIntelligence.
  ///
  /// In en, this message translates to:
  /// **'Contacting extraterrestrial intelligence'**
  String get contactingExtraterrestrialIntelligence;

  /// No description provided for @dialingUpTheTimeSpaceContinuum.
  ///
  /// In en, this message translates to:
  /// **'Dialing up the time-space continuum'**
  String get dialingUpTheTimeSpaceContinuum;

  /// No description provided for @downloadingThoughtsFromTheFuture.
  ///
  /// In en, this message translates to:
  /// **'Downloading thoughts from the future'**
  String get downloadingThoughtsFromTheFuture;

  /// No description provided for @establishingLinkToParallelUniverse.
  ///
  /// In en, this message translates to:
  /// **'Establishing link to parallel universe'**
  String get establishingLinkToParallelUniverse;

  /// No description provided for @establishingLinkToTheUniversalConsciousness.
  ///
  /// In en, this message translates to:
  /// **'Establishing link to the universal consciousness'**
  String get establishingLinkToTheUniversalConsciousness;

  /// No description provided for @tuningIntoTheCosmicFrequency.
  ///
  /// In en, this message translates to:
  /// **'Tuning into the cosmic frequency'**
  String get tuningIntoTheCosmicFrequency;

  /// No description provided for @initiatingIntergalacticCommunication.
  ///
  /// In en, this message translates to:
  /// **'Initiating intergalactic communication'**
  String get initiatingIntergalacticCommunication;

  /// No description provided for @bendingTheFabricOfReality.
  ///
  /// In en, this message translates to:
  /// **'Bending the fabric of reality'**
  String get bendingTheFabricOfReality;

  /// No description provided for @syncingWithTheCosmicClock.
  ///
  /// In en, this message translates to:
  /// **'Syncing with the cosmic clock'**
  String get syncingWithTheCosmicClock;

  /// No description provided for @activatingTheTransDimensionalRelay.
  ///
  /// In en, this message translates to:
  /// **'Activating the trans-dimensional relay'**
  String get activatingTheTransDimensionalRelay;

  /// No description provided for @establishingTelekineticConnection.
  ///
  /// In en, this message translates to:
  /// **'Establishing telekinetic connection'**
  String get establishingTelekineticConnection;

  /// No description provided for @channelingTheUniversalEnergy.
  ///
  /// In en, this message translates to:
  /// **'Channeling the universal energy'**
  String get channelingTheUniversalEnergy;

  /// No description provided for @unlockingTheSecretsOfTheUniverse.
  ///
  /// In en, this message translates to:
  /// **'Unlocking the secrets of the universe'**
  String get unlockingTheSecretsOfTheUniverse;

  /// No description provided for @contactingTheAllSeeingEye.
  ///
  /// In en, this message translates to:
  /// **'Contacting the all-seeing eye'**
  String get contactingTheAllSeeingEye;

  /// No description provided for @teleportingThroughTimeAndSpace.
  ///
  /// In en, this message translates to:
  /// **'Teleporting through time and space'**
  String get teleportingThroughTimeAndSpace;

  /// No description provided for @tuningIntoTheHigherDimensions.
  ///
  /// In en, this message translates to:
  /// **'Tuning into the higher dimensions'**
  String get tuningIntoTheHigherDimensions;

  /// No description provided for @connectingToTheGreatBeyond.
  ///
  /// In en, this message translates to:
  /// **'Connecting to the great beyond'**
  String get connectingToTheGreatBeyond;

  /// No description provided for @downloadingKnowledgeFromTheAkashicRecords.
  ///
  /// In en, this message translates to:
  /// **'Downloading knowledge from the Akashic records'**
  String get downloadingKnowledgeFromTheAkashicRecords;

  /// No description provided for @establishingAPsychicLink.
  ///
  /// In en, this message translates to:
  /// **'Establishing a psychic link'**
  String get establishingAPsychicLink;

  /// No description provided for @activatingTheCosmicGateway.
  ///
  /// In en, this message translates to:
  /// **'Activating the cosmic gateway'**
  String get activatingTheCosmicGateway;

  /// No description provided for @syncingWithTheUniverseFrequency.
  ///
  /// In en, this message translates to:
  /// **'Syncing with the universe frequency'**
  String get syncingWithTheUniverseFrequency;

  /// No description provided for @tuningIntoTheCosmicVibration.
  ///
  /// In en, this message translates to:
  /// **'Tuning into the cosmic vibration'**
  String get tuningIntoTheCosmicVibration;

  /// No description provided for @connectingToTheQuantumField.
  ///
  /// In en, this message translates to:
  /// **'Connecting to the quantum field'**
  String get connectingToTheQuantumField;

  /// No description provided for @establishingAConnectionToTheDivine.
  ///
  /// In en, this message translates to:
  /// **'Establishing a connection to the divine'**
  String get establishingAConnectionToTheDivine;

  /// No description provided for @channelingTheUniversalWisdom.
  ///
  /// In en, this message translates to:
  /// **'Channeling the universal wisdom'**
  String get channelingTheUniversalWisdom;

  /// No description provided for @emptyPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a page to edit or'**
  String get emptyPageTitle;

  /// No description provided for @addPage.
  ///
  /// In en, this message translates to:
  /// **'Add Page'**
  String get addPage;

  /// No description provided for @addNewPage.
  ///
  /// In en, this message translates to:
  /// **'Add New Page'**
  String get addNewPage;

  /// No description provided for @addNewPageForType.
  ///
  /// In en, this message translates to:
  /// **'Add a new {type} page'**
  String addNewPageForType(Object type);

  /// No description provided for @pageNameField.
  ///
  /// In en, this message translates to:
  /// **'Page Name'**
  String get pageNameField;

  /// No description provided for @pageNameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Page name cannot be empty'**
  String get pageNameCannotBeEmpty;

  /// No description provided for @pageNameCannotBeSame.
  ///
  /// In en, this message translates to:
  /// **'Page name cannot be the same'**
  String get pageNameCannotBeSame;

  /// No description provided for @advancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advancedSettings;

  /// No description provided for @chapterNameField.
  ///
  /// In en, this message translates to:
  /// **'Chapter Name'**
  String get chapterNameField;

  /// No description provided for @pagePriorityField.
  ///
  /// In en, this message translates to:
  /// **'Page priority'**
  String get pagePriorityField;

  /// No description provided for @renamePage.
  ///
  /// In en, this message translates to:
  /// **'Rename \${oldName}'**
  String renamePage(Object oldName);

  /// No description provided for @changeChapterTitle.
  ///
  /// In en, this message translates to:
  /// **'Change chapter'**
  String get changeChapterTitle;

  /// No description provided for @changeChapter.
  ///
  /// In en, this message translates to:
  /// **'Change chapter of \${pageId}'**
  String changeChapter(Object pageId);

  /// No description provided for @changePagePriority.
  ///
  /// In en, this message translates to:
  /// **'Change priority of \${pageId}'**
  String changePagePriority(Object pageId);

  /// No description provided for @deletePage.
  ///
  /// In en, this message translates to:
  /// **'Delete \${pageName}'**
  String deletePage(Object pageName);

  /// No description provided for @deletePageContent.
  ///
  /// In en, this message translates to:
  /// **'This will delete the page and all its content.\nTHIS CANNOT BE UNDONE.'**
  String get deletePageContent;

  /// No description provided for @enterAValueEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a value'**
  String get enterAValueEmpty;

  /// No description provided for @enterAValue.
  ///
  /// In en, this message translates to:
  /// **'Enter a {type}'**
  String enterAValue(Object type);

  /// No description provided for @invalidValue.
  ///
  /// In en, this message translates to:
  /// **'Invalid {name}: {value}'**
  String invalidValue(Object name, Object value);

  /// No description provided for @validValue.
  ///
  /// In en, this message translates to:
  /// **'Valid {name}: {value}'**
  String validValue(Object name, Object value);

  /// No description provided for @noGraphableEntries.
  ///
  /// In en, this message translates to:
  /// **'There are no graphable entries on this page.'**
  String get noGraphableEntries;

  /// No description provided for @addEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Entry'**
  String get addEntry;

  /// No description provided for @deleteSegment.
  ///
  /// In en, this message translates to:
  /// **'Delete Segment'**
  String get deleteSegment;

  /// No description provided for @deleteSegmentConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this segment?'**
  String get deleteSegmentConfirmation;

  /// No description provided for @couldNotAddSegment.
  ///
  /// In en, this message translates to:
  /// **'Could not add segment'**
  String get couldNotAddSegment;

  /// No description provided for @notEnoughSpace.
  ///
  /// In en, this message translates to:
  /// **'There is not enough space to add a segment.'**
  String get notEnoughSpace;

  /// No description provided for @addSegmentButton.
  ///
  /// In en, this message translates to:
  /// **'Add {title}'**
  String addSegmentButton(Object title);

  /// No description provided for @segment.
  ///
  /// In en, this message translates to:
  /// **'Segment {index}'**
  String segment(Object index);

  /// No description provided for @segments.
  ///
  /// In en, this message translates to:
  /// **'Segments'**
  String get segments;

  /// No description provided for @noSegments.
  ///
  /// In en, this message translates to:
  /// **'No segments'**
  String get noSegments;

  /// No description provided for @operations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get operations;

  /// No description provided for @segmentDuration.
  ///
  /// In en, this message translates to:
  /// **'Total Duration: {seconds} seconds ({frames} frames)'**
  String segmentDuration(Object seconds, Object frames);

  /// No description provided for @segmentInspectorTitle.
  ///
  /// In en, this message translates to:
  /// **'Segment Inspector'**
  String get segmentInspectorTitle;

  /// No description provided for @inspectorEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Select an entry to inspect'**
  String get inspectorEmptyTitle;

  /// No description provided for @inspectorEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select an entry from the list to view and edit its details'**
  String get inspectorEmptySubtitle;

  /// No description provided for @inspectorOperations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get inspectorOperations;

  /// No description provided for @moveEntry.
  ///
  /// In en, this message translates to:
  /// **'Move Entry'**
  String get moveEntry;

  /// No description provided for @missingBlueprint.
  ///
  /// In en, this message translates to:
  /// **'Missing Blueprint'**
  String get missingBlueprint;

  /// No description provided for @trackDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Track Duration'**
  String get trackDurationLabel;

  /// No description provided for @frame.
  ///
  /// In en, this message translates to:
  /// **'Frame'**
  String get frame;

  /// No description provided for @startFrame.
  ///
  /// In en, this message translates to:
  /// **'Start Frame'**
  String get startFrame;

  /// No description provided for @endFrame.
  ///
  /// In en, this message translates to:
  /// **'End Frame'**
  String get endFrame;

  /// No description provided for @enterFrameNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a frame number'**
  String get enterFrameNumber;

  /// No description provided for @noEntrySelected.
  ///
  /// In en, this message translates to:
  /// **'No entry selected'**
  String get noEntrySelected;

  /// No description provided for @noEntrySelectedDescriptionContent.
  ///
  /// In en, this message translates to:
  /// **'An entry must be selected to capture a field.'**
  String get noEntrySelectedDescriptionContent;

  /// No description provided for @noSegmentSelected.
  ///
  /// In en, this message translates to:
  /// **'No segment selected'**
  String get noSegmentSelected;

  /// No description provided for @frameBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'Cannot be before start frame'**
  String get frameBeforeStart;

  /// No description provided for @frameAfterEnd.
  ///
  /// In en, this message translates to:
  /// **'Cannot be after end frame'**
  String get frameAfterEnd;

  /// No description provided for @segmentTooShort.
  ///
  /// In en, this message translates to:
  /// **'The segment must be at least {minFrames} frames long'**
  String segmentTooShort(Object minFrames);

  /// No description provided for @segmentTooLong.
  ///
  /// In en, this message translates to:
  /// **'The segment must be at most {maxFrames} frames long'**
  String segmentTooLong(Object maxFrames);

  /// No description provided for @cannotExtendPastEndOfTrack.
  ///
  /// In en, this message translates to:
  /// **'Cannot extend past the end of the track'**
  String get cannotExtendPastEndOfTrack;

  /// No description provided for @cannotOverlapWithNextSegment.
  ///
  /// In en, this message translates to:
  /// **'Cannot overlap with next segment'**
  String get cannotOverlapWithNextSegment;

  /// No description provided for @cannotOverlapWithPreviousSegment.
  ///
  /// In en, this message translates to:
  /// **'Cannot overlap with previous segment'**
  String get cannotOverlapWithPreviousSegment;

  /// No description provided for @frameAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'A segment already exists at this frame'**
  String get frameAlreadyUsed;

  /// No description provided for @duplicateSegment.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Segment'**
  String get duplicateSegment;

  /// No description provided for @noCinematicEntries.
  ///
  /// In en, this message translates to:
  /// **'There are no cinematic entries on this page.'**
  String get noCinematicEntries;

  /// No description provided for @couldNotDeleteSegment.
  ///
  /// In en, this message translates to:
  /// **'Could not delete segment'**
  String get couldNotDeleteSegment;

  /// No description provided for @noPageSelected.
  ///
  /// In en, this message translates to:
  /// **'No page is selected.'**
  String get noPageSelected;

  /// No description provided for @noPageSelectedDescriptionContent.
  ///
  /// In en, this message translates to:
  /// **'A page must be selected to capture a field.'**
  String get noPageSelectedDescriptionContent;

  /// No description provided for @noBlueprintFoundForEntry.
  ///
  /// In en, this message translates to:
  /// **'No blueprint is found for the selected entry.'**
  String get noBlueprintFoundForEntry;

  /// No description provided for @noBlueprintFoundForSegment.
  ///
  /// In en, this message translates to:
  /// **'No blueprint is found for the selected segment.'**
  String get noBlueprintFoundForSegment;

  /// No description provided for @deleteReference.
  ///
  /// In en, this message translates to:
  /// **'Delete Reference'**
  String get deleteReference;

  /// No description provided for @nonExistentEntry.
  ///
  /// In en, this message translates to:
  /// **'Non-existent entry'**
  String get nonExistentEntry;

  /// No description provided for @selectEntry.
  ///
  /// In en, this message translates to:
  /// **'Select Entry'**
  String get selectEntry;

  /// No description provided for @selectAEntry.
  ///
  /// In en, this message translates to:
  /// **'Select a {name}'**
  String selectAEntry(Object name);

  /// No description provided for @entryNotAllow.
  ///
  /// In en, this message translates to:
  /// **'Entry is not allowed here'**
  String get entryNotAllow;

  /// No description provided for @entryReferenceNotAnEntry.
  ///
  /// In en, this message translates to:
  /// **'Entry reference is not an entry'**
  String get entryReferenceNotAnEntry;

  /// No description provided for @navigateToEntry.
  ///
  /// In en, this message translates to:
  /// **'Navigate to entry'**
  String get navigateToEntry;

  /// No description provided for @nonExistentBlueprint.
  ///
  /// In en, this message translates to:
  /// **'Non-existent blueprint'**
  String get nonExistentBlueprint;

  /// No description provided for @blueprintDoesNotExist.
  ///
  /// In en, this message translates to:
  /// **'Blueprint for this entry does not exist'**
  String get blueprintDoesNotExist;

  /// No description provided for @linkWith.
  ///
  /// In en, this message translates to:
  /// **'Link with ...'**
  String get linkWith;

  /// No description provided for @linkWithDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Link with duplicate'**
  String get linkWithDuplicate;

  /// No description provided for @moveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to ...'**
  String get moveTo;

  /// No description provided for @replaceWith.
  ///
  /// In en, this message translates to:
  /// **'Replace with ...'**
  String get replaceWith;

  /// No description provided for @addEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Add {type}'**
  String addEntryTitle(Object type);

  /// No description provided for @addPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Add {type}'**
  String addPageTitle(Object type);

  /// No description provided for @createPageDescription.
  ///
  /// In en, this message translates to:
  /// **'Add description for {type}'**
  String createPageDescription(Object type);

  /// No description provided for @manifestEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'There are no manifest entries on this page.'**
  String get manifestEmptyTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Enter search query...'**
  String get searchHint;

  /// No description provided for @worldFieldHint.
  ///
  /// In en, this message translates to:
  /// **'World'**
  String get worldFieldHint;

  /// No description provided for @materialSelectHint.
  ///
  /// In en, this message translates to:
  /// **'Select a material'**
  String get materialSelectHint;

  /// No description provided for @noStaticEntries.
  ///
  /// In en, this message translates to:
  /// **'There are no static entries on this page.'**
  String get noStaticEntries;

  /// No description provided for @replaceWithVariable.
  ///
  /// In en, this message translates to:
  /// **'Replace with Variable'**
  String get replaceWithVariable;

  /// No description provided for @removeVariable.
  ///
  /// In en, this message translates to:
  /// **'Remove Variable'**
  String get removeVariable;

  /// No description provided for @couldNotFindGenericBlueprint.
  ///
  /// In en, this message translates to:
  /// **'Could not find generic blueprint, this should not happen! For path: {path}'**
  String couldNotFindGenericBlueprint(Object path);

  /// No description provided for @entryDeprecatedWarning.
  ///
  /// In en, this message translates to:
  /// **'This entry has been marked as deprecated. Take a look at the '**
  String get entryDeprecatedWarning;

  /// No description provided for @entryDeprecatedWarningDocumentation.
  ///
  /// In en, this message translates to:
  /// **' documentation'**
  String get entryDeprecatedWarningDocumentation;

  /// No description provided for @entryDeprecatedWarningInfo.
  ///
  /// In en, this message translates to:
  /// **' for more information.'**
  String get entryDeprecatedWarningInfo;

  /// No description provided for @invalidCronExpression.
  ///
  /// In en, this message translates to:
  /// **'Invalid cron expression'**
  String get invalidCronExpression;

  /// No description provided for @validCron.
  ///
  /// In en, this message translates to:
  /// **'Valid cron expression: {humanReadable}'**
  String validCron(Object humanReadable);

  /// No description provided for @validDuration.
  ///
  /// In en, this message translates to:
  /// **'Valid duration: {duration}'**
  String validDuration(Object duration);

  /// No description provided for @genericNotFound.
  ///
  /// In en, this message translates to:
  /// **'Generic not found '**
  String get genericNotFound;

  /// No description provided for @genericNotFoundDescription.
  ///
  /// In en, this message translates to:
  /// **'please report this in the Typewriter Discord'**
  String get genericNotFoundDescription;

  /// No description provided for @globalContextKeyEditor_noGlobalKeys.
  ///
  /// In en, this message translates to:
  /// **'No extension has a global key. Try using an entry key.'**
  String get globalContextKeyEditor_noGlobalKeys;

  /// No description provided for @itemEditor_invalidShape.
  ///
  /// In en, this message translates to:
  /// **'Shape for item field is not an algebraic blueprint: {path}'**
  String itemEditor_invalidShape(Object path);

  /// No description provided for @itemEditor_itemFieldNotMap.
  ///
  /// In en, this message translates to:
  /// **'Value for serialized item field is not a map: {path}'**
  String itemEditor_itemFieldNotMap(Object path);

  /// No description provided for @itemEditor_noItemCaptured.
  ///
  /// In en, this message translates to:
  /// **'You have not yet captured the item. Click on the blue camera icon to capture the item you are holding in game.'**
  String get itemEditor_noItemCaptured;

  /// No description provided for @itemEditor_itemIsCaptured.
  ///
  /// In en, this message translates to:
  /// **'This item has been captured from in game. If you want to change it, you can re-capture the item.'**
  String get itemEditor_itemIsCaptured;

  /// No description provided for @noElementsFound.
  ///
  /// In en, this message translates to:
  /// **'No {name} found'**
  String noElementsFound(Object name);

  /// No description provided for @mapEditor_keyAlreadyExistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Override key?'**
  String get mapEditor_keyAlreadyExistsTitle;

  /// No description provided for @mapEditor_keyAlreadyExistsContent.
  ///
  /// In en, this message translates to:
  /// **'The key \'{key}\' already exists.\nThis will delete all the data from the existing key.'**
  String mapEditor_keyAlreadyExistsContent(Object key);

  /// No description provided for @materialNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable on \${version} servers'**
  String materialNotAvailable(Object version);

  /// No description provided for @numberEditorMinError.
  ///
  /// In en, this message translates to:
  /// **'Value must be at least {min}'**
  String numberEditorMinError(Object min);

  /// No description provided for @numberEditorMaxError.
  ///
  /// In en, this message translates to:
  /// **'Value must be at most {max}'**
  String numberEditorMaxError(Object max);

  /// No description provided for @invalidSubfield.
  ///
  /// In en, this message translates to:
  /// **'Invalid subfield, try to restart the server'**
  String get invalidSubfield;

  /// No description provided for @couldNotWireBlueprint.
  ///
  /// In en, this message translates to:
  /// **'Could not wire blueprint for entry \${bpId}, report this to the discord!'**
  String couldNotWireBlueprint(Object bpId);

  /// No description provided for @couldNotWireEntry.
  ///
  /// In en, this message translates to:
  /// **'Could not wire entry \${baseEntryId} to target entry \${targetEntryId}, report this to the discord!'**
  String couldNotWireEntry(Object baseEntryId, Object targetEntryId);

  /// No description provided for @couldNotReplaceEntry.
  ///
  /// In en, this message translates to:
  /// **'Could not replace entry \${baseEntryId} with target entry \${targetEntryId}, report this to the discord!'**
  String couldNotReplaceEntry(Object baseEntryId, Object targetEntryId);

  /// No description provided for @dataBlueprintMismatch.
  ///
  /// In en, this message translates to:
  /// **'Data blueprint for path {path} did not match'**
  String dataBlueprintMismatch(Object path);

  /// No description provided for @pathNotAListWhileBlueprintRequiresAList.
  ///
  /// In en, this message translates to:
  /// **'Path {path} is not a list while blueprint requires a list'**
  String pathNotAListWhileBlueprintRequiresAList(Object path);

  /// No description provided for @pathNotAMapWhileBlueprintRequiresAMap.
  ///
  /// In en, this message translates to:
  /// **'Path {path} is not a map while blueprint requires a map'**
  String pathNotAMapWhileBlueprintRequiresAMap(Object path);

  /// No description provided for @noDataBlueprintFound.
  ///
  /// In en, this message translates to:
  /// **'No data blueprint found for path {path}'**
  String noDataBlueprintFound(Object path);

  /// No description provided for @blueprintNotCompatibleWithGeneric.
  ///
  /// In en, this message translates to:
  /// **'The generic blueprint of the entry is not compatible with the new blueprint'**
  String get blueprintNotCompatibleWithGeneric;

  /// No description provided for @potionEffects.
  ///
  /// In en, this message translates to:
  /// **'Potion Effects'**
  String get potionEffects;

  /// No description provided for @variableReferenceNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not find Variable Reference, '**
  String get variableReferenceNotFound;

  /// No description provided for @variableReferenceNotFoundReset.
  ///
  /// In en, this message translates to:
  /// **'click to reset to default'**
  String get variableReferenceNotFoundReset;

  /// No description provided for @requestContentMode.
  ///
  /// In en, this message translates to:
  /// **'Request Content mode'**
  String get requestContentMode;
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
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
