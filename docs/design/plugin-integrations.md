# Plugin integrations

How an extension integrates with another Paper plugin (Vault, PlaceholderAPI, a test plugin) only
where that plugin is enabled. Decided 2026-11-22.

## Model

1. **Declare**: an extension declares each plugin once, with the API it compiles against. Source
   parts opt in.
2. **Compile**: only parts that use a plugin, and parts that include them, see its API.
3. **Check**: the Paper engine reports its enabled plugins; the Realm marks a part that uses a
   missing plugin ineligible for that engine, with a reason.
4. **Hook in**: a loaded part's classloader reaches the plugin's own classloader.
5. **Warn**: content that uses an entry whose behaviour no engine can run gets a finding.

## Declaration

```kotlin
typewriter {
    extension {
        val vault = plugin("Vault") {
            api("com.github.MilkBowl:VaultAPI:1.7.1") // any Gradle notation, also project(...)
            version("^1.7")                          // optional; any version without it
        }
        sourceSet("enginePaper") { engine(paper) }
        sourceSet("vault") { engine(paper); uses(vault) }
        sourceSet("vaultQuests") { engine(paper); uses(vault) }
    }
}
```

- The plugin name is the name Paper reports for it.
- `api(...)` goes on the compile only classpath of each part that uses the plugin, and of each part
  that includes such a part. No other part compiles against it.
- Repositories stay in the build's `repositories {}` block.
- The manifest records, per part, the plugins it needs (name and optional version range), including
  the ones it inherits through `includes`.
- The manifest records, per part, the entry types its handlers run, so the Realm can tell which
  part gives an entry its behaviour.

## Presence

- The Paper host reports its enabled plugins (name and version) in its presence answer
  (`RealmHostPresence.plugins`). The loader starts on the first server tick, after every plugin
  is enabled. The Realm host polls presence, so an enable or disable reaches it within a poll.
- Versions parse leniently: the leading numeric version counts (`1.7.3-b131` is 1.7.3). A version
  without one fails only a part that declares a range.
- The Realm's deployment resolver decides eligibility, as it does for engines and capabilities. A
  part that needs a plugin the engine does not report, or reports outside the declared range, is
  ineligible there with the reason "needs the Vault plugin" (or "needs Vault ^1.7, the engine has
  1.6.0").
- A change in reported plugins re-resolves that engine's deployment.

## Classloading

- An extension's loaded parts share one classloader. When a loaded part uses plugins, that
  classloader resolves the engine classloader first, then the classloader of each plugin a loaded
  part uses, found through Paper's plugin manager. The compiler keeps the per part boundary; at
  runtime the boundary is the extension.
- A plugin that is no longer enabled while a loaded part uses it refuses staging with a reason.
- Typewriter's own `paper-plugin.yml` lists no plugins. Any extension can integrate with any plugin.

## Checker

- An entry type lives in `common`; its behaviour may live in a part that uses a plugin.
- When content uses an entry whose behaviour runs on no engine of the Realm, the entry gets a
  warning finding, for example "No engine runs Give money: it needs the Vault plugin."
- Publication is not blocked; the plugin may arrive later.

## First user

The playtest bridge: a test only extension whose Paper part uses the `Playtest` plugin
(`api(project(":playtest-plugin"))`) for `PlayerWork`, `PlayerWipeEvent` and `AppliedContent`.
Game test modules install it with `gamePaper { typewriterExtensions.from(...) }`.
