use std::{
    env, fs,
    io::{self, Read},
    path::PathBuf,
    process::ExitCode,
};

use serde::{Deserialize, Serialize};
use typewriter_transport_generator::{
    OutputFile,
    manifest::Manifest,
    symbols::{CanonicalSymbols, Language, LanguageBindings, SymbolDocument},
};

#[derive(Debug, Clone, Copy)]
enum Command {
    Symbols,
    Generate,
    ValidateSubscriptions,
}

#[derive(Debug)]
struct Arguments {
    command: Command,
    manifest: PathBuf,
    target: Option<Language>,
    loader_kotlin: bool,
    component: Option<String>,
    deployment: Option<PathBuf>,
}

#[derive(Deserialize)]
struct GenerationInput {
    symbols: SymbolDocument,
    binding: LanguageBindings,
}

#[derive(Serialize)]
struct GenerationOutput {
    files: Vec<OutputFile>,
}

#[derive(Deserialize)]
struct WorkloadDeployment {
    spec: WorkloadSpec,
}

#[derive(Deserialize)]
struct WorkloadSpec {
    template: WorkloadTemplate,
}

#[derive(Deserialize)]
struct WorkloadTemplate {
    spec: WorkloadTemplateSpec,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct WorkloadTemplateSpec {
    host_interfaces: Vec<HostInterface>,
}

#[derive(Deserialize)]
struct HostInterface {
    namespace: String,
    package: String,
    #[serde(default)]
    config: std::collections::BTreeMap<String, String>,
}

fn deployment_subscriptions(source: &str) -> Result<String, String> {
    let deployment: WorkloadDeployment = serde_saphyr::from_str(source)
        .map_err(|error| format!("invalid deployment YAML: {error}"))?;
    let values = deployment
        .spec
        .template
        .spec
        .host_interfaces
        .into_iter()
        .filter(|interface| interface.namespace == "wasmcloud" && interface.package == "nats")
        .filter_map(|interface| interface.config.get("core-subscriptions").cloned())
        .collect::<Vec<_>>();
    match values.as_slice() {
        [value] => Ok(value.clone()),
        [] => Err("deployment has no NATS core-subscriptions value".to_owned()),
        _ => Err("deployment has duplicate NATS core-subscriptions values".to_owned()),
    }
}

fn parse_arguments() -> Result<Arguments, String> {
    let mut values = env::args().skip(1);
    let command = match values.next().as_deref() {
        Some("symbols") => Command::Symbols,
        Some("generate") => Command::Generate,
        Some("validate-subscriptions") => Command::ValidateSubscriptions,
        _ => {
            return Err("expected symbols, generate, or validate-subscriptions command".to_owned());
        }
    };
    let mut manifest = None;
    let mut target = None;
    let mut loader_kotlin = false;
    let mut component = None;
    let mut deployment = None;
    while let Some(flag) = values.next() {
        let value = values
            .next()
            .ok_or_else(|| format!("missing value for {flag}"))?;
        match flag.as_str() {
            "--manifest" => manifest = Some(PathBuf::from(value)),
            "--target" => {
                target = Some(match value.as_str() {
                    "kotlin" => Language::Kotlin,
                    "kotlin_loader" => {
                        loader_kotlin = true;
                        Language::Kotlin
                    }
                    "dart" => Language::Dart,
                    "rust" => Language::Rust,
                    _ => return Err(format!("unknown target {value}")),
                })
            }
            "--component" => component = Some(value),
            "--deployment" => deployment = Some(PathBuf::from(value)),
            _ => return Err(format!("unknown argument {flag}")),
        }
    }
    Ok(Arguments {
        command,
        manifest: manifest.ok_or_else(|| "missing manifest argument".to_owned())?,
        target,
        loader_kotlin,
        component,
        deployment,
    })
}

fn run(arguments: Arguments) -> Result<(), String> {
    let source = fs::read_to_string(&arguments.manifest)
        .map_err(|error| format!("failed to read {}: {error}", arguments.manifest.display()))?;
    let manifest = Manifest::parse(&source).map_err(|error| error.to_string())?;
    match arguments.command {
        Command::Symbols => {
            serde_json::to_writer(io::stdout(), &manifest.requested_symbols())
                .map_err(|error| error.to_string())?;
        }
        Command::Generate => {
            let target = arguments
                .target
                .ok_or_else(|| "missing target argument".to_owned())?;
            let mut input = String::new();
            io::stdin()
                .read_to_string(&mut input)
                .map_err(|error| error.to_string())?;
            let input: GenerationInput =
                serde_json::from_str(&input).map_err(|error| error.to_string())?;
            if input.binding.language != target {
                return Err("binding language does not match requested target".to_owned());
            }
            let symbols = CanonicalSymbols::new(input.symbols, input.binding)?;
            let routes = manifest.resolve(&symbols)?;
            let files = if arguments.loader_kotlin {
                typewriter_transport_generator::kotlin::emit_loader(&routes)?
            } else {
                match target {
                    Language::Kotlin => typewriter_transport_generator::kotlin::emit(&routes)?,
                    Language::Dart => typewriter_transport_generator::dart::emit(&routes)?,
                    Language::Rust => typewriter_transport_generator::rust::emit(&routes)?,
                }
            };
            serde_json::to_writer(io::stdout(), &GenerationOutput { files })
                .map_err(|error| error.to_string())?;
        }
        Command::ValidateSubscriptions => {
            let component = arguments
                .component
                .ok_or_else(|| "missing component argument".to_owned())?;
            let deployment = arguments
                .deployment
                .ok_or_else(|| "missing deployment argument".to_owned())?;
            let source = fs::read_to_string(&deployment)
                .map_err(|error| format!("failed to read {}: {error}", deployment.display()))?;
            let actual = deployment_subscriptions(&source)?;
            manifest.validate_component_subscriptions(&component, &actual)?;
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::deployment_subscriptions;

    fn deployment(host_interfaces: &str) -> String {
        format!("spec:\n  template:\n    spec:\n      hostInterfaces:\n{host_interfaces}")
    }

    #[test]
    fn reads_one_typed_nats_subscription_value() {
        let source = deployment(
            "        - namespace: wasmcloud\n          package: nats\n          config:\n            core-subscriptions: one:group,two:group\n",
        );
        assert_eq!(
            deployment_subscriptions(&source).unwrap(),
            "one:group,two:group"
        );
    }

    #[test]
    fn rejects_malformed_missing_and_duplicate_subscription_values() {
        assert!(deployment_subscriptions("spec: [invalid]").is_err());
        assert!(
            deployment_subscriptions(&deployment(
                "        - namespace: wasi\n          package: otel\n"
            ))
            .is_err()
        );
        let duplicate = deployment(
            "        - namespace: wasmcloud\n          package: nats\n          config:\n            core-subscriptions: one:group\n        - namespace: wasmcloud\n          package: nats\n          config:\n            core-subscriptions: two:group\n",
        );
        assert!(deployment_subscriptions(&duplicate).is_err());
    }
}

fn main() -> ExitCode {
    match parse_arguments().and_then(run) {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("{error}");
            ExitCode::FAILURE
        }
    }
}
