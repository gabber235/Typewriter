# Service development

The services composite contains the current Kotlin implementation. Its builds are independent Gradle roots composed through `services/settings.gradle.kts`.

## Verification

Run the complete service verification from `services`:

```shell
build-logic/gradlew check
```

Run Kotlin formatting checks from the same directory:

```shell
build-logic/gradlew ktlintCheck
```

Each included build can also be checked through its own wrapper. For example, run `./gradlew check` from `services/realm`, or use the Typewriter types wrapper with `gradlew` project selection for builds that do not own a wrapper.

## Discovery development

Imprint assembles one canonical manifest for each artifact. KSP processors contribute static metadata and generated module providers. Realm discovery loads only Realm bindings. Execution discovery loads only execution bindings. Each deployment owns an isolated Koin application and classloader.

The conformance extension is the complete development proof. It verifies declared type identities, qualified abstract parents, generated prototypes, element descriptors, source part eligibility, generated registrars, generated facets, and ordinary panel engine targeting.

There is no development artifact filename protocol. There is also no shared publication directory. Local deployment assembly must consume canonical Imprint manifests and explicit artifact packages.

## Runtime status

The loader and Realm lifecycle contracts remain available. Production deployment selection and artifact staging are not yet connected to the new discovery package factory. Do not describe local runtime startup as complete until that connection exists.
