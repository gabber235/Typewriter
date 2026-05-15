// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TypeWriter';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get homeTitle => 'Your journey starts here';

  @override
  String get homeSubtitle =>
      'Run the following command on your server to start editing';

  @override
  String get connectToTitle => 'Connect to';

  @override
  String get connectToHint => 'Fill in the url to connect to';

  @override
  String get unexpectedError =>
      'An error occurred, please report on the Typewriter Discord';

  @override
  String get noSkinDataError => 'Could not find the skin data in the response';

  @override
  String get invalidTextureDataError => 'Invalid texture data in response';

  @override
  String get textureAndSignatureMustBeStrings =>
      'Invalid texture or signature in response';

  @override
  String get noEntryChecked => 'Currently not inspecting an entry';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String addNew(Object item) {
    return 'Add new $item';
  }

  @override
  String get open => 'Open';

  @override
  String get actions => 'Actions';

  @override
  String get rename => 'Rename';

  @override
  String get connect => 'Connect';

  @override
  String get publish => 'Publish';

  @override
  String get stagingProduction => 'Production';

  @override
  String get stagingStaging => 'Staging';

  @override
  String get stagingPublishing => 'Publishing';

  @override
  String get priority => 'Priority';

  @override
  String get delete => 'Delete';

  @override
  String deleteThis(Object item) {
    return 'Remove $item?';
  }

  @override
  String get deleteEntry => 'Delete entry?';

  @override
  String deleteEntryConfirmation(Object entry) {
    return 'Are you sure you want to delete $entry?';
  }

  @override
  String get replaceEntry => 'Replace Entry';

  @override
  String replaceEntryConfirmation(Object entry) {
    return 'Replacing entries is not reversible.\nIt may result in data loss or data corruption.\nAre you sure you want to replace $entry?';
  }

  @override
  String get replace => 'Replace';

  @override
  String get confirm => 'Confirm';

  @override
  String get select => 'Select';

  @override
  String get duplicate => 'Duplicate';

  @override
  String duplicateThis(Object item) {
    return 'Duplicate $item';
  }

  @override
  String get fetchSkin => 'Fetch Skin';

  @override
  String fetchSkinHint(Object bodyKey) {
    return 'Enter the $bodyKey to fetch the skin';
  }

  @override
  String get duration => 'Duration';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get thisActionCannotBeUndone => 'This action cannot be undone.';

  @override
  String get connectLocalhost => 'Connect Localhost';

  @override
  String get connectCustom => 'Connect Custom';

  @override
  String get waitingForConnection => 'Waiting for connection';

  @override
  String get errorConnectTitle => 'Communication error';

  @override
  String get errorConnectSubtitle =>
      'There was an error while communicating to the server.\nPlease check your connection and try again.';

  @override
  String get placeholderInfo =>
      'Placeholders like %player_name% are supported. Click for more info.';

  @override
  String get regexInfo =>
      'Regular expressions are supported. Click for more info.';

  @override
  String get coloredInfo =>
      'Adventure Mini Format is supported. Click for more info.';

  @override
  String get pageSearch => 'Search';

  @override
  String get fields => 'Fields';

  @override
  String get pagesTitle => 'Pages';

  @override
  String get unknownPage => 'Unknown page';

  @override
  String get newPage => 'New Page';

  @override
  String get change => 'Change';

  @override
  String get changePriority => 'Change Priority';

  @override
  String get reconnectTitle => 'Connection lost, Reconnecting...';

  @override
  String get joinDiscord => 'Join Discord';

  @override
  String get openWiki => 'Open Wiki';

  @override
  String get reloadData => 'Reload Data';

  @override
  String get fetchFromURL => 'Fetch from URL';

  @override
  String get fetchFromUUID => 'Fetch from UUID';

  @override
  String get componentsCinematicDeleteSegment => 'Delete Segment';

  @override
  String get componentsCinematicDuplicateSegment => 'Duplicate Segment';

  @override
  String get componentsCinematicNoSegments => 'No segments';

  @override
  String get establishingInterstellarConnection =>
      'Establishing interstellar connection';

  @override
  String get tuningCommunicationFrequency => 'Tuning communication frequency';

  @override
  String get initiatingCommunicationProtocol =>
      'Initiating communication protocol';

  @override
  String get negotiatingConnectionParameters =>
      'Negotiating connection parameters';

  @override
  String get analyzingNetworkTraffic => 'Analyzing network traffic';

  @override
  String get establishingTelepathicLink => 'Establishing telepathic link';

  @override
  String get activatingQuantumCommunication =>
      'Activating quantum communication';

  @override
  String get settingUpVirtualPrivateConnection =>
      'Setting up virtual private connection';

  @override
  String get checkingForNetworkInterference =>
      'Checking for network interference';

  @override
  String get hackingIntoTheMatrix => 'Hacking into the matrix';

  @override
  String get summoningTheInterdimensionalPortal =>
      'Summoning the interdimensional portal';

  @override
  String get openingTheGatewayToTheAstralPlane =>
      'Opening the gateway to the astral plane';

  @override
  String get establishingConnectionToTheOtherSide =>
      'Establishing connection to the other side';

  @override
  String get connectingToTheCosmicMind => 'Connecting to the cosmic mind';

  @override
  String get contactingExtraterrestrialIntelligence =>
      'Contacting extraterrestrial intelligence';

  @override
  String get dialingUpTheTimeSpaceContinuum =>
      'Dialing up the time-space continuum';

  @override
  String get downloadingThoughtsFromTheFuture =>
      'Downloading thoughts from the future';

  @override
  String get establishingLinkToParallelUniverse =>
      'Establishing link to parallel universe';

  @override
  String get establishingLinkToTheUniversalConsciousness =>
      'Establishing link to the universal consciousness';

  @override
  String get tuningIntoTheCosmicFrequency => 'Tuning into the cosmic frequency';

  @override
  String get initiatingIntergalacticCommunication =>
      'Initiating intergalactic communication';

  @override
  String get bendingTheFabricOfReality => 'Bending the fabric of reality';

  @override
  String get syncingWithTheCosmicClock => 'Syncing with the cosmic clock';

  @override
  String get activatingTheTransDimensionalRelay =>
      'Activating the trans-dimensional relay';

  @override
  String get establishingTelekineticConnection =>
      'Establishing telekinetic connection';

  @override
  String get channelingTheUniversalEnergy => 'Channeling the universal energy';

  @override
  String get unlockingTheSecretsOfTheUniverse =>
      'Unlocking the secrets of the universe';

  @override
  String get contactingTheAllSeeingEye => 'Contacting the all-seeing eye';

  @override
  String get teleportingThroughTimeAndSpace =>
      'Teleporting through time and space';

  @override
  String get tuningIntoTheHigherDimensions =>
      'Tuning into the higher dimensions';

  @override
  String get connectingToTheGreatBeyond => 'Connecting to the great beyond';

  @override
  String get downloadingKnowledgeFromTheAkashicRecords =>
      'Downloading knowledge from the Akashic records';

  @override
  String get establishingAPsychicLink => 'Establishing a psychic link';

  @override
  String get activatingTheCosmicGateway => 'Activating the cosmic gateway';

  @override
  String get syncingWithTheUniverseFrequency =>
      'Syncing with the universe frequency';

  @override
  String get tuningIntoTheCosmicVibration => 'Tuning into the cosmic vibration';

  @override
  String get connectingToTheQuantumField => 'Connecting to the quantum field';

  @override
  String get establishingAConnectionToTheDivine =>
      'Establishing a connection to the divine';

  @override
  String get channelingTheUniversalWisdom => 'Channeling the universal wisdom';

  @override
  String get emptyPageTitle => 'Select a page to edit or';

  @override
  String get addPage => 'Add Page';

  @override
  String get addNewPage => 'Add New Page';

  @override
  String addNewPageForType(Object type) {
    return 'Add a new $type page';
  }

  @override
  String get pageNameField => 'Page Name';

  @override
  String get pageNameCannotBeEmpty => 'Page name cannot be empty';

  @override
  String get pageNameCannotBeSame => 'Page name cannot be the same';

  @override
  String get advancedSettings => 'Advanced';

  @override
  String get chapterNameField => 'Chapter Name';

  @override
  String get pagePriorityField => 'Page priority';

  @override
  String renamePage(Object oldName) {
    return 'Rename \$$oldName';
  }

  @override
  String get changeChapterTitle => 'Change chapter';

  @override
  String changeChapter(Object pageId) {
    return 'Change chapter of \$$pageId';
  }

  @override
  String changePagePriority(Object pageId) {
    return 'Change priority of \$$pageId';
  }

  @override
  String deletePage(Object pageName) {
    return 'Delete \$$pageName';
  }

  @override
  String get deletePageContent =>
      'This will delete the page and all its content.\nTHIS CANNOT BE UNDONE.';

  @override
  String get enterAValueEmpty => 'Enter a value';

  @override
  String enterAValue(Object type) {
    return 'Enter a $type';
  }

  @override
  String invalidValue(Object name, Object value) {
    return 'Invalid $name: $value';
  }

  @override
  String validValue(Object name, Object value) {
    return 'Valid $name: $value';
  }

  @override
  String get noGraphableEntries =>
      'There are no graphable entries on this page.';

  @override
  String get addEntry => 'Add Entry';

  @override
  String get deleteSegment => 'Delete Segment';

  @override
  String get deleteSegmentConfirmation =>
      'Are you sure you want to delete this segment?';

  @override
  String get couldNotAddSegment => 'Could not add segment';

  @override
  String get notEnoughSpace => 'There is not enough space to add a segment.';

  @override
  String addSegmentButton(Object title) {
    return 'Add $title';
  }

  @override
  String segment(Object index) {
    return 'Segment $index';
  }

  @override
  String get segments => 'Segments';

  @override
  String get noSegments => 'No segments';

  @override
  String get operations => 'Operations';

  @override
  String segmentDuration(Object seconds, Object frames) {
    return 'Total Duration: $seconds seconds ($frames frames)';
  }

  @override
  String get segmentInspectorTitle => 'Segment Inspector';

  @override
  String get inspectorEmptyTitle => 'Select an entry to inspect';

  @override
  String get inspectorEmptySubtitle =>
      'Select an entry from the list to view and edit its details';

  @override
  String get inspectorOperations => 'Operations';

  @override
  String get moveEntry => 'Move Entry';

  @override
  String get missingBlueprint => 'Missing Blueprint';

  @override
  String get trackDurationLabel => 'Track Duration';

  @override
  String get frame => 'Frame';

  @override
  String get startFrame => 'Start Frame';

  @override
  String get endFrame => 'End Frame';

  @override
  String get enterFrameNumber => 'Enter a frame number';

  @override
  String get noEntrySelected => 'No entry selected';

  @override
  String get noEntrySelectedDescriptionContent =>
      'An entry must be selected to capture a field.';

  @override
  String get noSegmentSelected => 'No segment selected';

  @override
  String get frameBeforeStart => 'Cannot be before start frame';

  @override
  String get frameAfterEnd => 'Cannot be after end frame';

  @override
  String segmentTooShort(Object minFrames) {
    return 'The segment must be at least $minFrames frames long';
  }

  @override
  String segmentTooLong(Object maxFrames) {
    return 'The segment must be at most $maxFrames frames long';
  }

  @override
  String get cannotExtendPastEndOfTrack =>
      'Cannot extend past the end of the track';

  @override
  String get cannotOverlapWithNextSegment => 'Cannot overlap with next segment';

  @override
  String get cannotOverlapWithPreviousSegment =>
      'Cannot overlap with previous segment';

  @override
  String get frameAlreadyUsed => 'A segment already exists at this frame';

  @override
  String get duplicateSegment => 'Duplicate Segment';

  @override
  String get noCinematicEntries =>
      'There are no cinematic entries on this page.';

  @override
  String get couldNotDeleteSegment => 'Could not delete segment';

  @override
  String get noPageSelected => 'No page is selected.';

  @override
  String get noPageSelectedDescriptionContent =>
      'A page must be selected to capture a field.';

  @override
  String get noBlueprintFoundForEntry =>
      'No blueprint is found for the selected entry.';

  @override
  String get noBlueprintFoundForSegment =>
      'No blueprint is found for the selected segment.';

  @override
  String get deleteRefference => 'Delete Reference';

  @override
  String get nonExistentEntry => 'Non-existent entry';

  @override
  String get entryReferenceNotAnEntry => 'Entry reference is not an entry';

  @override
  String get nonExistentBlueprint => 'Non-existent blueprint';

  @override
  String get blueprintDoesNotExist => 'Blueprint for this entry does not exist';

  @override
  String get linkWith => 'Link with ...';

  @override
  String get linkWithDuplicate => 'Link with duplicate';

  @override
  String get moveTo => 'Move to ...';

  @override
  String get replaceWith => 'Replace with ...';

  @override
  String addEntryTitle(Object type) {
    return 'Add $type';
  }

  @override
  String addPageTitle(Object type) {
    return 'Add $type';
  }

  @override
  String createPageDescription(Object type) {
    return 'Add description for $type';
  }

  @override
  String get manifestEmptyTitle =>
      'There are no manifest entries on this page.';

  @override
  String get searchHint => 'Enter search query...';

  @override
  String get noStaticEntries => 'There are no static entries on this page.';

  @override
  String get replaceWithVariable => 'Replace with Variable';

  @override
  String get removeVariable => 'Remove Variable';

  @override
  String couldNotFindGenericBlueprint(Object path) {
    return 'Could not find generic blueprint, this should not happen! For path: $path';
  }

  @override
  String get entryDeprecatedWarning =>
      'This entry has been marked as deprecated. Take a look at the ';

  @override
  String get entryDeprecatedWarningDocumentation => ' documentation';

  @override
  String get entryDeprecatedWarningInfo => ' for more information.';
}
