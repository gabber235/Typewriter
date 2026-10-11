export type Language = "kotlin" | "dart" | "rust";

export type BindingReference =
  | {
      readonly language: "kotlin";
      readonly packageName: string;
      readonly symbol: string;
    }
  | {
      readonly language: "dart";
      readonly importUri: string;
      readonly symbol: string;
      readonly alias: string;
    }
  | {
      readonly language: "rust";
      readonly absolutePath: string;
    };

export interface MethodNames {
  readonly module: string;
  readonly name: string;
  readonly method: BindingReference;
  readonly requestType: string;
  readonly responseType: string;
  readonly imports?: ReadonlyArray<{
    readonly importUri: string;
    readonly alias: string;
  }>;
}

export interface RecordNames {
  readonly key: string;
  readonly type: string;
  readonly binding?: BindingReference;
  readonly fields: ReadonlyArray<{
    readonly sourceName: string;
    readonly targetName: string;
  }>;
}

export interface LanguageBindings {
  readonly language: Language;
  readonly methods: ReadonlyArray<MethodNames>;
  readonly records: ReadonlyArray<RecordNames>;
}
