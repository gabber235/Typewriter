package main

import "dagger/typewriter/internal/dagger"

func (m *Typewriter) servicesGradleContainer(source *dagger.Workspace) *dagger.Container {
	services := source.Directory("/services", dagger.WorkspaceDirectoryOpts{Gitignore: true})

	return dag.Container().
		From("eclipse-temurin:21-jdk-noble").
		WithDirectory("/workspace/services", services).
		WithMountedCache("/root/.gradle/caches", dag.CacheVolume("services-gradle-caches")).
		WithMountedCache("/root/.gradle/wrapper", dag.CacheVolume("services-gradle-wrapper"))
}

// +check
func (m *Typewriter) ServicesCheck(source *dagger.Workspace) *dagger.Container {
	return m.servicesGradleContainer(source).
		WithWorkdir("/workspace/services").
		WithExec([]string{"./gradlew", "check", "ktlintCheck", "--no-daemon"}).
		WithExec([]string{"./gradlew", "-p", "imprint", "check", "ktlintCheck", "--no-daemon"})
}
