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

// +check
func (m *Typewriter) SkirCheck(
	// +optional
	// +defaultPath="/"
	// +ignore=["*", "!package.json", "!bun.lock", "!skir.yml", "!skir-src"]
	source *dagger.Directory,
) (*dagger.Changeset, error) {
	generated := m.skirContainer(source).
		WithExec([]string{"bunx", "--no-install", "skir", "format", "--ci"}).
		Directory("/workspace").
		WithoutDirectory("node_modules")

	return generated.Changes(source), nil
}

func (m *Typewriter) SkirFormat(
	// +optional
	// +defaultPath="/"
	// +ignore=["*", "!package.json", "!bun.lock", "!skir.yml", "!skir-src"]
	source *dagger.Directory,
) (*dagger.Changeset, error) {
	generated := m.skirContainer(source).
		WithExec([]string{"bunx", "--no-install", "skir", "format"}).
		Directory("/workspace").
		WithoutDirectory("node_modules")

	return generated.Changes(source), nil
}

func (m *Typewriter) SkirSnapshot(
	// +optional
	// +defaultPath="/"
	// +ignore=["*", "!package.json", "!bun.lock", "!skir.yml", "!skir-src"]
	source *dagger.Directory,
) (*dagger.Changeset, error) {
	generated := m.skirContainer(source).
		WithExec([]string{"bunx", "--no-install", "skir", "snapshot"}).
		Directory("/workspace").
		WithoutDirectory("node_modules")

	return generated.Changes(source), nil
}

// +generate
func (m *Typewriter) SkirGenerate(
	// +optional
	// +defaultPath="/"
	// +ignore=["*", "!package.json", "!bun.lock", "!skir.yml", "!skir-src", "!panel/lib/infrastructure/protocols/skir/skirout", "!backend/wasmcloud-utils/src/skirout", "!services/libs/service-communicator/skir/src/main/kotlin/skirout"]
	source *dagger.Directory,
) (*dagger.Changeset, error) {
	generated := m.skirContainer(source).
		WithExec([]string{"bunx", "--no-install", "skir", "gen"}).
		Directory("/workspace").
		WithoutDirectory("node_modules")

	return generated.Changes(source), nil
}
