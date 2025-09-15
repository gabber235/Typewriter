import "package:flutter/material.dart" hide PageRoute;
import "package:freezed_annotation/freezed_annotation.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:iconify_flutter_plus/icons/icon_park_solid.dart";
import "package:iconify_flutter_plus/icons/ph.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/app_router.dart";
import "package:typewriter_panel/utils/color_converter.dart";

part "pages.g.dart";
part "pages.freezed.dart";

@freezed
abstract class Page with _$Page {
  const factory Page({
    required String id,
    @JsonKey(name: "name") required String pageName,
    required PageType type,
    @NullableColorConverter() Color? color,
    @Default("") String chapter,
    @Default(0) int priority,
  }) = _Page;

  factory Page.fromJson(Map<String, dynamic> json) => _$PageFromJson(json);
}

enum PageType {
  sequence("trigger", ["triggerable"], Fa6Solid.diagram_project, Colors.blue),
  static("static", [], Ph.push_pin_fill, Colors.deepPurple),
  cinematic("cinematic", [], Fa6Solid.film, Colors.orange),
  manifest(
    "manifest",
    ["manifest", "audience"],
    IconParkSolid.chart_graph,
    Colors.green,
  ),
  ;

  const PageType(this.tag, this.linkingTags, this.icon, this.color);

  final String tag;
  final List<String> linkingTags;
  final String icon;
  final Color color;

  static PageType fromName(String name) {
    return values.firstWhere((type) => name.startsWith(type.tag));
  }
}

@riverpod
class BookPages extends _$BookPages {
  @override
  Future<List<Page>> build(String bookId, String search) async {
    // TODO: Fetch book pages from API or database
    throw UnimplementedError();
  }
}

@riverpod
class Pages extends _$Pages {
  @override
  Future<Page> build(String pageId) async {
    // TODO: Fetch book pages from API or database
    throw UnimplementedError();
  }

  Future<void> changeChapter(String chapter) async {
    // TODO: Update chapter in API or database
    throw UnimplementedError();
  }

  Future<void> changePriority(int priority) async {
    // TODO: Update priority in API or database
    throw UnimplementedError();
  }

  Future<void> renamePage(String name) async {
    /// TODO: Update page name in API or database
    throw UnimplementedError();
  }
}

@riverpod
String? pageId(Ref ref) {
  final routeData = ref.watch(currentRouteDataProvider(RouteRoute.name));
  return routeData?.params.getString("pageId");
}
