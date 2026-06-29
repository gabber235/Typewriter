package main

import (
	"dagger/typewriter/internal/dagger"
)

func (m *Typewriter) skirContainer(source *dagger.Directory) *dagger.Container {
	return dag.Container().
		From("oven/bun").
		WithDirectory("/workspace", source).
		WithWorkdir("/workspace")
}

// +check
func (m *Typewriter) SkirCheck(
	// +optional
	// +defaultPath="/"
	// +ignore=["*", "!skir.yml", "!skir-src"]
	source *dagger.Directory,
) (*dagger.Changeset, error) {
	generated := m.skirContainer(source).
		WithExec([]string{"bunx", "skir", "format", "--ci"}).
		Directory("/workspace")

	return generated.Changes(source), nil
}

func (m *Typewriter) SkirFormat(
	// +optional
	// +defaultPath="/"
	// +ignore=["*", "!skir.yml", "!skir-src"]
	source *dagger.Directory,
) (*dagger.Changeset, error) {
	generated := m.skirContainer(source).
		WithExec([]string{"bunx", "skir", "format"}).
		Directory("/workspace")

	return generated.Changes(source), nil
}

func (m *Typewriter) SkirSnapshot(
	// +optional
	// +defaultPath="/"
	// +ignore=["*", "!skir.yml", "!skir-src"]
	source *dagger.Directory,
) (*dagger.Changeset, error) {
	generated := m.skirContainer(source).
		WithExec([]string{"bunx", "skir", "snapshot"}).
		Directory("/workspace")

	return generated.Changes(source), nil
}
