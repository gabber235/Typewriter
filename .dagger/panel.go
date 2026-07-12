package main

import (
	"dagger/typewriter/internal/dagger"
)

var defaultWorkspaceOpts = dagger.WorkspaceDirectoryOpts{
	Exclude:   []string{".git", "target", "node_modules", "build", "dist"},
	Gitignore: true,
}

func (m *Typewriter) dartContainer() *dagger.Container {
	return dag.FlutterContainer().
		WithFlutterVersion("3.44.4").
		Flutter()
}

func (m *Typewriter) buildRunner(
	source *dagger.Workspace,
	dir string,
) *dagger.Changeset {
	dirSource := source.Directory("/panel", defaultWorkspaceOpts)
	generated := m.dartContainer().
		WithDirectory("/workspace", dirSource).
		WithMountedCache("/root/.pub-cache", dag.CacheVolume("pub-cache")).
		WithWorkdir(dir).
		WithExec([]string{"flutter", "pub", "get"}).
		WithMountedCache("/workspace/.dart_tool", dag.CacheVolume("dart-tool")).
		WithExec([]string{"dart", "run", "build_runner", "build"}).
		Directory("/workspace")

	return generated.Changes(dirSource)
}

// +generate
func (m *Typewriter) PanelBuildRunner(
	source *dagger.Workspace,
) (*dagger.Changeset, error) {
	return m.buildRunner(source, "/workspace"), nil
}

// +generate
func (m *Typewriter) PanelTestKitBuildRunner(
	source *dagger.Workspace,
) (*dagger.Changeset, error) {
	return m.buildRunner(source, "/workspace/testkit"), nil
}

// +generate
func (m *Typewriter) PanelWidgetbookBuildRunner(
	source *dagger.Workspace,
) (*dagger.Changeset, error) {
	return m.buildRunner(source, "/workspace/widgetbook"), nil
}

// +check
func (m *Typewriter) PanelAnalysis(
	source *dagger.Workspace,
) *dagger.Container {
	return m.dartContainer().
		WithDirectory("/workspace", source.Directory("/panel", defaultWorkspaceOpts)).
		WithMountedCache("/root/.pub-cache", dag.CacheVolume("pub-cache")).
		WithMountedCache("/workspace/.dart_tool", dag.CacheVolume("dart-tool")).
		WithMountedCache("/workspace/testkit/.dart_tool", dag.CacheVolume("dart-tool-testkit")).
		WithMountedCache("/workspace/widgetbook/.dart_tool", dag.CacheVolume("dart-tool-widgetbook")).
		WithWorkdir("/workspace/testkit").
		WithExec([]string{"flutter", "pub", "get"}).
		WithExec([]string{"flutter", "analyze"}).
		WithWorkdir("/workspace/widgetbook").
		WithExec([]string{"flutter", "pub", "get"}).
		WithExec([]string{"flutter", "analyze"}).
		WithWorkdir("/workspace").
		WithExec([]string{"flutter", "pub", "get"}).
		WithExec([]string{"flutter", "analyze"})
}

// +check
func (m *Typewriter) PanelTest(
	source *dagger.Workspace,
) *dagger.Container {
	return m.dartContainer().
		WithDirectory("/workspace", source.Directory("/panel", defaultWorkspaceOpts)).
		WithWorkdir("/workspace").
		WithExec([]string{"flutter", "test"})
}
