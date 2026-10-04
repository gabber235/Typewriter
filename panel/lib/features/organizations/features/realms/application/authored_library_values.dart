import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/authoring.dart"
    as authoring;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/shared/editors/application/portable_value_tree.dart";

final class AuthoredBookValue {
  const AuthoredBookValue({
    required this.id,
    required this.title,
    required this.icon,
    required this.argb,
    required this.tags,
  });

  final types.ResourceId id;
  final String title;
  final String icon;
  final int argb;
  final List<types.ResourceId> tags;
}

final class AuthoredTagValue {
  const AuthoredTagValue({
    required this.id,
    required this.name,
    required this.argb,
    required this.parents,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final types.ResourceId id;
  final String name;
  final int argb;
  final List<types.ResourceId> parents;
  final int x;
  final int y;
  final int width;
  final int height;
}

final class AuthoredPageValue {
  const AuthoredPageValue({
    required this.id,
    required this.configuration,
    required this.book,
    required this.name,
    required this.chapter,
    required this.priority,
    required this.elements,
  });

  final types.ResourceId id;
  final types.TypeSelection configuration;
  final types.ResourceId? book;
  final String name;
  final String chapter;
  final int priority;
  final List<types.ResourceId> elements;
}

AuthoredBookValue decodeAuthoredBook(authoring.AuthoringResource resource) {
  final title = resource.content.authoredField("title")?.authoredString;
  final iconValue = resource.content.authoredField("icon");
  final icon =
      iconValue?.authoredField("value")?.authoredString ??
      iconValue?.authoredField("source")?.authoredString;
  final color = resource.content.authoredField("color")?.authoredInteger;
  final tagIds =
      (resource.content.authoredField("tags")?.authoredItems ??
              const <types.ListItem>[])
          .map((item) => item.value.authoredLink?.target.resource)
          .nonNulls
          .toList(growable: false);
  return AuthoredBookValue(
    id: resource.id,
    title: _displayLabel(title, "Unnamed Book"),
    icon: _displayLabel(icon, "material-symbols:book"),
    argb: (color ?? BigInt.from(0xff3f51b5)).toUnsigned(32).toInt(),
    tags: tagIds,
  );
}

AuthoredTagValue decodeAuthoredTag(authoring.AuthoringResource resource) {
  final name = resource.content.authoredField("name")?.authoredString;
  final color = resource.content.authoredField("color")?.authoredInteger;
  final parentIds =
      (resource.content.authoredField("parents")?.authoredItems ??
              const <types.ListItem>[])
          .map((item) => item.value.authoredLink?.target.resource)
          .nonNulls
          .toList(growable: false);
  final placement = resource.content.authoredField("placement");
  final x = placement?.authoredField("x")?.authoredInteger;
  final y = placement?.authoredField("y")?.authoredInteger;
  final width = placement?.authoredField("width")?.authoredInteger;
  final height = placement?.authoredField("height")?.authoredInteger;
  return AuthoredTagValue(
    id: resource.id,
    name: _displayLabel(name, "Unnamed Tag"),
    argb: (color ?? BigInt.from(0xff9e9e9e)).toUnsigned(32).toInt(),
    parents: parentIds,
    x: x?.toInt() ?? 0,
    y: y?.toInt() ?? 0,
    width: width == null || width < BigInt.one ? 1 : width.toInt(),
    height: height == null || height < BigInt.one ? 1 : height.toInt(),
  );
}

AuthoredPageValue decodeAuthoredPage(authoring.AuthoringResource resource) {
  final book = resource.content.authoredField("book")?.authoredLink;
  final name = resource.content.authoredField("name")?.authoredString;
  final chapter = resource.content.authoredField("chapter")?.authoredString;
  final priority = resource.content.authoredField("priority")?.authoredInteger;
  final elementIds =
      (resource.content.authoredField("elements")?.authoredItems ??
              const <types.ListItem>[])
          .map((item) => item.value.authoredLink?.target.resource)
          .nonNulls
          .toList(growable: false);
  return AuthoredPageValue(
    id: resource.id,
    configuration: resource.content.configuration,
    book: book?.target.resource,
    name: _displayLabel(name, "Unnamed Page"),
    chapter: chapter ?? "",
    priority: priority?.toInt() ?? 0,
    elements: elementIds,
  );
}

String _displayLabel(String? value, String fallback) =>
    value == null || value.trim().isEmpty ? fallback : value;
