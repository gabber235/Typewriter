/// Public Skir boundary for panel protocol models and domain codecs.
///
/// Generated wire declarations are re exported for transport use, while
/// handwritten codecs and converters keep those declarations away from most
/// application code. The generated tree is not edited here.
library;

export "converters.dart";
export "editor_codec.dart";
export "skirout/access/v1/permission.dart";
export "skirout/access/v1/sentinel.dart";
export "skirout/editor/v1/action.dart";
export "skirout/editor/v1/authoring.dart";
export "skirout/editor/v1/binding.dart";
export "skirout/editor/v1/capability.dart";
export "skirout/editor/v1/catalog.dart";
export "skirout/editor/v1/catalog_presentation.dart";
export "skirout/editor/v1/compiled_content.dart";
export "skirout/editor/v1/conversion.dart";
export "skirout/editor/v1/diagnostic.dart";
export "skirout/editor/v1/element_catalog.dart";
export "skirout/editor/v1/expression.dart";
export "skirout/editor/v1/page_catalog.dart"
    hide PageDiagnostic, PageDiagnostic_mutable, PageDiagnostic_orMutable;
export "skirout/editor/v1/path.dart";
export "skirout/editor/v1/presentation.dart";
export "skirout/editor/v1/search.dart";
export "skirout/editor/v1/type_catalog.dart";
export "skirout/editor/v1/typed_value.dart";
export "skirout/kernel/v1/color.dart";
export "skirout/kernel/v1/duration.dart";
export "skirout/kernel/v1/errors.dart";
export "skirout/kernel/v1/icon.dart";
export "skirout/kernel/v1/page_kind.dart";
export "skirout/kernel/v1/record_id.dart";
export "skirout/organization/v1/join_codes.dart";
export "skirout/organization/v1/join_request.dart";
export "skirout/organization/v1/member.dart";
export "skirout/organization/v1/organization.dart";
export "skirout/organization/v1/presence.dart";
export "skirout/organization/v1/role.dart";
export "skirout/organization/v1/user.dart";
export "skirout/service/v1/artifact.dart";
export "skirout/service/v1/identity.dart";
export "skirout/service/v1/lifecycle.dart";
export "skirout/service/v1/organization.dart";
export "skirout/service/v1/registration.dart";
export "skirout/service/v1/service.dart";
export "skirout/service/v1/status.dart";
export "skirout/service/v1/topology.dart";
