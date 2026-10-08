import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

extension type const PageAuthoringSelectionKey(String value) {
  factory PageAuthoringSelectionKey.page(skir.ResourceId page) =>
      PageAuthoringSelectionKey("page:${page.value}");

  static PageAuthoringSelectionKey? parse(String value) =>
      value.startsWith("page:") ? PageAuthoringSelectionKey(value) : null;

  skir.ResourceId get page =>
      skir.ResourceId(value: value.substring("page:".length));
}

extension type const PageContentSelectionKey(String value) {
  factory PageContentSelectionKey.page(
    skir.ResourceId page,
    CatalogGeneration generation,
  ) => PageContentSelectionKey(
    "page-content:${base64Url.encode(utf8.encode(page.value))}:${generation.value}",
  );

  static PageContentSelectionKey? parse(String value) =>
      value.startsWith("page-content:") ? PageContentSelectionKey(value) : null;

  skir.ResourceId get page => skir.ResourceId(
    value: utf8.decode(base64Url.decode(value.split(":")[1])),
  );
}
