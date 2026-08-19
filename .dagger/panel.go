package main

import (
	"dagger/typewriter/internal/dagger"
)

const panelFlutterVersion = "3.44.7"

const panelGeneratorCacheVersion = "flutter-3.44.7-lock-v2"

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

func (m *Typewriter) panelGeneratorContainer(source *dagger.Workspace, packageName string) *dagger.Container {
	panelSource := source.Directory("/panel", defaultWorkspaceOpts)
	cachePrefix := "panel-generator-" + packageName + "-" + panelGeneratorCacheVersion

	return m.dartContainer().
		WithDirectory("/workspace/panel", panelSource).
		WithMountedCache("/root/.pub-cache", dag.CacheVolume(cachePrefix+"-pub-cache")).
		WithMountedCache("/workspace/panel/.dart_tool", dag.CacheVolume(cachePrefix+"-dart-tool")).
		WithMountedCache("/workspace/panel/testkit/.dart_tool", dag.CacheVolume(cachePrefix+"-dart-tool-testkit")).
		WithMountedCache("/workspace/panel/widgetbook/.dart_tool", dag.CacheVolume(cachePrefix+"-dart-tool-widgetbook"))
}

func (m *Typewriter) buildRunner(
	source *dagger.Workspace,
	dir string,
	packageName string,
) *dagger.Changeset {
	panelSource := source.Directory("/panel", defaultWorkspaceOpts)
	workspaceSource := dag.Directory().WithDirectory("panel", panelSource)
	generated := m.panelGeneratorContainer(source, packageName).
		WithWorkdir("/workspace/panel").
		WithExec([]string{"git", "init", "--quiet"}).
		WithExec([]string{"git", "add", "--all"}).
		WithWorkdir(dir).
		WithExec([]string{"flutter", "pub", "get", "--enforce-lockfile"}).
		WithExec([]string{"dart", "run", "build_runner", "build"}).
		WithWorkdir("/workspace/panel").
		WithExec([]string{
			"sh",
			"-c",
			"(git diff --name-only --diff-filter=ACM -z -- ':(glob)**/*.g.dart' ':(glob)**/*.freezed.dart'; git ls-files --others --exclude-standard -z -- ':(glob)**/*.g.dart' ':(glob)**/*.freezed.dart') | xargs -0 -r sed -i 's/[[:space:]]*$//'",
		}).
		WithWorkdir(dir).
		WithExec([]string{"dart", "format", "--output=none", "."}).
		WithoutMount("/root/.pub-cache").
		WithoutMount("/workspace/panel/.dart_tool").
		WithoutMount("/workspace/panel/testkit/.dart_tool").
		WithoutMount("/workspace/panel/widgetbook/.dart_tool").
		WithWorkdir("/workspace/panel").
		WithExec([]string{"git", "clean", "-fdX"}).
		WithoutDirectory("/workspace/panel/.git").
		Directory("/workspace")

	return generated.Changes(workspaceSource)
}

// +generate
func (m *Typewriter) PanelBuildRunner(
	source *dagger.Workspace,
) (*dagger.Changeset, error) {
	return m.buildRunner(source, "/workspace/panel", "panel"), nil
}

// +generate
func (m *Typewriter) PanelTestKitBuildRunner(
	source *dagger.Workspace,
) (*dagger.Changeset, error) {
	return m.buildRunner(source, "/workspace/panel/testkit", "testkit"), nil
}

// +generate
func (m *Typewriter) PanelWidgetbookBuildRunner(
	source *dagger.Workspace,
) (*dagger.Changeset, error) {
	return m.buildRunner(source, "/workspace/panel/widgetbook", "widgetbook"), nil
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
