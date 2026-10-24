import type { CodeGenerator } from "skir-internal";

import { UNKNOWN_SLUG, type MethodResponse, type Outcome } from "../../outcomes.js";
import { rustDefaultVariant } from "../../symbols.js";

const OUTCOME: Record<Outcome, string> = {
  success: "crate::SkirResponseOutcome::Success",
  domain_error: "crate::SkirResponseOutcome::DomainError",
  internal_error: "crate::SkirResponseOutcome::InternalError",
};

/** A Rust string literal; JSON escaping yields valid Rust escapes for the text Skir docs contain. */
function literal(value: string): string {
  return JSON.stringify(value);
}

/**
 * Emits `impl crate::SkirResponse` for one method response enum. Outcomes follow the variant names;
 * internal_error and the generated unknown variant are internal. Messages come from variant doc
 * comments, never from payloads. Every domain error variant can be built from its slug with a
 * default payload, which `skir_domain_result!` uses for database rejections. Serialization is the
 * trait default over the record's `crate::SkirType` implementation.
 */
function emitResponse(
  { response }: MethodResponse,
  symbols: CodeGenerator.SymbolProvider,
): string[] {
  const { location, variants, internalError } = response;
  const pattern = (field: (typeof variants)[number]["field"]) =>
    symbols.variant(location, field).reference;
  const known = variants.filter(({ outcome }) => outcome !== "internal_error");
  const outcomeArms = (["success", "domain_error"] as const).flatMap((outcome) => {
    const patterns = known.filter((variant) => variant.outcome === outcome).map((variant) => pattern(variant.field));
    return patterns.length === 0 ? [] : [`            ${patterns.join(" | ")} => ${OUTCOME[outcome]},`];
  });
  const documented = variants.filter(({ message, slug }) => message !== slug);
  const domainErrors = variants.filter(({ outcome }) => outcome === "domain_error");
  return [
    `impl crate::SkirResponse for ${symbols.record(location).reference} {`,
    "    fn outcome(&self) -> crate::SkirResponseOutcome {",
    ...(outcomeArms.length === 0
      ? [`        ${OUTCOME.internal_error}`]
      : [
          "        match self {",
          ...outcomeArms,
          "            // internal_error and the generated unknown variant",
          `            _ => ${OUTCOME.internal_error},`,
          "        }",
        ]),
    "    }",
    "    fn variant_slug(&self) -> &'static str {",
    "        match self {",
    ...variants.map(({ field, slug }) => `            ${pattern(field)} => ${literal(slug)},`),
    `            _ => ${literal(UNKNOWN_SLUG)},`,
    "        }",
    "    }",
    "    fn variant_message(&self) -> String {",
    ...(documented.length === 0
      ? ["        self.variant_slug().to_owned()"]
      : [
          "        match self {",
          ...documented.map(({ field, message }) => `            ${pattern(field)} => ${literal(message)}.to_owned(),`),
          "            other => other.variant_slug().to_owned(),",
          "        }",
        ]),
    "    }",
    "    fn internal_error() -> Self {",
    `        ${rustDefaultVariant(symbols, location, internalError)}`,
    "    }",
    ...(domainErrors.length === 0
      ? []
      : [
          "    fn domain_error_from_slug(slug: &str) -> Option<Self> {",
          "        match slug {",
          ...domainErrors.map(
            ({ field, slug }) => `            ${literal(slug)} => Some(${rustDefaultVariant(symbols, location, field)}),`,
          ),
          "            _ => None,",
          "        }",
          "    }",
        ]),
    "}",
  ];
}

/**
 * Emits the `crate::SkirResponse` implementations of every method response enum, including methods
 * served outside the transport routes, so every response classifies the same way.
 */
export function emitResponses(
  responses: readonly MethodResponse[],
  symbols: CodeGenerator.SymbolProvider,
): string[] {
  return responses.flatMap((response) => emitResponse(response, symbols));
}
