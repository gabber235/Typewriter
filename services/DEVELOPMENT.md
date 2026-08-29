# Service development

`services/` is one Gradle multiproject build. `build-logic` and `imprint` are the only included builds because Gradle needs both while configuring normal projects.

## Project ownership

- `protocol` owns generated Kotlin Skir contracts.

- `typewriter-api` owns the shared programming model used by Realm, engines, capabilities, and extensions.

- `typewriter-codegen` owns every Typewriter KSP processor. Every Imprint artifact receives it automatically.

- `service-sdk` owns the supported service identity, organization binding, authentication, messaging, status, and shutdown lifecycle.

- `messaging`, `file-transfer`, and `telemetry` own the supported platform implementations and their deterministic test utilities.

- Loader projects remain separate because their API, core, standalone, Paper, and distribution classpaths differ.

- Engine projects remain separate when they represent an API, runtime artifact, capability artifact, or distinct classpath.

Realm remains one deployable project.

## Verification

Run complete service verification from `services/`:

```shell
./gradlew check ktlintCheck
```

Build canonical development artifacts:

```shell
./gradlew assembleDevelopmentArtifacts
```

Verify the Loader distribution:

```shell
./gradlew :loader-distribution:verifyDistribution
```

Regenerate contracts from the repository root:

```shell
bunx --no-install skir format --ci
bunx --no-install skir gen
```

Never add another nested Gradle root for a normal service project. `services/settings.gradle.kts` rejects it.

## Discovery development

Imprint assembles one canonical manifest for each artifact. KSP processors contribute static metadata and generated module providers. Realm discovery loads only Realm bindings. Execution discovery loads only execution bindings. Each deployment owns an isolated Koin application and classloader.

The conformance extension proves declared type identities, generated prototypes, element descriptors, source part eligibility, generated registrars, generated facets, and engine targeting.

## Runtime status

The Loader and Realm lifecycle contracts remain available. Production Realm assignment for third party services is not implemented. Do not simulate it in `service-sdk`. It requires a complete protocol, backend, authorization, SDK, and test slice.

Production deployment selection and artifact staging are not yet connected to the new discovery package factory. Do not describe local runtime startup as complete until that connection exists.
