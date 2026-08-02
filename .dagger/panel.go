package main

import (
	"dagger/typewriter/internal/dagger"
)

const panelFlutterVersion = "3.44.7"

var defaultWorkspaceOpts = dagger.WorkspaceDirectoryOpts{
	Exclude:   []string{".git", "target", "node_modules", "build", "dist"},
	Gitignore: true,
}

func (m *Typewriter) dartContainer() *dagger.Container {
	return dag.FlutterContainer().
		WithFlutterVersion(panelFlutterVersion).
		Flutter().
		WithExec([]string{"flutter", "precache", "--linux"})
}

func (m *Typewriter) panelContainer(source *dagger.Workspace) *dagger.Container {
	panelSource := source.Directory("/panel", defaultWorkspaceOpts)

	return m.dartContainer().
		WithDirectory("/workspace/panel", panelSource).
		WithMountedCache("/root/.pub-cache", dag.CacheVolume("pub-cache")).
		WithMountedCache("/workspace/panel/.dart_tool", dag.CacheVolume("dart-tool")).
		WithMountedCache("/workspace/panel/testkit/.dart_tool", dag.CacheVolume("dart-tool-testkit")).
		WithMountedCache("/workspace/panel/widgetbook/.dart_tool", dag.CacheVolume("dart-tool-widgetbook"))
}

func (m *Typewriter) buildRunner(
	source *dagger.Workspace,
	dir string,
) *dagger.Changeset {
	panelSource := source.Directory("/panel", defaultWorkspaceOpts)
	workspaceSource := dag.Directory().WithDirectory("panel", panelSource)
	generated := m.panelContainer(source).
		WithWorkdir(dir).
		WithExec([]string{"flutter", "pub", "get"}).
		WithExec([]string{"dart", "run", "build_runner", "build"}).
		WithoutMount("/root/.pub-cache").
		WithoutMount("/workspace/panel/.dart_tool").
		WithoutMount("/workspace/panel/testkit/.dart_tool").
		WithoutMount("/workspace/panel/widgetbook/.dart_tool").
		WithWorkdir("/workspace/panel").
		WithExec([]string{"git", "init", "--quiet"}).
		WithExec([]string{"git", "clean", "-fdX"}).
		WithoutDirectory("/workspace/panel/.git").
		Directory("/workspace")

	return generated.Changes(workspaceSource)
}

// +generate
func (m *Typewriter) PanelBuildRunner(
	source *dagger.Workspace,
) (*dagger.Changeset, error) {
	return m.buildRunner(source, "/workspace/panel"), nil
}

// +generate
func (m *Typewriter) PanelTestKitBuildRunner(
	source *dagger.Workspace,
) (*dagger.Changeset, error) {
	return m.buildRunner(source, "/workspace/panel/testkit"), nil
}

// +generate
func (m *Typewriter) PanelWidgetbookBuildRunner(
	source *dagger.Workspace,
) (*dagger.Changeset, error) {
	return m.buildRunner(source, "/workspace/panel/widgetbook"), nil
}

// +check
func (m *Typewriter) PanelAnalysis(
	source *dagger.Workspace,
) *dagger.Container {
	return m.panelContainer(source).
		WithWorkdir("/workspace/panel/testkit").
		WithExec([]string{"flutter", "pub", "get"}).
		WithExec([]string{"flutter", "analyze"}).
		WithWorkdir("/workspace/panel/widgetbook").
		WithExec([]string{"flutter", "pub", "get"}).
		WithExec([]string{"flutter", "analyze"}).
		WithWorkdir("/workspace/panel").
		WithExec([]string{"flutter", "pub", "get"}).
		WithExec([]string{"flutter", "analyze"})
}

// +check
func (m *Typewriter) PanelTest(
	source *dagger.Workspace,
) *dagger.Container {
	return m.panelContainer(source).
		WithWorkdir("/workspace/panel").
		WithExec([]string{"flutter", "pub", "get"}).
		WithExec([]string{"flutter", "test"})
}
