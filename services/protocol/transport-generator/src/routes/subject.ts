import type { ScopeKind } from "./manifest.js";

/** Identity captures a subject may name, in the order generated code lists them. */
export const PARAMETERS = ["organization", "realm", "service", "user", "transfer_id"] as const;
export type Parameter = (typeof PARAMETERS)[number];

export type SubjectToken =
  | { readonly kind: "literal"; readonly value: string }
  | { readonly kind: "parameter"; readonly parameter: Parameter };

/** Sorts parameters into their canonical order and removes duplicates. */
export function sortedParameters(parameters: Iterable<Parameter>): Parameter[] {
  const present = new Set(parameters);
  return PARAMETERS.filter((parameter) => present.has(parameter));
}

/** The identities each scope binds, in the order generated scope types declare them. */
export function scopeParameters(scope: ScopeKind): readonly Parameter[] {
  switch (scope) {
    case "realm":
      return ["organization", "realm"];
    case "service":
      return ["service"];
    case "bound_service":
      return ["service", "organization"];
    case "organization_actor":
      return ["organization", "user"];
    case "organization":
      return ["organization"];
    case "user":
      return ["user"];
    case "native":
    case "internal_component":
      return [];
  }
}

/**
 * A concrete subject shape with named identity captures, never authored broker wildcards. Parsing
 * validates tokens and capture uniqueness. Scope admission is separate: request endpoints require
 * every scope identity, while event and update endpoints may use a subset. Bounded updates also
 * require a final transfer capture; grant emission decides when it becomes a wildcard.
 */
export class SubjectTemplate {
  private constructor(readonly tokens: readonly SubjectToken[]) {}

  /** Parses a dotted subject such as `cloud.to.user.{user}.watch`; throws on invalid tokens. */
  static parse(value: string): SubjectTemplate {
    const seen = new Set<Parameter>();
    const tokens = value.split(".").map((part): SubjectToken => {
      const parameter = PARAMETERS.find((candidate) => part === `{${candidate}}`);
      if (parameter) {
        if (seen.has(parameter)) {
          throw new Error(`repeated subject parameter ${part}`);
        }
        seen.add(parameter);
        return { kind: "parameter", parameter };
      }
      if (part.length === 0 || /[\s*>{}]/u.test(part)) {
        throw new Error(`invalid subject token ${JSON.stringify(part)}`);
      }
      return { kind: "literal", value: part };
    });
    return new SubjectTemplate(tokens);
  }

  /** Whether the subject captures the given identity. */
  has(parameter: Parameter): boolean {
    return this.tokens.some((token) => token.kind === "parameter" && token.parameter === parameter);
  }

  /** The captured identities in canonical order. */
  parameters(): Parameter[] {
    return sortedParameters(
      this.tokens.flatMap((token) => (token.kind === "parameter" ? [token.parameter] : [])),
    );
  }

  /**
   * Admits a subject whose captures are a subset of the scope identities. A transfer capture is
   * valid only as the final token of a bounded update, which must end in one.
   */
  validateScope(scope: ScopeKind, transfer: boolean): void {
    const allowed = scopeParameters(scope);
    this.tokens.forEach((token, index) => {
      if (token.kind !== "parameter") {
        return;
      }
      if (token.parameter === "transfer_id") {
        if (!transfer || index + 1 !== this.tokens.length) {
          throw new Error("transfer_id is valid only as the final bounded update token");
        }
      } else if (!allowed.includes(token.parameter)) {
        throw new Error(`subject parameter ${token.parameter} is absent from ${scope} scope`);
      }
    });
    const last = this.tokens.at(-1);
    if (transfer && !(last?.kind === "parameter" && last.parameter === "transfer_id")) {
      throw new Error("bounded updates must end in transfer_id");
    }
  }

  /** Admits a request subject, which must capture every identity of its scope. */
  validateRequestScope(scope: ScopeKind): void {
    this.validateScope(scope, false);
    for (const parameter of scopeParameters(scope)) {
      if (!this.has(parameter)) {
        throw new Error(
          `request subject is missing required ${parameter} parameter for ${scope} scope`,
        );
      }
    }
  }

  toString(): string {
    return this.tokens
      .map((token) => (token.kind === "literal" ? token.value : `{${token.parameter}}`))
      .join(".");
  }
}
