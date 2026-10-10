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

func (m *Typewriter) transportGeneratorContainer(source *dagger.Directory) *dagger.Container {
	return dag.Container().
		From("rust:1.95-bookworm").
		WithDirectory("/generator", source.Directory("services/protocol/transport-generator")).
		WithWorkdir("/generator").
		WithMountedCache("/usr/local/cargo/registry", lockedCache("transport-generator-cargo-registry")).
		WithMountedCache("/usr/local/cargo/git", lockedCache("transport-generator-cargo-git"))
}

func (m *Typewriter) transportGenerator(source *dagger.Directory) *dagger.File {
	return m.transportGeneratorContainer(source).
		WithExec([]string{"cargo", "build", "--locked", "--release"}).
		File("/generator/target/release/typewriter-transport-generator")
}

func (m *Typewriter) transportGenerationContainer(source *dagger.Directory) *dagger.Container {
	return m.skirContainer(source).
		WithFile("/workspace/services/protocol/transport-generator/target/release/typewriter-transport-generator", m.transportGenerator(source)).
		WithExec([]string{
			"services/protocol/transport-generator/target/release/typewriter-transport-generator",
			"validate-subscriptions",
			"--manifest", "services/protocol/transport-routes.yaml",
			"--component", "auth-typewriter-permissions",
			"--deployment", "backend/access/auth-typewriter-permissions/deploy/base/workloaddeployment.yaml",
		}).
		WithExec([]string{"bunx", "--bun", "--no-install", "skir", "gen"})
}

// +check
func (m *Typewriter) TransportManifestCheck(
	// +optional
	// +defaultPath="/"
	// +ignore=["*", "!package.json", "!bun.lock", "!skir.yml", "!skir-src", "!services/protocol/transport-routes.yaml", "!services/protocol/transport-generator", "!backend/access/auth-typewriter-permissions/deploy/base/workloaddeployment.yaml", "**/target", "**/node_modules"]
	source *dagger.Directory,
) *dagger.Container {
	return m.transportGenerationContainer(source)
}

// +check
func (m *Typewriter) TransportGeneratorTest(
	// +optional
	// +defaultPath="/"
	// +ignore=["*", "!services/protocol/transport-routes.yaml", "!services/protocol/transport-generator", "**/target", "**/node_modules"]
	source *dagger.Directory,
) *dagger.Container {
	return m.transportGeneratorContainer(source).
		WithFile("/transport-routes.yaml", source.File("services/protocol/transport-routes.yaml")).
		WithExec([]string{"cargo", "test", "--locked"})
}

// +check
func (m *Typewriter) TransportBindingCheck(
	// +optional
	// +defaultPath="/"
	// +ignore=["*", "!package.json", "!bun.lock", "!services/protocol/transport-generator/dependency-patches", "!services/protocol/transport-generator/skir-bridge"]
	source *dagger.Directory,
) *dagger.Container {
	return m.skirContainer(source).
		WithExec([]string{"bun", "run", "--cwd", "services/protocol/transport-generator/skir-bridge", "check"}).
		WithExec([]string{"bun", "run", "test:transport-metadata"})
}

func (m *Typewriter) formatGeneratedProtocol(source *dagger.Directory) *dagger.Directory {
	rust := dag.Container().
		From("rust:1.95-bookworm").
		WithExec([]string{"rustup", "component", "add", "rustfmt"}).
		WithDirectory("/workspace", source).
		WithWorkdir("/workspace").
		WithExec([]string{
			"rustfmt", "--edition", "2024",
			"backend/wasmcloud-utils/src/skirout/base.rs",
			"backend/wasmcloud-utils/src/transport_routes/skirout/mod.rs",
		}).
		Directory("/workspace")

	return m.dartContainer().
		WithDirectory("/workspace", rust).
		WithWorkdir("/workspace").
		WithExec([]string{
			"dart", "services/protocol/transport-generator/normalize_generated_dart.dart",
			"panel/lib/infrastructure/protocols/skir/skirout",
			"panel/lib/infrastructure/messaging/generated/skirout",
		}).
		WithExec([]string{
			"dart", "format",
			"panel/lib/infrastructure/protocols/skir/skirout",
			"panel/lib/infrastructure/messaging/generated/skirout",
		}).
		Directory("/workspace")
}

// +check
func (m *Typewriter) SkirCheck(
	// +optional
	// +defaultPath="/"
	// +ignore=["*", "!package.json", "!bun.lock", "!skir.yml", "!skir-src", "!services/protocol/transport-generator/dependency-patches", "!services/protocol/transport-generator/skir-bridge"]
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
	// +ignore=["*", "!package.json", "!bun.lock", "!skir.yml", "!skir-src", "!services/protocol/transport-generator/dependency-patches", "!services/protocol/transport-generator/skir-bridge"]
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
	// +ignore=["*", "!package.json", "!bun.lock", "!skir.yml", "!skir-src", "!services/protocol/transport-generator/dependency-patches", "!services/protocol/transport-generator/skir-bridge"]
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
	// +ignore=["*", "!package.json", "!bun.lock", "!skir.yml", "!skir-src", "!services/protocol/transport-routes.yaml", "!services/protocol/transport-generator", "!backend/access/auth-typewriter-permissions/deploy/base/workloaddeployment.yaml", "!panel/lib/infrastructure/protocols/skir/skirout", "!panel/lib/infrastructure/messaging/generated", "!backend/wasmcloud-utils/src/skirout", "!backend/wasmcloud-utils/src/transport_routes", "!services/protocol/src/main/kotlin/skirout", "!services/protocol/transport-adapters", "**/target", "**/node_modules"]
	source *dagger.Directory,
) (*dagger.Changeset, error) {
	generated := m.transportGenerationContainer(source).
		Directory("/workspace").
		WithoutDirectory("node_modules").
		WithoutDirectory("services/protocol/transport-generator/target")

	return m.formatGeneratedProtocol(generated).Changes(source), nil
}
