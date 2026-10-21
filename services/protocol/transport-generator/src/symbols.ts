import { GENERATOR as DART_GENERATOR } from "skir-dart-gen";
import { GENERATOR as KOTLIN_GENERATOR } from "skir-kotlin-gen";
import type { CodeGenerator } from "skir-internal";
import { GENERATOR as RUST } from "skir-rust-gen";

import type { Config } from "./config.js";

/**
 * skir-kotlin-gen and skir-dart-gen still declare their types against skir-internal 0.1.1, whose
 * model types TypeScript does not relate to the 0.2.21 ones the compiler uses. The compiler hands
 * every generator the same model, so both are typed through the current contract.
 *
 * TODO: drop once both generators depend on skir-internal 0.2.
 */
const KOTLIN = KOTLIN_GENERATOR as unknown as CodeGenerator<{ packagePrefix?: string }>;
const DART = DART_GENERATOR as unknown as CodeGenerator<{ importUriPrefix?: string }>;

/** The symbol provider of each language generator whose output the transport routes reference. */
export interface SymbolProviders {
  readonly kotlin: CodeGenerator.SymbolProvider;
  readonly dart: CodeGenerator.SymbolProvider;
  readonly rust: CodeGenerator.SymbolProvider;
}

/**
 * Obtains each language's provider from the Skir generator it describes, with the config skir.yml
 * gives that generator. This is the only naming code: emitters reference Skir declarations through
 * these providers and never spell a generated name themselves. Each provider is created on first
 * use, so a target only needs the config of the languages it references.
 */
export function symbolProviders(input: CodeGenerator.Input<Config>): SymbolProviders {
  const forGenerator = <C>(generator: CodeGenerator<C>, config: C) => {
    if (!generator.symbols) {
      throw new Error(`${generator.id} does not describe its symbols`);
    }
    return generator.symbols({ ...input, config });
  };
  let kotlin: CodeGenerator.SymbolProvider | undefined;
  let dart: CodeGenerator.SymbolProvider | undefined;
  let rust: CodeGenerator.SymbolProvider | undefined;
  return {
    get kotlin() {
      return (kotlin ??= forGenerator(KOTLIN, {}));
    },
    get dart() {
      return (dart ??= forGenerator(DART, { importUriPrefix: input.config.dartImportUriPrefix }));
    },
    get rust() {
      return (rust ??= forGenerator(RUST, {}));
    },
  };
}

/**
 * Splits a fully qualified Kotlin reference into the import that brings it into scope and its
 * simple name, so generated files keep importing top level method descriptors.
 */
export function importedKotlinSymbol(symbol: CodeGenerator.Symbol): {
  readonly name: string;
  readonly imports: readonly string[];
} {
  const name = symbol.reference.slice(symbol.reference.lastIndexOf(".") + 1);
  return { name, imports: [...symbol.imports, `import ${symbol.reference}`] };
}
