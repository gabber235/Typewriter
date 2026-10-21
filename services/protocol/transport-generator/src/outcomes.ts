import type { CodeGenerator, Field, Method, Module, RecordLocation, Token } from "skir-internal";

/**
 * Outcome classification of Skir responses. The variant name is the single source: every emitter
 * renders the result of {@link classifyVariant}, so Kotlin, Rust and the panel classify a response
 * the same way. The generated unknown variant of every enum is an internal error.
 */
export type Outcome = "success" | "domain_error" | "internal_error";

/** The variant every request response replies with when its handler fails. */
export const INTERNAL_ERROR_VARIANT = "internal_error";

/** The Skir record that every internal_error variant carries. */
const INTERNAL_ERROR_RECORD = { modulePath: "kernel/v1/errors.skir", name: "InternalError" } as const;

/**
 * Classifies one response variant by its Skir name: internal_error is internal, a name ending in
 * `_error` is a domain error and any other name is a success.
 */
export function classifyVariant(variant: Field): Outcome {
  const name = variant.name.text;
  if (name === INTERNAL_ERROR_VARIANT) {
    return "internal_error";
  }
  return name.endsWith("_error") ? "domain_error" : "success";
}

/** The telemetry slug of a variant: its Skir name in kebab case, such as `service-not-found-error`. */
export function variantSlug(variant: Field): string {
  return variant.name.text.replaceAll("_", "-");
}

/** The telemetry slug of the generated unknown variant every enum has. */
export const UNKNOWN_SLUG = "unknown";

/**
 * The caller facing message of a variant: its doc comment on one line, or its slug when the variant
 * is undocumented. Payloads never contribute, so messages carry no request data.
 */
export function variantMessage(variant: Field): string {
  const text = variant.doc.text.replace(/\s+/gu, " ").trim();
  return text === "" ? variantSlug(variant) : text;
}

/** One classified variant of a response enum. */
export interface OutcomeVariant {
  readonly field: Field;
  readonly outcome: Outcome;
  readonly slug: string;
  readonly message: string;
}

/** A response enum whose variants classify outcomes and whose internal_error is the fallback reply. */
export interface OutcomeResponse {
  readonly location: RecordLocation;
  /** Every declared variant in declaration order; the generated unknown variant is not listed. */
  readonly variants: readonly OutcomeVariant[];
  /** The internal_error variant. */
  readonly internalError: Field;
  /** The `kernel/v1/errors.skir:InternalError` record the internal_error variant carries. */
  readonly internalErrorPayload: RecordLocation;
}

/** A response that cannot carry typed outcomes, with the Skir token to report it at. */
export class OutcomeAdmissionError extends Error {
  override readonly name = "OutcomeAdmissionError";

  constructor(
    message: string,
    readonly token: Token,
  ) {
    super(message);
  }
}

/** Formats a Skir token as `module.skir:line:column`, both one based. */
export function skirPosition(token: Token): string {
  return `${token.line.modulePath}:${token.line.lineNumber + 1}:${token.colNumber + 1}`;
}

/**
 * Admits a response record: it must be an enum with an `internal_error: InternalError` variant of
 * `kernel/v1/errors.skir`, which the transports reply with when a handler fails.
 */
export function outcomeResponse(
  location: RecordLocation,
  recordMap: CodeGenerator.Input<unknown>["recordMap"],
): OutcomeResponse {
  const { record } = location;
  const name = record.name.text;
  if (record.recordType !== "enum") {
    throw new OutcomeAdmissionError(`${name} must be an enum with internal_error: InternalError`, record.name);
  }
  const internalError = record.fields.find((field) => field.name.text === INTERNAL_ERROR_VARIANT);
  const payload =
    internalError?.type?.kind === "record" ? recordMap.get(internalError.type.key) : undefined;
  if (
    !internalError ||
    payload?.modulePath !== INTERNAL_ERROR_RECORD.modulePath ||
    payload.record.name.text !== INTERNAL_ERROR_RECORD.name
  ) {
    throw new OutcomeAdmissionError(`${name} lacks internal_error: InternalError`, record.name);
  }
  const variants = record.fields.map(
    (field): OutcomeVariant => ({
      field,
      outcome: classifyVariant(field),
      slug: variantSlug(field),
      message: variantMessage(field),
    }),
  );
  return { location, variants, internalError, internalErrorPayload: payload };
}

/** The response enum of one Skir method with its classified variants. */
export interface MethodResponse {
  readonly module: Module;
  readonly method: Method;
  readonly response: OutcomeResponse;
}

/**
 * Every method response enum of the Skir input, including methods no transport route serves such
 * as HTTP only methods, each response record once in module path order. Struct responses carry
 * no outcome and are
 * skipped; an enum without internal_error fails the generation with its method and position.
 */
export function methodResponses(input: CodeGenerator.Input<unknown>): MethodResponse[] {
  const seen = new Set<string>();
  // Skir hands modules over in collection order, which varies between runs; module paths keep
  // the output stable.
  const modules = [...input.modules].sort((left, right) =>
    left.path < right.path ? -1 : left.path > right.path ? 1 : 0,
  );
  return modules.flatMap((module) =>
    module.methods.flatMap((method): MethodResponse[] => {
      const type = method.responseType;
      const location = type?.kind === "record" ? input.recordMap.get(type.key) : undefined;
      if (!location || location.record.recordType !== "enum" || seen.has(location.record.key)) {
        return [];
      }
      seen.add(location.record.key);
      try {
        return [{ module, method, response: outcomeResponse(location, input.recordMap) }];
      } catch (error) {
        if (error instanceof OutcomeAdmissionError) {
          throw new Error(
            `method ${module.path}:${method.name.text}: ${error.message} (Skir ${skirPosition(error.token)})`,
          );
        }
        throw error;
      }
    }),
  );
}
