# Unicode 17.0.0 character data

The portable expression language takes case mapping, case folding, normalization and white space from this one Unicode release, so Realm (Kotlin) and the panel (Dart on the VM and the web) agree on every code point.

These files are unmodified copies of the Unicode Character Database at <https://www.unicode.org/Public/17.0.0/ucd/>:

| File | Used for |
| --- | --- |
| `UnicodeData.txt` | Simple case mappings, canonical combining classes, decompositions |
| `SpecialCasing.txt` | Full case mappings (unconditional entries and Final_Sigma; no language tailoring) |
| `CaseFolding.txt` | Full case folding (statuses C and F) |
| `CompositionExclusions.txt` | Primary composites |
| `PropList.txt` | White_Space |
| `DerivedCoreProperties.txt` | Cased and Case_Ignorable, for the Final_Sigma condition |
| `NormalizationTest.txt` | Normalization conformance tests in Kotlin and Dart |

`services/protocol/skir-gen/src/operations/unicode.ts` turns them into the generated `PortableUnicodeTables` for Kotlin and Dart. Use of the data is subject to the [Unicode License](https://www.unicode.org/license.txt).

Upgrading is a reviewed edit: add the new release as a sibling directory with the same files, point the pinned release at it, regenerate the tables, and review the behavior changes the Kotlin and Dart conformance tests report.
