"""Embed fixtures emitted by the real Kotlin catalog assembly test."""
import argparse
import base64
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("directory", type=Path)
args = parser.parse_args()
target = Path(__file__).resolve().parents[1] / "lib/src/app/compiled_sdk_control_fixture.dart"
lines = [
    'import "dart:convert";',
    '',
    'import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart" as skir;',
    '',
    '/// Actual SDK material emitted by FrameworkCatalogCreationTest and DefaultPresentationRuntimeTest.',
    '/// Regenerate with TYPEWRITER_CONTROL_FIXTURE_DIR and this fixture tool.',
]
for name, wire_type, file_name in [
    ("compiledSdkControlCatalog", "EditorCatalogWireSnapshot", "catalog.bin"),
    ("compiledSdkTagRecord", "AuthoringRecord", "tag.bin"),
    ("compiledSdkTagValue", "DataValue", "tag-value.bin"),
    ("compiledSdkBookRecord", "AuthoringRecord", "book.bin"),
    ("compiledSdkBookValue", "DataValue", "book-value.bin"),
    ("compiledSdkPlacementValue", "DataValue", "placement.bin"),
    ("compiledSdkElementValue", "DataValue", "element-value.bin"),
    ("compiledSdkCompositeLayout", "PresentationNode", "composite-layout.bin"),
    ("compiledSdkCompositeValue", "DataValue", "composite-value.bin"),
    ("compiledSdkTypedLayout", "PresentationNode", "typed-layout.bin"),
    ("compiledSdkTypedValue", "DataValue", "typed-value.bin"),
    ("compiledSdkNullableLayout", "PresentationNode", "nullable-layout.bin"),
    ("compiledSdkNullableValue", "DataValue", "nullable-value.bin"),
    ("compiledSdkNestedRemainderLayout", "PresentationNode", "nested-remainder-layout.bin"),
    ("compiledSdkNestedRemainderCatalog", "EditorCatalogWireSnapshot", "nested-remainder-catalog.bin"),
]:
    data = base64.b64encode((args.directory / file_name).read_bytes()).decode()
    lines.append(f"final {name} = skir.{wire_type}.serializer.fromBytes(base64Decode(")
    for index in range(0, len(data), 100):
        lines.append(f'  "{data[index:index + 100]}"')
    lines.append("));")
    lines.append("")
target.write_text("\n".join(lines))
