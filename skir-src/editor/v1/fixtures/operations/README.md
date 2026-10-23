# Portable operation fixture

One expected result per case. Kotlin and Dart run the same cases. Expected values are written by hand from
`operations.yaml`, never copied from a host.

## Files

| File | Holds |
| --- | --- |
| `operations/<group>.json` | Cases for one operation group of `operations.yaml` (`text`, `number`, ...) |
| `operations/structural.json` | Structural forms, the call rule, budgets and evaluator failures |
| `../portable_pattern_conformance.json` | Pattern expansion and rule outcome cases (see below) |

Each operation file is `{ "cases": [ ... ] }`. Unknown keys fail on both hosts.

## Who runs what

| Host | Runs | Uses `check` |
| --- | --- | --- |
| Kotlin | Cases whose calls are all profile `rule` | Yes |
| Dart | Every case | No |

## Case keys

| Key | Required | Meaning |
| --- | --- | --- |
| `id` | yes | Unique across all files |
| `expression` | yes | Skir readable JSON of `expression.skir:ExpressionNode` |
| `inputs` | no | `{ "<binding>": { "value": <compact value>, "type": <ExpressionType>, "located": true } }` |
| `typeDefinitions` | no | Readable `TypeDefinition` list for the checker and the type facts |
| `resources` | no | `{ "<resource id>": { "configuration": <TypeSelection>, "fields": { "<name>": <compact value> } } }` |
| `budget` | no | `{ "maxSteps": n, "maxCollectionItems": n }`, default 1000 and 1000 |
| `check` | no | Kotlin checker: `{ "resultType", "failures", "inferredType" }` |
| `expected` | yes | Exactly one of `available`, `unavailable`, `failed`, and always `reads` |

### `inputs`

| Field | Default | Meaning |
| --- | --- | --- |
| `value` | | The binding's value (compact) |
| `type` | none | Readable `ExpressionType`; required when the case has `check` |
| `located` | `true` | Located at `ValueLocation(resource = binding id, root path)` |

### `check`

| Field | Meaning |
| --- | --- |
| `resultType` | The slot type the expression is checked against |
| `failures` | Check failure ids; compared as a multiset (order is not part of the contract); `[]` when it checks |
| `inferredType` | Optional; the type the checker infers |

### `expected`

| Field | Meaning |
| --- | --- |
| `available` | The compact value |
| `unavailable` | Compact locations, in collection order, distinct |
| `failed` | A failure id from `failures` or `evaluator_failures` |
| `reads` | Required. Distinct compact locations, in first read order; compared in order |

Every runner compares the outcome and `reads` of every case it runs, and the Kotlin runner compares `check` as described
above. A case without `reads` is invalid.

## Compact values

| Kind | Form |
| --- | --- |
| null, unfilled, unit | `{"null": true}`, `{"unfilled": true}`, `{"unit": true}` |
| boolean | `{"boolean": true}` |
| integer | `{"integer": "7"}` |
| float | `{"float": 1.5}` |
| decimal | `{"decimal": "1.5"}` |
| text | `{"string": "x"}` |
| bytes | `{"bytes": "<base64>"}` |
| timestamp | `{"timestamp": "2024-01-02T03:04:05.000Z"}` |
| duration | `{"duration": "90500"}` (milliseconds) |
| enum case | `{"enum_case": "Floor"}` |
| record | `{"record": {"name": <value>}}` (fields compare as a map) |
| list, set | `{"list": [{"id": "a", "value": <value>}]}`, same for `set` |
| map | `{"map": [{"id": "r1", "key": <value>, "value": <value>}]}` |
| link | `{"link": {"endpoint": "<endpoint>", "resource": "<resource>"}}` |
| named | `{"named": {"declared": "<32 hex>", "revision": 1, "arguments": [<TypeUse>], "payload": <value>}}` |
| named (qualified) | `{"named": {"namespace": "...", "name": "...", "revision": 1, "arguments": [], "payload": <value>}}` |

Item ids are part of the result: list, set and map results compare in order, with their ids.

## Compact locations

The resource id, then path segments.

| Segment | Form | Example |
| --- | --- | --- |
| field | `.name` | `subject.title` |
| item or map row | `[id]` | `subject.tags[a]` |
| map key | `.#key` | `subject.scores[r1].#key` |
| map value | `.#value` | `subject.scores[r1].#value` |

## Coverage (Kotlin test)

| Must appear | Where |
| --- | --- |
| Every operation of `operations.yaml` | In some case's call |
| Every failure an operation declares | As some case's `expected.failed` |
| Every evaluator failure | As some case's `expected.failed`, except `outside_rule_profile` and `unknown_expression` |

Host failures (`host_failures`: authored value reads in Realm and the SDK) never come from an evaluator and need no case.

## Rules these cases pin

Besides the operation docs, the cases fix these evaluator rules.

| Rule | Example case |
| --- | --- |
| A `field` over an `input` reads the projected location, as one input with the joined path | `field_of_input_reads_the_projected_location` |
| A `field` over a computed value that is null, unfilled or lacks the path is missing at no location | `field_of_null_is_missing` |
| `and`, `or` and `conditional` fail `expression_result_not_boolean` on a non boolean operand or test | `and_non_boolean_operand` |
| A missing left operand of `and` or `or` is the result; the right one is not evaluated | `and_missing_left_is_missing` |
| A lambda of the wrong arity, a lambda in a value position, or another node in a lambda position fails `ill_typed_argument` | `lambda_arity_must_match_parameter` |
| Missing locations a call collects are distinct, in collection order | `collection_map_unfilled_entry_location_is_distinct` |
| Operands of different numeric families at runtime fail `ill_typed_argument` | `number_add_mixed_families` |
| An each lambda result of the wrong kind fails `ill_typed_argument` | `collection_filter_non_boolean_predicate` |
| Enum defaults such as `mode = nearest_ties_to_even` are DSL only; the wire carries every argument | `number_round_mode_is_required_on_the_wire` |
| Regex kernels charge at least one step per input position they examine | `regex_find_charges_steps` |
| Locales are BCP 47 tags with hyphens (`en-US`, `und`) | `number_format_english_grouping` |
| Every available call result charges collection items: one per item of a list or set, one per top level row of a map, one per started 64 UTF-16 code units of text and per started 64 bytes; an empty result charges nothing | `budget_text_result_charges_per_started_64_code_units` |
| A short circuit of `and` or `or` is a plain boolean, even when the operand is a named boolean | `or_short_circuit_unwraps_named_boolean` |
| A lambda local bound to a map entry is located at its row; its `key` and `value` are the row's `.#key` and `.#value` | `collection_filter_map_entry_value_is_located_at_row_value` |

## Pattern fixture

`../portable_pattern_conformance.json` is `{ "expansions": [ ... ], "rules": [ ... ] }`. It follows Realm:
`CapturedAuthoringReads.expand` and the portable rule branch of `RealmCheckRuntime`.

### Expansion case

| Key | Meaning |
| --- | --- |
| `id` | Unique in the file |
| `value` | Compact value of the owner resource (its fields as a record) |
| `owner` | Compact location of the owner; the resource root |
| `pattern` | Readable `RelativeFieldPattern` |
| `expected` | Compact locations, in expansion order |

| Step | Yields |
| --- | --- |
| field | The field location, unless the parent value is null (named null included) |
| `items` | List and set items; for a map, each row's key then value |
| `keys`, `values` | Each map row's key, or value |
| any wildcard on a non collection, missing, unfilled or null value | Nothing |

### Rule case

| Key | Meaning |
| --- | --- |
| `id` | Unique in the file |
| `value`, `owner` | As in an expansion case |
| `recipe` | Readable `RelativeFieldPattern`; every location it expands to is one subject |
| `predicate` | Readable `ExpressionNode`; binding `configured_value` is located at the subject |
| `diagnostic` | `{ "code", "message", "severity", "targets": [<RelativeFieldPattern>] }` |
| `expected` | One entry per subject, in expansion order |

Each `expected` entry is `{ "subject": <location>, "outcome": ..., "findings": [ ... ] }`.

| Outcome | Form | When |
| --- | --- | --- |
| finished | `"finished"` | The predicate is a boolean; `false` adds one finding |
| needs input | `{"needs_input": [<location>]}` | The predicate is missing |
| failed | `{"failed": {"failure": "<id>", "primary": <location>, "related": [...]}}` | The predicate failed or is not a boolean |

A finding is `{ "code", "message", "severity", "primary", "related" }`. Its targets: a target equal to the recipe
is the subject; any other expands from the owner. Targets are distinct. The first is `primary`, the rest are
`related`; with no targets the subject is `primary`. A failed outcome's `primary` is the first failure location,
or the subject when there is none. Diagnostic ids and origins are host specific and not compared.
