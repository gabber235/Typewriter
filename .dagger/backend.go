package main

import (
	"context"
	"sort"
	"strconv"
	"strings"

	"dagger/typewriter/internal/dagger"
)

const (
	backendRoot          = "/workspace/backend"
	backendCacheRoot     = "/workspace/backend-cache"
	backendTarget        = backendCacheRoot + "/target"
	componentTestXtask   = backendTarget + "/debug/component-test-xtask"
	cleanupBackendTarget = `cargo clean --manifest-path /workspace/backend/Cargo.toml --target-dir "$CARGO_TARGET_DIR" >/dev/null`
)

func withBackendTargetCleanup(command ...string) []string {
	return append([]string{
		"sh", "-c",
		`status=0; "$@" || status=$?; ` + cleanupBackendTarget + ` || exit $?; exit "$status"`,
		"backend-command",
	}, command...)
}

func backendTestCommand(args ...string) []string {
	command := append([]string{componentTestXtask}, args...)
	return append([]string{
		"sh", "-c",
		`status=0; cargo build --manifest-path backend/tests/component/Cargo.toml -p component-test-xtask && "$@" || status=$?; ` + cleanupBackendTarget + ` || exit $?; exit "$status"`,
		"backend-test",
	}, command...)
}

func (m *Typewriter) backendToolchain() *dagger.Container {
	return dag.Container().
		From("rust:1.95-bookworm").
		WithExec([]string{"rustup", "target", "add", "wasm32-wasip2"})
}

func (m *Typewriter) backendContainer(source *dagger.Workspace, cacheScope string) *dagger.Container {
	cachePrefix := "backend-" + cacheScope

	return m.backendToolchain().
		WithWorkdir("/workspace").
		WithMountedCache("/usr/local/cargo/registry", lockedCache(cachePrefix+"-cargo-registry-v2")).
		WithMountedCache("/usr/local/cargo/git", lockedCache(cachePrefix+"-cargo-git-v2")).
		WithDirectory(backendRoot,
			source.Directory("/backend", dagger.WorkspaceDirectoryOpts{
				Gitignore: true,
			}),
		).
		WithMountedCache(backendCacheRoot, lockedCache(cachePrefix+"-target-v3")).
		WithEnvVariable("CARGO_TARGET_DIR", backendTarget).
		WithEnvVariable("CARGO_INCREMENTAL", "0").
		WithEnvVariable("CARGO_PROFILE_DEV_DEBUG", "0").
		WithEnvVariable("CARGO_PROFILE_TEST_DEBUG", "0")
}

func (m *Typewriter) backendTestContainer(source *dagger.Workspace) *dagger.Container {
	return m.backendContainer(source, "component-test").
		WithFile("/usr/local/bin/nats-server", dag.Container().From("nats:2.14.6-alpine").File("/usr/local/bin/nats-server"))
}

// +check
func (m *Typewriter) BackendUnitTest(source *dagger.Workspace) *dagger.Container {
	return m.backendContainer(source, "unit-test").
		WithExec(withBackendTargetCleanup(
			"cargo", "test", "--manifest-path", "backend/Cargo.toml",
			"--workspace", "--no-fail-fast", "--jobs", "2",
		))
}

// +check
func (m *Typewriter) BackendSupportTest(source *dagger.Workspace) *dagger.Container {
	return m.backendContainer(source, "support-test").
		WithExec(withBackendTargetCleanup(
			"cargo", "test", "--manifest-path", "backend/tests/component/Cargo.toml",
			"--workspace", "--exclude", "typewriter-component-tests", "--no-fail-fast", "--jobs", "2",
		))
}

// BackendTest runs the full embedded component test suite.
func (m *Typewriter) BackendTest(source *dagger.Workspace) *dagger.Container {
	return m.backendTestContainer(source).
		WithExec(backendTestCommand("component-test", "--all", "--jobs", "2"))
}

// BackendTestFixture runs every case for one fixture.
func (m *Typewriter) BackendTestFixture(source *dagger.Workspace, fixture string) *dagger.Container {
	return m.backendTestContainer(source).
		WithExec(backendTestCommand("component-test", fixture, "--jobs", "2"))
}

// BackendTestCase runs cases matching a filter within one fixture.
func (m *Typewriter) BackendTestCase(source *dagger.Workspace, fixture string, filter string) *dagger.Container {
	return m.backendTestContainer(source).
		WithExec(backendTestCommand("component-test", fixture, filter, "--jobs", "1"))
}

// BackendTestAffected runs fixtures changed relative to a repository revision.
func (m *Typewriter) BackendTestAffected(
	ctx context.Context,
	source *dagger.Workspace,
	repository string,
	base string,
) (*dagger.Container, error) {
	current := source.Directory("/", dagger.WorkspaceDirectoryOpts{Gitignore: true})
	baseline := dag.Git(repository).Commit(base).Tree()
	changes := current.Changes(baseline)
	added, err := changes.AddedPaths(ctx)
	if err != nil {
		return nil, err
	}
	modified, err := changes.ModifiedPaths(ctx)
	if err != nil {
		return nil, err
	}
	removed, err := changes.RemovedPaths(ctx)
	if err != nil {
		return nil, err
	}
	paths := append(append(added, modified...), removed...)
	sort.Strings(paths)
	pathFile := dag.Directory().WithNewFile("changed-paths", strings.Join(paths, "\n")+"\n").File("changed-paths")

	return m.backendTestContainer(source).
		WithFile("/tmp/component-test-changed-paths", pathFile).
		WithExec(backendTestCommand(
			"component-test",
			"--affected-paths-file", "/tmp/component-test-changed-paths",
		)), nil
}

// BackendTestShard runs one deterministic full-suite shard.
func (m *Typewriter) BackendTestShard(source *dagger.Workspace, index int, count int) *dagger.Container {
	return m.backendTestContainer(source).
		WithExec(backendTestCommand(
			"component-test", "--all",
			"--shard-index", strconv.Itoa(index),
			"--shard-count", strconv.Itoa(count),
		))
}
