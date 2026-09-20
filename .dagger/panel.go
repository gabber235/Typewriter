package main

import (
	"dagger/typewriter/internal/dagger"
)

const panelFlutterVersion = "3.47.2"

const panelGeneratorCacheVersion = "flutter-3.47.2-lock-v2"

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

func (m *Typewriter) panelDependencies(source *dagger.Workspace) *dagger.Container {
	panelSource := source.Directory("/panel", defaultWorkspaceOpts)

	return m.dartContainer().
		WithDirectory("/workspace/panel", panelSource).
		WithMountedCache("/root/.pub-cache", lockedCache("panel-pub-cache")).
		WithWorkdir("/workspace/panel/testkit").
		WithExec([]string{"flutter", "pub", "get", "--enforce-lockfile"}).
		WithWorkdir("/workspace/panel/widgetbook").
		WithExec([]string{"flutter", "pub", "get", "--enforce-lockfile"}).
		WithWorkdir("/workspace/panel").
		WithExec([]string{"flutter", "pub", "get", "--enforce-lockfile"}).
		WithExec([]string{"sh", "-c", "mkdir -p /dependency-cache/pub && cp -a /root/.pub-cache/. /dependency-cache/pub"}).
		WithNewFile("/dependency-ready", "")
}

func (m *Typewriter) panelContainer(source *dagger.Workspace) *dagger.Container {
	panelSource := source.Directory("/panel", defaultWorkspaceOpts)
	dependencies := m.panelDependencies(source)

	return m.dartContainer().
		WithDirectory("/workspace/panel", panelSource).
		WithFile("/dependency-ready", dependencies.File("/dependency-ready")).
		WithDirectory("/root/.pub-cache", dependencies.Directory("/dependency-cache/pub")).
		WithDirectory("/workspace/panel/.dart_tool", dependencies.Directory("/workspace/panel/.dart_tool")).
		WithDirectory("/workspace/panel/testkit/.dart_tool", dependencies.Directory("/workspace/panel/testkit/.dart_tool")).
		WithDirectory("/workspace/panel/widgetbook/.dart_tool", dependencies.Directory("/workspace/panel/widgetbook/.dart_tool"))
}

func (m *Typewriter) panelGeneratorContainer(source *dagger.Workspace, packageName string) *dagger.Container {
	cachePrefix := "panel-generator-" + packageName + "-" + panelGeneratorCacheVersion

	return m.panelContainer(source).
		WithMountedCache("/workspace/panel/.dart_tool", lockedCache(cachePrefix+"-dart-tool")).
		WithMountedCache("/workspace/panel/testkit/.dart_tool", lockedCache(cachePrefix+"-dart-tool-testkit")).
		WithMountedCache("/workspace/panel/widgetbook/.dart_tool", lockedCache(cachePrefix+"-dart-tool-widgetbook"))
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
		WithExec([]string{"flutter", "analyze", "--no-pub"}).
		WithWorkdir("/workspace/panel/widgetbook").
		WithExec([]string{"flutter", "analyze", "--no-pub"}).
		WithWorkdir("/workspace/panel").
		WithExec([]string{"flutter", "analyze", "--no-pub"})
}

// +check
func (m *Typewriter) PanelTest(
	source *dagger.Workspace,
) *dagger.Container {
	return m.panelContainer(source).
		WithDirectory("/workspace/skir-src", source.Directory("/skir-src", defaultWorkspaceOpts)).
		WithWorkdir("/workspace/panel").
		WithExec([]string{"flutter", "test", "--no-pub"})
}

// +check
func (m *Typewriter) PanelTestKitTest(source *dagger.Workspace) *dagger.Container {
	return m.panelContainer(source).
		WithWorkdir("/workspace/panel/testkit").
		WithExec([]string{"flutter", "test", "--no-pub"})
}

// +check
func (m *Typewriter) PanelWidgetbookTest(source *dagger.Workspace) *dagger.Container {
	return m.panelContainer(source).
		WithWorkdir("/workspace/panel/widgetbook").
		WithExec([]string{"flutter", "test", "--no-pub"})
}

// +check
func (m *Typewriter) PanelNatsIntegration(
	source *dagger.Workspace,
) *dagger.Container {
	config := `
port: 4222
authorization {
  users: [{
    nkey: "UD466L6EBCM3YY5HEGHJANNTN4LSKTSUXTH7RILHCKEQMQHTBNLHJJXT"
    permissions: {
      publish: {allow: ["allowed.>", "_INBOX.integration.>"]}
      subscribe: {allow: ["allowed.>", "_INBOX.integration.>"]}
    }
  }]
}
`
	nats := dag.Container().
		From("nats:2.14.6-alpine").
		WithNewFile("/etc/nats/nats.conf", config).
		WithExposedPort(4222).
		AsService(dagger.ContainerAsServiceOpts{
			Args:          []string{"-c", "/etc/nats/nats.conf"},
			UseEntrypoint: true,
		})

	return m.panelContainer(source).
		WithServiceBinding("nats", nats).
		WithEnvVariable("NATS_ADAPTER_URL", "nats://nats:4222").
		WithWorkdir("/workspace/panel").
		WithExec([]string{
			"flutter",
			"test",
			"--no-pub",
			"test/infrastructure/messaging/nats_core_client_integration_test.dart",
		})
}
