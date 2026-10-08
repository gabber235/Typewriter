/// Public Skir boundary for panel protocol models and domain codecs.
///
/// Import this library as `skir` so protocol names stay distinct from panel and
/// Flutter names. It exposes generated declarations, serializers, and primitive
/// converters used at protocol boundaries. The generated tree is not edited.
library;

import "skirout/editor/v1/authoring.dart"
    show ArgumentLocation, ArgumentLocation_mutable, ArgumentLocation_orMutable;

export "package:skir_client/skir_client.dart" hide EnumVariant, Service;

export "converters.dart";
export "skirout/access/v1/permission.dart";
export "skirout/access/v1/sentinel.dart";
export "skirout/editor/v1/action.dart";
export "skirout/editor/v1/authoring.dart"
    hide ArgumentLocation, ArgumentLocation_mutable, ArgumentLocation_orMutable;
export "skirout/editor/v1/authoring_facts.dart";
export "skirout/editor/v1/binding.dart";
export "skirout/editor/v1/capability.dart";
export "skirout/editor/v1/catalog.dart";
export "skirout/editor/v1/catalog_presentation.dart";
export "skirout/editor/v1/checking.dart";
export "skirout/editor/v1/compiled_content.dart";
export "skirout/editor/v1/conversion.dart";
export "skirout/editor/v1/diagnostic.dart";
export "skirout/editor/v1/expression.dart";
export "skirout/editor/v1/presentation.dart";
export "skirout/editor/v1/publication.dart";
export "skirout/editor/v1/search.dart";
export "skirout/editor/v1/type_catalog.dart";
export "skirout/editor/v1/typed_value.dart";
export "skirout/kernel/v1/bounded_transfer.dart";
export "skirout/kernel/v1/color.dart";
export "skirout/kernel/v1/duration.dart";
export "skirout/kernel/v1/errors.dart";
export "skirout/kernel/v1/icon.dart";
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

/// Authoring argument placement, distinct from diagnostic argument locations.
typedef AuthoringArgumentLocation = ArgumentLocation;
typedef AuthoringArgumentLocationMutable = ArgumentLocation_mutable;
typedef AuthoringArgumentLocationOrMutable = ArgumentLocation_orMutable;
