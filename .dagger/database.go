package main

import (
	"context"
	"encoding/base64"
	"fmt"
	"sort"
	"strings"

	"dagger/typewriter/internal/dagger"
)

const (
	surrealkitImage        = "ghcr.io/surrealdb/surrealkit:0.6.3"
	kubectlImage           = "bitnami/kubectl:latest"
	fluxCliImage           = "ghcr.io/fluxcd/flux-cli:v2.6.4"
	defaultKubernetesAPI   = "https://host.docker.internal:6550"
	defaultLocalSurrealURL = "wss://surrealdb.local.seamlezz.net"
)

func (m *Typewriter) surrealkitContainer() *dagger.Container {
	return dag.Container().
		From(surrealkitImage)
}

func (m *Typewriter) surrealdbService() *dagger.Service {
	return dag.Container().
		From("surrealdb/surrealdb:v3.2.0").
		WithExposedPort(8000).
		AsService(dagger.ContainerAsServiceOpts{
			Args:          []string{"start", "--user", "root", "--pass", "root", "memory"},
			UseEntrypoint: true,
		})
}

// DatabaseImage packages the SurrealKit database folder into an immutable image.
// The image is used by Flux-managed Kubernetes Jobs, avoiding ConfigMap encoding
// of many schema, rollout, snapshot, and test files.
func (m *Typewriter) DatabaseImage(
	source *dagger.Workspace,
) *dagger.Container {
	backend := source.Directory("/backend", dagger.WorkspaceDirectoryOpts{
		Gitignore: true,
		Include: []string{
			"database/**",
			"surrealkit.toml",
		},
	})

	return dag.Container().
		From("alpine:3.20").
		WithExec([]string{"apk", "add", "--no-cache", "ca-certificates"}).
		WithFile("/usr/local/bin/surrealkit", m.surrealkitContainer().File("/usr/local/bin/surrealkit"), dagger.ContainerWithFileOpts{Permissions: 0o755}).
		WithDirectory("/workspace/backend", backend).
		WithWorkdir("/workspace/backend").
		WithEntrypoint([]string{"/usr/local/bin/surrealkit"})
}

func (m *Typewriter) DatabasePublish(
	ctx context.Context,
	source *dagger.Workspace,
	registry *dagger.Service,
	ref string,
	username string,
	password *dagger.Secret,
) (string, error) {
	if strings.TrimSpace(ref) == "" {
		return "", fmt.Errorf("ref is required")
	}
	return m.DatabaseImage(source).
		WithRegistryAuth(ref, username, password).
		Publish(ctx, ref, dagger.ContainerPublishOpts{
			RegistryService: registry,
		})
}

// +check
func (m *Typewriter) DatabaseTest(
	ctx context.Context,
	source *dagger.Workspace,
) *dagger.Container {
	return m.surrealkitContainer().
		WithDirectory("/backend/database", source.Directory("/backend/database", dagger.WorkspaceDirectoryOpts{
			Gitignore: true,
		})).
		WithWorkdir("/backend").
		WithServiceBinding("surrealdb", m.surrealdbService()).
		WithEnvVariable("SURREALDB_FOLDER", "database").
		WithExec([]string{"surrealkit", "--host", "http://surrealdb:8000", "test"})
}

// +check
func (m *Typewriter) DatabaseRolloutLint(
	ctx context.Context,
	source *dagger.Workspace,
) (*dagger.Container, error) {
	backend := source.Directory("/backend", dagger.WorkspaceDirectoryOpts{
		Gitignore: true,
		Include: []string{
			"database/**",
			"surrealkit.toml",
		},
	})

	rolloutsDirExists, err := backend.Exists(ctx, "database/rollouts", dagger.DirectoryExistsOpts{
		ExpectedType: dagger.ExistsTypeDirectoryType,
	})
	if err != nil {
		return nil, err
	}
	if !rolloutsDirExists {
		return dag.Container().From("alpine:3.20").WithExec([]string{"true"}), nil
	}

	entries, err := backend.Entries(ctx, dagger.DirectoryEntriesOpts{Path: "database/rollouts"})
	if err != nil {
		return nil, err
	}
	sort.Strings(entries)

	container := m.surrealkitContainer().
		WithDirectory("/workspace/backend", backend).
		WithWorkdir("/workspace/backend").
		WithEnvVariable("SURREALDB_FOLDER", "database")

	linted := false
	for _, entry := range entries {
		if !strings.HasSuffix(entry, ".toml") {
			continue
		}
		rolloutID := strings.TrimSuffix(entry, ".toml")
		container = container.WithExec([]string{"surrealkit", "rollout", "lint", rolloutID})
		linted = true
	}

	if !linted {
		return dag.Container().From("alpine:3.20").WithExec([]string{"true"}), nil
	}
	return container, nil
}

func (m *Typewriter) localKubectlContainer(
	kubeconfig *dagger.Secret,
	kubernetes *dagger.Service,
) *dagger.Container {
	container := dag.Container().
		From(kubectlImage).
		WithUser("0").
		WithMountedSecret("/root/.kube/config", kubeconfig, dagger.ContainerWithMountedSecretOpts{Mode: 0o600, Owner: "0:0"}).
		WithEnvVariable("KUBECONFIG", "/root/.kube/config")

	if kubernetes != nil {
		container = container.WithServiceBinding("host.docker.internal", kubernetes)
	}

	return container
}

func localKubectlArgs(kubernetesAPI string, args ...string) []string {
	if strings.TrimSpace(kubernetesAPI) == "" {
		kubernetesAPI = defaultKubernetesAPI
	}

	base := []string{
		"kubectl",
		"--server", kubernetesAPI,
		"--insecure-skip-tls-verify=true",
	}
	return append(base, args...)
}

func secretValue(ctx context.Context, kubectl *dagger.Container, key string, kubernetesAPI string) (string, error) {
	encoded, err := kubectl.WithExec(localKubectlArgs(
		kubernetesAPI,
		"-n", "surrealdb",
		"get", "secret", "surrealdb-root-credentials",
		"-o", fmt.Sprintf("jsonpath={.data.%s}", key),
	)).Stdout(ctx)
	if err != nil {
		return "", err
	}

	decoded, err := base64.StdEncoding.DecodeString(strings.TrimSpace(encoded))
	if err != nil {
		return "", fmt.Errorf("decode surrealdb-root-credentials %s: %w", key, err)
	}

	value := strings.TrimSpace(string(decoded))
	if value == "" {
		return "", fmt.Errorf("surrealdb-root-credentials %s is empty", key)
	}
	return value, nil
}

func (m *Typewriter) localClusterSurrealkit(
	ctx context.Context,
	source *dagger.Workspace,
	kubeconfig *dagger.Secret,
	// +optional
	kubernetes *dagger.Service,
	// +optional
	surrealdb *dagger.Service,
	// +optional
	endpoint string,
	// +optional
	kubernetesAPI string,
) (*dagger.Container, error) {
	if strings.TrimSpace(endpoint) == "" {
		endpoint = defaultLocalSurrealURL
	}

	kubectl := m.localKubectlContainer(kubeconfig, kubernetes)
	user, err := secretValue(ctx, kubectl, "username", kubernetesAPI)
	if err != nil {
		return nil, err
	}
	pass, err := secretValue(ctx, kubectl, "password", kubernetesAPI)
	if err != nil {
		return nil, err
	}

	backend := source.Directory("/backend", dagger.WorkspaceDirectoryOpts{
		Gitignore: true,
		Include: []string{
			"database/**",
			"surrealkit.toml",
		},
	})

	container := m.surrealkitContainer().
		WithDirectory("/workspace/backend", backend).
		WithWorkdir("/workspace/backend")
	if surrealdb != nil {
		container = container.WithServiceBinding("surrealdb.local.seamlezz.net", surrealdb)
	}
	return container.
		WithEnvVariable("SURREALDB_HOST", endpoint).
		WithEnvVariable("SURREALDB_NAMESPACE", "typewriter").
		WithEnvVariable("SURREALDB_NAME", "typewriter").
		WithEnvVariable("SURREALDB_AUTH_LEVEL", "root").
		WithSecretVariable("SURREALDB_USER", dag.SetSecret("local-surrealdb-root-user", user)).
		WithSecretVariable("SURREALDB_PASSWORD", dag.SetSecret("local-surrealdb-root-password", pass)), nil
}

func (m *Typewriter) DatabaseLocalSync(
	ctx context.Context,
	source *dagger.Workspace,
	kubeconfig *dagger.Secret,
	// +optional
	kubernetes *dagger.Service,
	// +optional
	surrealdb *dagger.Service,
	// +optional
	endpoint string,
	// +optional
	kubernetesAPI string,
	// +optional
	watch bool,
) (*dagger.Container, error) {
	container, err := m.localClusterSurrealkit(ctx, source, kubeconfig, kubernetes, surrealdb, endpoint, kubernetesAPI)
	if err != nil {
		return nil, err
	}

	args := []string{"surrealkit", "sync"}
	if watch {
		args = append(args, "--watch")
	}
	return container.WithExec(args), nil
}

func (m *Typewriter) DatabaseLocalSeed(
	ctx context.Context,
	source *dagger.Workspace,
	kubeconfig *dagger.Secret,
	// +optional
	kubernetes *dagger.Service,
	// +optional
	surrealdb *dagger.Service,
	// +optional
	endpoint string,
	// +optional
	kubernetesAPI string,
) (*dagger.Container, error) {
	container, err := m.localClusterSurrealkit(ctx, source, kubeconfig, kubernetes, surrealdb, endpoint, kubernetesAPI)
	if err != nil {
		return nil, err
	}
	return container.WithExec([]string{"surrealkit", "seed"}), nil
}

func (m *Typewriter) DatabaseLocalTest(
	ctx context.Context,
	source *dagger.Workspace,
	kubeconfig *dagger.Secret,
	// +optional
	kubernetes *dagger.Service,
	// +optional
	surrealdb *dagger.Service,
	// +optional
	endpoint string,
	// +optional
	kubernetesAPI string,
) (*dagger.Container, error) {
	container, err := m.localClusterSurrealkit(ctx, source, kubeconfig, kubernetes, surrealdb, endpoint, kubernetesAPI)
	if err != nil {
		return nil, err
	}
	return container.WithExec([]string{"surrealkit", "test"}), nil
}

func (m *Typewriter) DatabaseLocalStatus(
	ctx context.Context,
	source *dagger.Workspace,
	kubeconfig *dagger.Secret,
	// +optional
	kubernetes *dagger.Service,
	// +optional
	surrealdb *dagger.Service,
	// +optional
	endpoint string,
	// +optional
	kubernetesAPI string,
) (*dagger.Container, error) {
	container, err := m.localClusterSurrealkit(ctx, source, kubeconfig, kubernetes, surrealdb, endpoint, kubernetesAPI)
	if err != nil {
		return nil, err
	}
	return container.WithExec([]string{"surrealkit", "rollout", "status"}), nil
}

func fluxContainer(kubeconfig *dagger.Secret, kubernetes *dagger.Service) *dagger.Container {
	container := dag.Container().
		From(fluxCliImage).
		WithUser("0").
		WithMountedSecret("/root/.kube/config", kubeconfig, dagger.ContainerWithMountedSecretOpts{Mode: 0o600, Owner: "0:0"}).
		WithEnvVariable("KUBECONFIG", "/root/.kube/config")

	if kubernetes != nil {
		container = container.WithServiceBinding("host.docker.internal", kubernetes)
	}

	return container
}

func fluxAction(container *dagger.Container, name string) *dagger.Container {
	return container.WithExec([]string{"sh", "-lc", fmt.Sprintf(
		"flux resume kustomization %s -n flux-system && flux reconcile kustomization %s -n flux-system --with-source && flux suspend kustomization %s -n flux-system",
		name, name, name,
	)})
}

func (m *Typewriter) DatabaseProdStatus(
	kubeconfig *dagger.Secret,
	// +optional
	kubernetes *dagger.Service,
) *dagger.Container {
	return fluxContainer(kubeconfig, kubernetes).
		WithExec([]string{"sh", "-lc", "flux get kustomizations -n flux-system | grep -E 'typewriter-db|typewriter-backend'"})
}

func (m *Typewriter) DatabaseProdComplete(
	kubeconfig *dagger.Secret,
	rolloutID string,
	// +optional
	kubernetes *dagger.Service,
) (*dagger.Container, error) {
	if strings.TrimSpace(rolloutID) == "" {
		return nil, fmt.Errorf("rolloutID is required")
	}
	return fluxAction(fluxContainer(kubeconfig, kubernetes).WithEnvVariable("TYPEWRITER_DB_ROLLOUT_ID", rolloutID), "typewriter-db-complete"), nil
}

func (m *Typewriter) DatabaseProdRollback(
	kubeconfig *dagger.Secret,
	rolloutID string,
	// +optional
	kubernetes *dagger.Service,
) (*dagger.Container, error) {
	if strings.TrimSpace(rolloutID) == "" {
		return nil, fmt.Errorf("rolloutID is required")
	}
	return fluxAction(fluxContainer(kubeconfig, kubernetes).WithEnvVariable("TYPEWRITER_DB_ROLLOUT_ID", rolloutID), "typewriter-db-rollback"), nil
}

func (m *Typewriter) DatabaseProdRepair(
	kubeconfig *dagger.Secret,
	rolloutID string,
	// +optional
	kubernetes *dagger.Service,
) (*dagger.Container, error) {
	if strings.TrimSpace(rolloutID) == "" {
		return nil, fmt.Errorf("rolloutID is required")
	}
	return fluxAction(fluxContainer(kubeconfig, kubernetes).WithEnvVariable("TYPEWRITER_DB_ROLLOUT_ID", rolloutID), "typewriter-db-repair"), nil
}
