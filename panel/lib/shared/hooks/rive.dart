import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:rive/rive.dart";

/// Hook creator for creating and managing a Rive [FileLoader].
///
/// The FileLoader will be disposed automatically when the widget is disposed.
///
/// Example usage:
/// ```dart
/// final fileLoader = useRiveFileLoader.fromAsset(
///   'assets/animation.riv',
///   riveFactory: Factory.rive,
/// );
/// ```
const useRiveFileLoader = _RiveFileLoaderHookCreator();

class _RiveFileLoaderHookCreator {
  const _RiveFileLoaderHookCreator();

  /// Creates a [FileLoader] that loads a Rive file from an asset.
  ///
  /// The [asset] parameter is the asset path to load the Rive file from.
  /// The [riveFactory] parameter determines the renderer to use.
  FileLoader fromAsset(
    String asset, {
    Factory? riveFactory,
    List<Object?>? keys,
  }) {
    return use(
      _RiveFileLoaderHook.fromAsset(
        asset,
        riveFactory: riveFactory ?? Factory.rive,
        keys: keys,
      ),
    );
  }

  /// Creates a [FileLoader] that loads a Rive file from a URL.
  ///
  /// The [url] parameter is the URL to load the Rive file from.
  /// The [riveFactory] parameter determines the renderer to use.
  FileLoader fromUrl(String url, {Factory? riveFactory, List<Object?>? keys}) {
    return use(
      _RiveFileLoaderHook.fromUrl(
        url,
        riveFactory: riveFactory ?? Factory.rive,
        keys: keys,
      ),
    );
  }

  /// Creates a [FileLoader] from an already loaded Rive [File].
  ///
  /// The [file] parameter is the pre-loaded Rive file.
  /// The [riveFactory] parameter determines the renderer to use.
  FileLoader fromFile(File file, {Factory? riveFactory, List<Object?>? keys}) {
    return use(
      _RiveFileLoaderHook.fromFile(
        file,
        riveFactory: riveFactory ?? Factory.rive,
        keys: keys,
      ),
    );
  }
}

enum _FileLoaderSource { asset, url, file }

class _RiveFileLoaderHook extends Hook<FileLoader> {
  const _RiveFileLoaderHook.fromAsset(
    String asset, {
    required this.riveFactory,
    super.keys,
  }) : _source = _FileLoaderSource.asset,
       _asset = asset,
       _url = null,
       _file = null;

  const _RiveFileLoaderHook.fromUrl(
    String url, {
    required this.riveFactory,
    super.keys,
  }) : _source = _FileLoaderSource.url,
       _url = url,
       _asset = null,
       _file = null;

  const _RiveFileLoaderHook.fromFile(
    File file, {
    required this.riveFactory,
    super.keys,
  }) : _source = _FileLoaderSource.file,
       _file = file,
       _asset = null,
       _url = null;

  final _FileLoaderSource _source;
  final String? _asset;
  final String? _url;
  final File? _file;
  final Factory riveFactory;

  @override
  _RiveFileLoaderHookState createState() => _RiveFileLoaderHookState();
}

class _RiveFileLoaderHookState
    extends HookState<FileLoader, _RiveFileLoaderHook> {
  late final FileLoader _fileLoader;

  @override
  void initHook() {
    super.initHook();
    _fileLoader = switch (hook._source) {
      _FileLoaderSource.asset => FileLoader.fromAsset(
        hook._asset!,
        riveFactory: hook.riveFactory,
      ),
      _FileLoaderSource.url => FileLoader.fromUrl(
        hook._url!,
        riveFactory: hook.riveFactory,
      ),
      _FileLoaderSource.file => FileLoader.fromFile(
        hook._file!,
        riveFactory: hook.riveFactory,
      ),
    };
  }

  @override
  FileLoader build(BuildContext context) => _fileLoader;

  @override
  void dispose() {
    _fileLoader.dispose();
    super.dispose();
  }

  @override
  String get debugLabel => "useRiveFileLoader";
}
