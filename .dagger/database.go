package main

import (
	"context"
	"dagger/typewriter/internal/dagger"
)

func (m *Typewriter) surrealkitContainer() *dagger.Container {
	return dag.Container().
		From("ghcr.io/surrealdb/surrealkit:latest")
}

func (m *Typewriter) surrealdbService() *dagger.Service {
	return dag.Container().
		From("surrealdb/surrealdb:latest").
		WithExposedPort(8000).
		AsService(dagger.ContainerAsServiceOpts{
			Args:          []string{"start", "--user", "root", "--pass", "root", "memory"},
			UseEntrypoint: true,
		})
}

// +check
func (m *Typewriter) DatabaseTest(
	ctx context.Context,
	source *dagger.Workspace,
) *dagger.Container {
	return m.surrealkitContainer().
		WithDirectory("/database", source.Directory("/backend/database", dagger.WorkspaceDirectoryOpts{
			Gitignore: true,
		})).
		WithServiceBinding("surrealdb", m.surrealdbService()).
		WithExec([]string{"surrealkit", "--host", "http://surrealdb:8000", "test"})
}
