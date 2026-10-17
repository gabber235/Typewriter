/// Runtime libraries shared by every panel consumer.
///
/// Colliding vendor types have explicit names so the main panel library can
/// expose one unambiguous namespace. Skir remains a separate named import.
library;

import "dart:async" show AsyncError, Future;

import "package:http/http.dart" show read;
import "package:nats_core/nats_core.dart"
    show
        NatsClosed,
        NatsConnected,
        NatsConnecting,
        NatsMessage,
        NatsReconnecting,
        NatsSubscription;
import "package:petitparser/petitparser.dart" show Parser, any, anyOf;
import "package:responsive_framework/responsive_framework.dart" show Breakpoint;
import "package:rive/rive.dart" show Factory, File;

export "dart:async" hide AsyncError;
export "dart:collection";
export "dart:convert";
export "dart:io" if (dart.library.js_interop) "dependencies_io_stub.dart";
export "dart:math";
export "dart:typed_data";
export "dart:ui"
    hide
        Codec,
        FrameCallback,
        Gradient,
        Image,
        ImageDecoderCallback,
        StrutStyle,
        TextStyle,
        decodeImageFromList;

export "package:auto_route/auto_route.dart"
    hide
        CupertinoFullscreenDialogTransition,
        CupertinoPageTransition,
        kCupertinoModalBarrierColor;
export "package:auto_size_text/auto_size_text.dart";
export "package:clock/clock.dart";
export "package:collection/collection.dart"
    hide UnmodifiableSetView, binarySearch, mergeSort;
export "package:crypto/crypto.dart";
export "package:dart_casing/dart_casing.dart";
export "package:dartastic_opentelemetry/dartastic_opentelemetry.dart"
    hide Client, Service, View;
export "package:dotted_border/dotted_border.dart";
export "package:duration/duration.dart";
export "package:expandable_page_view/expandable_page_view.dart";
export "package:flutter/cupertino.dart" hide Page, RefreshCallback, Title;
export "package:flutter/foundation.dart";
export "package:flutter/gestures.dart";
export "package:flutter/material.dart" hide Page, SearchController, Title;
export "package:flutter/rendering.dart" hide Selectable;
export "package:flutter/scheduler.dart";
export "package:flutter/semantics.dart";
export "package:flutter/services.dart";
export "package:flutter/widgets.dart" hide Page, Title;
export "package:flutter_animate/flutter_animate.dart";
export "package:flutter_hooks/flutter_hooks.dart";
export "package:flutter_markdown_plus/flutter_markdown_plus.dart";
export "package:flutter_reorderable_grid_view/widgets/widgets.dart";
export "package:freezed_annotation/freezed_annotation.dart";
export "package:hooks_riverpod/hooks_riverpod.dart";
export "package:hooks_riverpod/legacy.dart";
export "package:hooks_riverpod/misc.dart";
export "package:http/http.dart" hide read;
export "package:iconify_flutter_plus/icons/bi.dart";
export "package:iconify_flutter_plus/icons/fa6_solid.dart";
export "package:iconify_flutter_plus/icons/heroicons_solid.dart";
export "package:iconify_flutter_plus/icons/ic.dart";
export "package:iconify_flutter_plus/icons/ion.dart";
export "package:iconify_flutter_plus/icons/lucide.dart";
export "package:iconify_flutter_plus/icons/material_symbols.dart";
export "package:iconify_flutter_plus/icons/mingcute.dart";
export "package:iconify_flutter_plus/icons/ph.dart";
export "package:intl/intl.dart" hide TextDirection;
export "package:jovial_svg/jovial_svg.dart";
export "package:json_annotation/json_annotation.dart";
export "package:json_path/json_path.dart";
export "package:localstorage/localstorage.dart";
export "package:material_color_utilities/material_color_utilities.dart"
    hide Direction;
export "package:nats_core/nats_core.dart"
    hide
        NatsClosed,
        NatsConnected,
        NatsConnecting,
        NatsMessage,
        NatsReconnecting,
        NatsSubscription;
export "package:nats_jetstream/nats_jetstream.dart";
export "package:oidc/oidc.dart";
export "package:oidc_default_store/oidc_default_store.dart";
export "package:okcolor/models/extensions.dart";
export "package:petitparser/debug.dart";
export "package:petitparser/petitparser.dart"
    hide Context, any, anyOf, epsilon, ref;
export "package:pub_semver/pub_semver.dart";
export "package:responsive_framework/responsive_framework.dart" hide Breakpoint;
export "package:rive/rive.dart"
    hide
        Animation,
        Factory,
        File,
        PaintingStyle,
        PathFillType,
        RenderImage,
        RiveSemanticsMixin,
        RiveSemanticsWidget;
export "package:riverpod/misc.dart";
export "package:riverpod/riverpod.dart";
// Generated Riverpod parts require the annotation library support types.
// ignore: invalid_export_of_internal_element
export "package:riverpod_annotation/riverpod_annotation.dart";
export "package:rxdart/rxdart.dart";
export "package:searchlight/searchlight.dart" hide SearchResult;
export "package:url_launcher/url_launcher.dart";
export "package:uuid/uuid.dart";
export "package:vector_math/vector_math_64.dart" hide Colors;

typedef SdkAsyncError = AsyncError;

typedef CoreNatsClosed = NatsClosed;

typedef CoreNatsConnected = NatsConnected;

typedef CoreNatsConnecting = NatsConnecting;

typedef CoreNatsReconnecting = NatsReconnecting;

typedef CoreNatsMessage = NatsMessage;

typedef CoreNatsSubscription = NatsSubscription;

typedef ResponsiveBreakpoint = Breakpoint;

typedef RiveFactory = Factory;

typedef RiveFile = File;

/// Matches one of the supplied characters in a query parser.
const Parser<String> Function(
  String chars, {
  String? message,
  bool ignoreCase,
  bool unicode,
})
anyOfCharacters = anyOf;

/// Matches a single character in a query parser.
const Parser<String> Function({String message, bool unicode}) anyCharacter =
    any;

/// Reads an HTTP response without colliding with provider read methods.
const Future<String> Function(Uri url, {Map<String, String>? headers})
httpRead = read;
