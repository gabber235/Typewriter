package main

import (
	"dagger/typewriter/internal/dagger"
)

func (m *Typewriter) skirContainer(source *dagger.Directory) *dagger.Container {
	return dag.Container().
		From("oven/bun").
		WithDirectory("/workspace", source).
		WithWorkdir("/workspace").
		WithExec([]string{"bun", "install", "--frozen-lockfile"})
}

// protocolGenerationContainer runs the single protocol generation entry point, `bun run generate:protocol`, with
// the panel's Dart SDK plus rustfmt, Bun and the JDK the services build needs. The source is staged in a scratch Git
// index first, so ignored build artifacts can be cleaned afterwards and generated drift stays visible.
func (m *Typewriter) protocolGenerationContainer(source *dagger.Directory) *dagger.Container {
	rust := dag.Container().
		From("rust:1.95-bookworm").
		WithExec([]string{"rustup", "component", "add", "rustfmt"})

	return m.dartContainer().
		WithDirectory("/usr/local/rustup", rust.Directory("/usr/local/rustup")).
		WithDirectory("/usr/local/cargo", rust.Directory("/usr/local/cargo")).
		WithEnvVariable("RUSTUP_HOME", "/usr/local/rustup").
		WithEnvVariable("CARGO_HOME", "/usr/local/cargo").
		WithEnvVariable("PATH", "/usr/local/cargo/bin:${PATH}", dagger.ContainerWithEnvVariableOpts{Expand: true}).
		WithFile("/usr/local/bin/bun", dag.Container().From("oven/bun").File("/usr/local/bin/bun")).
		WithExec([]string{"ln", "-s", "bun", "/usr/local/bin/bunx"}).
		WithEnvVariable("GRADLE_OPTS", "-Dorg.gradle.daemon=false -Dorg.gradle.workers.max=2").
		WithMountedCache("/root/.gradle/caches", dag.CacheVolume("services-gradle-caches")).
		WithMountedCache("/root/.gradle/wrapper", dag.CacheVolume("services-gradle-wrapper")).
		WithDirectory("/workspace", source).
		WithWorkdir("/workspace").
		WithExec([]string{"git", "init", "--quiet"}).
		WithExec([]string{"git", "add", "--all", "--force"}).
		WithExec([]string{"bun", "install", "--frozen-lockfile", "--ignore-scripts"}).
		WithExec([]string{"bun", "run", "generate:protocol"}).
		WithExec([]string{"git", "clean", "-fdX", "--quiet"})
}

// +check
// ProtocolGenerationCheck fails when `bun run generate:protocol` changes committed generated output.
func (m *Typewriter) ProtocolGenerationCheck(
	// +optional
	// +defaultPath="/"
	// +ignore=["*", "!.gitignore", "!package.json", "!bun.lock", "!skir.yml", "!skir-src", "!services", "!backend/**/deploy/base/workloaddeployment.yaml", "!backend/**/deploy/base/kustomization.yaml", "!backend/**/deploy/base/nats-subscriptions.generated.yaml", "!backend/wasmcloud-utils/src/skirout", "!backend/wasmcloud-utils/src/transport_routes", "!panel/lib/infrastructure/protocols/skir/skirout", "!panel/lib/infrastructure/messaging/generated", "!panel/lib/shared/editors/application/canonical_read_models.generated.dart", "**/target", "**/node_modules", "**/build", "**/.gradle", "**/.kotlin"]
	source *dagger.Directory,
) *dagger.Container {
	return m.protocolGenerationContainer(source).
		WithExec([]string{"sh", "-c", "git add --all --intent-to-add && git diff --exit-code --stat"})
}

// +check
// TransportGeneratorCheck typechecks the transport Skir generator and runs its tests against the committed
// route manifest and Skir sources.
func (m *Typewriter) TransportGeneratorCheck(
	// +optional
	// +defaultPath="/"
	// +ignore=["*", "!package.json", "!bun.lock", "!skir-src", "!services/protocol/transport-routes.yaml", "!services/protocol/transport-generator", "**/node_modules"]
	source *dagger.Directory,
) *dagger.Container {
	return m.skirContainer(source).
		WithExec([]string{"bun", "run", "--cwd", "services/protocol/transport-generator", "check"}).
		WithExec([]string{"bun", "run", "test:transport-generator"})
}

// +check
func (m *Typewriter) SkirCheck(
	// +optional
	// +defaultPath="/"
	// +ignore=["*", "!package.json", "!bun.lock", "!skir.yml", "!skir-src", "!services/protocol/transport-generator", "**/node_modules"]
	source *dagger.Directory,
) (*dagger.Changeset, error) {
	generated := m.skirContainer(source).
		WithExec([]string{"bunx", "--bun", "--no-install", "skir", "format", "--ci"}).
		Directory("/workspace").
		WithoutDirectory("node_modules")

	return generated.Changes(source), nil
}

func (m *Typewriter) SkirFormat(
	// +optional
	// +defaultPath="/"
	// +ignore=["*", "!package.json", "!bun.lock", "!skir.yml", "!skir-src", "!services/protocol/transport-generator", "**/node_modules"]
	source *dagger.Directory,
) (*dagger.Changeset, error) {
	generated := m.skirContainer(source).
		WithExec([]string{"bunx", "--bun", "--no-install", "skir", "format"}).
		Directory("/workspace").
		WithoutDirectory("node_modules")

	return generated.Changes(source), nil
}

func (m *Typewriter) SkirSnapshot(
	// +optional
	// +defaultPath="/"
	// +ignore=["*", "!package.json", "!bun.lock", "!skir.yml", "!skir-src", "!services/protocol/transport-generator", "**/node_modules"]
	source *dagger.Directory,
) (*dagger.Changeset, error) {
	generated := m.skirContainer(source).
		WithExec([]string{"bunx", "--bun", "--no-install", "skir", "snapshot"}).
		Directory("/workspace").
		WithoutDirectory("node_modules")

	return generated.Changes(source), nil
}

// +generate
func (m *Typewriter) SkirGenerate(
	// +optional
	// +defaultPath="/"
	// +ignore=["*", "!.gitignore", "!package.json", "!bun.lock", "!skir.yml", "!skir-src", "!services", "!backend/**/deploy/base/workloaddeployment.yaml", "!backend/**/deploy/base/kustomization.yaml", "!backend/**/deploy/base/nats-subscriptions.generated.yaml", "!backend/wasmcloud-utils/src/skirout", "!backend/wasmcloud-utils/src/transport_routes", "!panel/lib/infrastructure/protocols/skir/skirout", "!panel/lib/infrastructure/messaging/generated", "!panel/lib/shared/editors/application/canonical_read_models.generated.dart", "**/target", "**/node_modules", "**/build", "**/.gradle", "**/.kotlin"]
	source *dagger.Directory,
) (*dagger.Changeset, error) {
	generated := m.protocolGenerationContainer(source).
		Directory("/workspace").
		WithoutDirectory(".git")

	return generated.Changes(source), nil
}
