package main

import (
	"context"
	"sort"
	"strconv"
	"strings"

	"dagger/typewriter/internal/dagger"
)

const componentTestXtask = "/workspace/backend/tests/component/target/debug/component-test-xtask"

func (m *Typewriter) backendTestContainer(source *dagger.Workspace) *dagger.Container {
	return dag.Container().
		From("rust:1.95-bookworm").
		WithExec([]string{"rustup", "target", "add", "wasm32-wasip2"}).
		WithWorkdir("/workspace").
		WithMountedCache("/usr/local/cargo/registry", dag.CacheVolume("component-test-cargo-registry")).
		WithMountedCache("/usr/local/cargo/git", dag.CacheVolume("component-test-cargo-git")).
		WithDirectory("/workspace/backend",
			source.Directory("/backend", dagger.WorkspaceDirectoryOpts{
				Gitignore: true,
			}),
		).
		WithMountedCache("/workspace/backend/target", dag.CacheVolume("component-test-backend-target")).
		WithMountedCache("/workspace/backend/tests/component/target", dag.CacheVolume("component-test-host-target")).
		WithEnvVariable("CARGO_PROFILE_DEV_DEBUG", "0").
		WithEnvVariable("CARGO_PROFILE_TEST_DEBUG", "0").
		WithExec([]string{
			"cargo", "build",
			"--manifest-path", "backend/tests/component/Cargo.toml",
			"-p", "component-test-xtask",
		})
}

// BackendTest runs the full embedded component test suite.
func (m *Typewriter) BackendTest(source *dagger.Workspace) *dagger.Container {
	return m.backendTestContainer(source).
		WithExec([]string{componentTestXtask, "component-test", "--all", "--jobs", "2"})
}

// BackendTestFixture runs every case for one fixture.
func (m *Typewriter) BackendTestFixture(source *dagger.Workspace, fixture string) *dagger.Container {
	return m.backendTestContainer(source).
		WithExec([]string{componentTestXtask, "component-test", fixture, "--jobs", "2"})
}

// BackendTestCase runs cases matching a filter within one fixture.
func (m *Typewriter) BackendTestCase(source *dagger.Workspace, fixture string, filter string) *dagger.Container {
	return m.backendTestContainer(source).
		WithExec([]string{componentTestXtask, "component-test", fixture, filter, "--jobs", "1"})
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
		WithExec([]string{
			componentTestXtask, "component-test",
			"--affected-paths-file", "/tmp/component-test-changed-paths",
		}), nil
}

// BackendTestShard runs one deterministic full-suite shard.
func (m *Typewriter) BackendTestShard(source *dagger.Workspace, index int, count int) *dagger.Container {
	return m.backendTestContainer(source).
		WithExec([]string{
			componentTestXtask, "component-test", "--all",
			"--shard-index", strconv.Itoa(index),
			"--shard-count", strconv.Itoa(count),
		})
}
