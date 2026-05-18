// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'TypeWriter';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get homeTitle => 'Твоё приключение начинается здесь';

  @override
  String get homeSubtitle =>
      'Введите эту команду в консоли Minecraft, чтобы подключиться';

  @override
  String get connectToTitle => 'Подключиться к серверу';

  @override
  String get connectToHint => 'Введите адрес сервера';

  @override
  String get unexpectedError =>
      'Произошла ошибка, пожалуйста, сообщите в Discord Typewriter';

  @override
  String get noSkinDataError => 'Не удалось найти данные о скине в ответе';

  @override
  String get invalidTextureDataError => 'Недопустимые данные текстуры в ответе';

  @override
  String get textureAndSignatureMustBeStrings =>
      'Недопустимая текстура или подпись в ответе';

  @override
  String get noEntryChecked => 'Сущность не выбрана';

  @override
  String get cancel => 'Отмена';

  @override
  String get add => 'Добавить';

  @override
  String addNew(Object item) {
    return 'Добавить новый $item';
  }

  @override
  String get trueValue => 'Верно';

  @override
  String get falseValue => 'Неверно';

  @override
  String get hexCode => 'Hex код';

  @override
  String get open => 'Открыть';

  @override
  String get actions => 'Действия';

  @override
  String get rename => 'Переименовать';

  @override
  String get connect => 'Подключиться';

  @override
  String get publish => 'Жми!';

  @override
  String get stagingProduction => 'Продакшн';

  @override
  String get stagingStaging => 'Установка';

  @override
  String get stagingPublishing => 'Публикация';

  @override
  String get priority => 'Приоритет';

  @override
  String get delete => 'Удалить';

  @override
  String deleteThis(Object item) {
    return 'Удалить $item';
  }

  @override
  String get deleteEntry => 'Удалить ноду';

  @override
  String deleteEntryConfirmation(Object entry) {
    return 'Вы уверены, что хотите удалить $entry?';
  }

  @override
  String get replaceEntry => 'Заменить ноду';

  @override
  String replaceEntryConfirmation(Object entry) {
    return 'Замена нод необратима.\nЭто может привести к потере или повреждению данных.\nВы уверены, что хотите заменить $entry?';
  }

  @override
  String get replace => 'Заменить';

  @override
  String get confirm => 'Поддтвердить';

  @override
  String get select => 'Выбрать';

  @override
  String get duplicate => 'Дублировать';

  @override
  String duplicateThis(Object item) {
    return 'Дублировать $item';
  }

  @override
  String get fetchSkin => 'Получить скин';

  @override
  String get fetch => 'Получить';

  @override
  String fetchSkinHint(Object bodyKey) {
    return 'Введите $bodyKey для получения скина';
  }

  @override
  String get duration => 'Длительность';

  @override
  String get areYouSure => 'Вы уверены?';

  @override
  String get thisActionCannotBeUndone => 'Это действие не может быть отменено.';

  @override
  String get connectLocalhost => 'Подключиться к localhost';

  @override
  String get connectCustom => 'Своё подключение';

  @override
  String get waitingForConnection => 'Ожидание подключения...';

  @override
  String get errorConnectTitle => 'Ошибка коммуникации';

  @override
  String get errorConnectSubtitle =>
      'Произошла ошибка при коммуникации с сервером.\nПожалуйста, проверьте ваше подключение и попробуйте снова.';

  @override
  String get placeholderInfo =>
      'Плейсхолдеры типа %player_name% поддерживаются. Нажмите для получения дополнительной информации.';

  @override
  String get regexInfo =>
      'Регулярные выражения поддерживаются. Нажмите для получения дополнительной информации.';

  @override
  String get coloredInfo =>
      'Поддерживается формат Adventure Mini. Нажмите для получения дополнительной информации.';

  @override
  String get pageSearch => 'Поиск';

  @override
  String get fields => 'Поля';

  @override
  String get entry => 'Нода';

  @override
  String get name => 'Имя';

  @override
  String get nameHint => 'Введите имя';

  @override
  String get algebraicEditorInvalidData =>
      'Это поле содержит недопустимые данные.';

  @override
  String algebraicEditorCaseNotFound(Object name) {
    return 'Не удалось найти кейс для $name. ';
  }

  @override
  String get selectCase => 'Выберите кейс';

  @override
  String get valueReset => 'Нажмите здесь, чтобы сбросить значение.';

  @override
  String setCaseType(Object name) {
    return 'Установить $name как тип поля';
  }

  @override
  String get newEntries => 'Новые ноды';

  @override
  String get entries => 'Ноды';

  @override
  String get material => 'Материал';

  @override
  String get materials => 'Материалы';

  @override
  String get itemName => 'Имя предмета';

  @override
  String get sounds => 'Звуки';

  @override
  String get selectSound => 'Выбрать звук';

  @override
  String get removeSound => 'Удалить звук';

  @override
  String get loadingSounds => 'Загрузка звуков...';

  @override
  String get faledToLoadSounds => 'Не удалось загрузить звуки';

  @override
  String soundDescription(
      Object category, Object trackCount, Object trackWord) {
    return '$category ($trackCount Звук $trackWord)';
  }

  @override
  String get texture => 'Текстура';

  @override
  String get signature => 'Подпись';

  @override
  String get pages => 'Страницы';

  @override
  String get unknownPage => 'Неизвестная страница';

  @override
  String get invalidPageType => 'Недопустимый тип страницы';

  @override
  String selectAPage(Object type) {
    return 'Выберите страницу $type';
  }

  @override
  String get pageNotAllowedHere => 'Страница не разрешена здесь';

  @override
  String get newPage => 'Новая страница';

  @override
  String get change => 'Изменить';

  @override
  String get changePriority => 'Изменить приоритет';

  @override
  String get reconnectTitle => 'Соединение потеряно, реконнект...';

  @override
  String get reloadBookResyncDescription =>
      'Полная книга перезагружается для повторной синхронизации с сервером.';

  @override
  String get joinDiscord => 'Подключатесь к Discord';

  @override
  String get openWiki => 'Открыть вики';

  @override
  String get reloadData => 'Обновить данные';

  @override
  String get fetchFromURL => 'Получить из URL';

  @override
  String get fetchFromUUID => 'Получить из UUID';

  @override
  String get yawFieldLabel => 'Yaw (Горизонтальный угол)';

  @override
  String get pitchFieldLabel => 'Pitch (Вертикальный угол)';

  @override
  String get componentsCinematicDeleteSegment => 'Удалить сегмент';

  @override
  String get componentsCinematicDuplicateSegment => 'Дублировать сегмент';

  @override
  String get componentsCinematicNoSegments => 'Нет сегментов';

  @override
  String get establishingInterstellarConnection =>
      'Установка межзвездного соединения';

  @override
  String get tuningCommunicationFrequency => 'Настройка частоты коммуникации';

  @override
  String get initiatingCommunicationProtocol =>
      'Инициализация протокола коммуникации';

  @override
  String get negotiatingConnectionParameters =>
      'Согласование параметров подключения';

  @override
  String get analyzingNetworkTraffic => 'Анализ трафика сети';

  @override
  String get establishingTelepathicLink => 'Установка телепатической связи';

  @override
  String get activatingQuantumCommunication =>
      'Активация квантовой коммуникации';

  @override
  String get settingUpVirtualPrivateConnection =>
      'Настройка виртуального частного соединения';

  @override
  String get checkingForNetworkInterference => 'Проверка на помехи в сети';

  @override
  String get hackingIntoTheMatrix => 'Ломаем матрицу';

  @override
  String get summoningTheInterdimensionalPortal =>
      'Вызов межпространственного портала';

  @override
  String get openingTheGatewayToTheAstralPlane =>
      'Открытие ворот в астральный план';

  @override
  String get establishingConnectionToTheOtherSide =>
      'Установка соединения с другой стороной';

  @override
  String get connectingToTheCosmicMind => 'Подключение к космическому разуму';

  @override
  String get contactingExtraterrestrialIntelligence =>
      'Контакт с внеземной интеллектуальной силой';

  @override
  String get dialingUpTheTimeSpaceContinuum =>
      'Вызов временно-пространственного континуума';

  @override
  String get downloadingThoughtsFromTheFuture =>
      'Скачивание мыслей из будущего';

  @override
  String get establishingLinkToParallelUniverse =>
      'Установка связи с параллельной вселенной';

  @override
  String get establishingLinkToTheUniversalConsciousness =>
      'Установка связи с универсальным сознанием';

  @override
  String get tuningIntoTheCosmicFrequency => 'Настройка на космическую частоту';

  @override
  String get initiatingIntergalacticCommunication =>
      'Инициация межгалактической коммуникации';

  @override
  String get bendingTheFabricOfReality => 'Изгибание ткани реальности';

  @override
  String get syncingWithTheCosmicClock =>
      'Синхронизируясь с космическими часами';

  @override
  String get activatingTheTransDimensionalRelay =>
      'Активация транс-измерительного реле';

  @override
  String get establishingTelekineticConnection =>
      'Установка телекинетического соединения';

  @override
  String get channelingTheUniversalEnergy => 'Передача универсальной энергии';

  @override
  String get unlockingTheSecretsOfTheUniverse => 'Раскрытие секретов вселенной';

  @override
  String get contactingTheAllSeeingEye => 'Контакт с всеохватывающим глазом';

  @override
  String get teleportingThroughTimeAndSpace =>
      'Телепортация через время и пространство';

  @override
  String get tuningIntoTheHigherDimensions =>
      'Настройка на более высокие измерения';

  @override
  String get connectingToTheGreatBeyond => 'Обращаемся к великому за пределами';

  @override
  String get downloadingKnowledgeFromTheAkashicRecords =>
      'Скачивание знаний из Акашевых записей';

  @override
  String get establishingAPsychicLink => 'Установка психической связи';

  @override
  String get activatingTheCosmicGateway => 'Активация космического шлюза';

  @override
  String get syncingWithTheUniverseFrequency =>
      'Синхронизация с частотой вселенной';

  @override
  String get tuningIntoTheCosmicVibration =>
      'Настройка на космическую вибрацию';

  @override
  String get connectingToTheQuantumField => 'Подключение к квантовому полю';

  @override
  String get establishingAConnectionToTheDivine =>
      'Установка связи с божественным';

  @override
  String get channelingTheUniversalWisdom => 'Передача универсальной мудрости';

  @override
  String get emptyPageTitle => 'Выберите страницу или создайте новую';

  @override
  String get addPage => 'Добавить страницу';

  @override
  String get addNewPage => 'Добавить новую страницу';

  @override
  String addNewPageForType(Object type) {
    return 'Добавить новую страницу типа $type';
  }

  @override
  String get pageNameField => 'Имя страницы';

  @override
  String get pageNameCannotBeEmpty => 'Имя страницы не может быть пустым';

  @override
  String get pageNameCannotBeSame =>
      'Имя страницы не может быть таким же, как у другой страницы';

  @override
  String get advancedSettings => 'Расширенные настройки';

  @override
  String get chapterNameField => 'Имя главы';

  @override
  String get pagePriorityField => 'Приоритет страницы';

  @override
  String renamePage(Object oldName) {
    return 'Переименовать \$$oldName';
  }

  @override
  String get changeChapterTitle => 'Изменить главу';

  @override
  String changeChapter(Object pageId) {
    return 'Изменить главу \$$pageId';
  }

  @override
  String changePagePriority(Object pageId) {
    return 'Изменить приоритет \$$pageId';
  }

  @override
  String deletePage(Object pageName) {
    return 'Удалить \$$pageName';
  }

  @override
  String get deletePageContent =>
      'Это приведет к удалению страницы и всего ее содержимого.\nЭТО НЕЛЬЗЯ ОТМЕНИТЬ.';

  @override
  String get enterAValueEmpty => 'Введите значение';

  @override
  String enterAValue(Object type) {
    return 'Введите $type';
  }

  @override
  String invalidValue(Object name, Object value) {
    return 'Недопустимое $name: $value';
  }

  @override
  String validValue(Object name, Object value) {
    return 'Допустимое $name: $value';
  }

  @override
  String get noGraphableEntries => 'На этой странице нет графических записей.';

  @override
  String get addEntry => 'Добавить ноду';

  @override
  String get deleteSegment => 'Удалить сегмент';

  @override
  String get deleteSegmentConfirmation =>
      'Вы уверены, что хотите удалить этот сегмент?';

  @override
  String get couldNotAddSegment => 'Не удалось добавить сегмент';

  @override
  String get notEnoughSpace => 'Недостаточно места для добавления сегмента.';

  @override
  String addSegmentButton(Object title) {
    return 'Добавить $title';
  }

  @override
  String segment(Object index) {
    return 'Сегмент $index';
  }

  @override
  String get segments => 'Сегменты';

  @override
  String get noSegments => 'Нет сегментов';

  @override
  String get operations => 'Операции';

  @override
  String segmentDuration(Object seconds, Object frames) {
    return 'Общая продолжительность: $seconds секунд ($frames кадров)';
  }

  @override
  String get segmentInspectorTitle => 'Инспектор сегментов';

  @override
  String get inspectorEmptyTitle => 'Выберите ноду для просмотра';

  @override
  String get inspectorEmptySubtitle =>
      'Выберите ноду из списка, чтобы просмотреть и отредактировать ее детали';

  @override
  String get inspectorOperations => 'Операции';

  @override
  String get moveEntry => 'Переместить ноду';

  @override
  String get missingBlueprint => 'Отсутствует чертеж';

  @override
  String get trackDurationLabel => 'Продолжительность трека';

  @override
  String get frame => 'Кадр';

  @override
  String get startFrame => 'Начальный кадр';

  @override
  String get endFrame => 'Конечный кадр';

  @override
  String get enterFrameNumber => 'Введите номер кадра';

  @override
  String get noEntrySelected => 'Нода не выбрана';

  @override
  String get noEntrySelectedDescriptionContent =>
      'Нода должна быть выбрана для захвата поля.';

  @override
  String get noSegmentSelected => 'Сегмент не выбран';

  @override
  String get frameBeforeStart => 'Не может быть до начального кадра';

  @override
  String get frameAfterEnd => 'Не может быть после конечного кадра';

  @override
  String segmentTooShort(Object minFrames) {
    return 'Сегмент слишком короткий: $minFrames кадров';
  }

  @override
  String segmentTooLong(Object maxFrames) {
    return 'Сегмент слишком длинный: $maxFrames кадров';
  }

  @override
  String get cannotExtendPastEndOfTrack =>
      'Невозможно продлить за пределы трека';

  @override
  String get cannotOverlapWithNextSegment =>
      'Невозможно перекрыть следующий сегмент';

  @override
  String get cannotOverlapWithPreviousSegment =>
      'Невозможно перекрыть предыдущий сегмент';

  @override
  String get frameAlreadyUsed => 'Сегмент уже существует на этом кадре';

  @override
  String get duplicateSegment => 'Дублировать сегмент';

  @override
  String get noCinematicEntries => 'На этой странице нет нoд синематики.';

  @override
  String get couldNotDeleteSegment => 'Не удалось удалить сегмент';

  @override
  String get noPageSelected => 'Страница не выбрана.';

  @override
  String get noPageSelectedDescriptionContent =>
      'Страница должна быть выбрана для захвата поля.';

  @override
  String get noBlueprintFoundForEntry =>
      'Чертеж не найден для выбранной записи.';

  @override
  String get noBlueprintFoundForSegment =>
      'Чертеж не найден для выбранного сегмента.';

  @override
  String get deleteReference => 'Удалить ссылку';

  @override
  String get nonExistentEntry => 'Нода не существует';

  @override
  String get selectEntry => 'Выбрать ноду';

  @override
  String selectAEntry(Object name) {
    return 'Выберите $name';
  }

  @override
  String get entryNotAllow => 'Нода не разрешена здесь';

  @override
  String get entryReferenceNotAnEntry => 'Референс нoды не является нoдой';

  @override
  String get navigateToEntry => 'Перейти к ноде';

  @override
  String get nonExistentBlueprint => 'Чертеж не существует';

  @override
  String get blueprintDoesNotExist => 'Чертеж для этой нodы не существует';

  @override
  String get linkWith => 'Связать с ...';

  @override
  String get linkWithDuplicate => 'Связать с дубликатом';

  @override
  String get moveTo => 'Переместить в ...';

  @override
  String get replaceWith => 'Заменить на ...';

  @override
  String addEntryTitle(Object type) {
    return 'Добавить $type';
  }

  @override
  String addPageTitle(Object type) {
    return 'Добавить $type';
  }

  @override
  String createPageDescription(Object type) {
    return 'Добавить описание для $type';
  }

  @override
  String get manifestEmptyTitle => 'На этой странице нет нод манифеста.';

  @override
  String get searchHint => 'Введите запрос для поиска...';

  @override
  String get worldFieldHint => 'Мир';

  @override
  String get materialSelectHint => 'Выберите материал';

  @override
  String get noStaticEntries => 'На этой странице нет статичных нод.';

  @override
  String get replaceWithVariable => 'Заменить на переменную';

  @override
  String get removeVariable => 'Удалить переменную';

  @override
  String couldNotFindGenericBlueprint(Object path) {
    return 'Не удалось найти генеративный чертеж для $path';
  }

  @override
  String get entryDeprecatedWarning =>
      'Эта нода была помечена как устаревшая. Посетите';

  @override
  String get entryDeprecatedWarningDocumentation => ' документацию';

  @override
  String get entryDeprecatedWarningInfo => ' для получения подробностей.';

  @override
  String get invalidCronExpression => 'Недопустимое cron выражение';

  @override
  String validCron(Object humanReadable) {
    return 'Допустимое cron выражение: $humanReadable';
  }

  @override
  String validDuration(Object duration) {
    return 'Верная продолжительность: $duration';
  }

  @override
  String get genericNotFound => 'Не удалось найти генеративную информацию, ';

  @override
  String get genericNotFoundDescription =>
      'пожалуйста, сообщите об этом в дискорде Typewriter';

  @override
  String get globalContextKeyEditor_noGlobalKeys =>
      'Ни у одного расширения нет глобального ключа. Попробуйте использовать ключ записи.';

  @override
  String itemEditor_invalidShape(Object path) {
    return 'Форма поля элемента не является алгебраической схемой: $path';
  }

  @override
  String itemEditor_itemFieldNotMap(Object path) {
    return 'Значение для сериализованного поля элемента не является мапой: $path';
  }

  @override
  String get itemEditor_noItemCaptured =>
      'Вы не захватили элемент. Нажмите на синюю иконку камеры, чтобы захватить элемент, который вы держите в игре.';

  @override
  String get itemEditor_itemIsCaptured =>
      'Этот элемент был захвачен в игре. Если вы хотите изменить его, вы можете повторно захватить другой предмет.';

  @override
  String noElementsFound(Object name) {
    return 'Не найдено $name';
  }

  @override
  String get mapEditor_keyAlreadyExistsTitle => 'Ключ уже существует';

  @override
  String mapEditor_keyAlreadyExistsContent(Object key) {
    return 'Ключ \'$key\' уже существует.\nЭто приведет к удалению всех данных из существующего ключа.\nВы уверены, что хотите заменить его?';
  }

  @override
  String materialNotAvailable(Object version) {
    return 'Недоступно на серверах версии $version';
  }

  @override
  String numberEditorMinError(Object min) {
    return 'Значение должно быть не меньше $min';
  }

  @override
  String numberEditorMaxError(Object max) {
    return 'Значение должно быть не больше $max';
  }

  @override
  String get invalidSubfield =>
      'Недопустимое подполе, попробуйте перезапустить сервер';

  @override
  String couldNotWireBlueprint(Object bpId) {
    return 'Не удалось связать чертеж \$$bpId с нодой, сообщите об этом в дискорде Typewriter!';
  }

  @override
  String couldNotWireEntry(Object baseEntryId, Object targetEntryId) {
    return 'Не удалось связать ноду \$$baseEntryId с целевой нодой \$$targetEntryId, сообщите об этом в дискорде Typewriter!';
  }

  @override
  String couldNotReplaceEntry(Object baseEntryId, Object targetEntryId) {
    return 'Не удалось заменить ноду \$$baseEntryId на \$$targetEntryId, сообщите об этом в дискорде Typewriter!';
  }

  @override
  String dataBlueprintMismatch(Object path) {
    return 'Чертеж данных для пути $path не совпадает';
  }

  @override
  String pathNotAListWhileBlueprintRequiresAList(Object path) {
    return 'Путь $path не является списком, в то время как чертеж требует списка';
  }

  @override
  String pathNotAMapWhileBlueprintRequiresAMap(Object path) {
    return 'Путь $path не является мапой, в то время как чертеж требует мапу';
  }

  @override
  String noDataBlueprintFound(Object path) {
    return 'Не найден чертеж данных для пути $path';
  }

  @override
  String get blueprintNotCompatibleWithGeneric =>
      'Генеративный чертеж записи несовместим с новым чертежом';

  @override
  String get potionEffects => 'Эффекты зелий';

  @override
  String get variableReferenceNotFound =>
      'Не удалось найти ссылку на переменную, ';

  @override
  String get variableReferenceNotFoundReset =>
      'нажмите, чтобы сбросить до значения по умолчанию';
}
