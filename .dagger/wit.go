package main

import (
	"context"
	"fmt"

	"dagger/typewriter/internal/dagger"
)

var witComponentDirs = []string{
	"backend/access/auth-callout",
	"backend/access/auth-sentinel",
	"backend/access/auth-typewriter-permissions",
	"backend/organization/organization-members",
	"backend/organization/organization-roles",
	"backend/organization/user-organization",
	"backend/service/identity",
	"backend/service/registration",
	"backend/wasmcloud-utils",
}

func (m *Typewriter) witChanges(source *dagger.Directory, ociConfig *dagger.Secret) *dagger.Changeset {
	return dag.Wash().WitFetchChanges(source, witComponentDirs, dagger.WashWitFetchChangesOpts{OciConfig: ociConfig})
}

// +generate
func (m *Typewriter) WitSync(
	// +optional
	// +defaultPath="/"
	// +ignore=["*", "!wkg.lock", "!.wasm-pkg/config.toml", "!backend/**/wkg.lock", "!backend/**/wit/**", "!backend/**/wasmcloud.toml", "!backend/**/Cargo.toml"]
	source *dagger.Directory,
	// Docker config.json used to authenticate WIT registry requests.
	// +optional
	ociConfig *dagger.Secret,
) (*dagger.Changeset, error) {
	return m.witChanges(source, ociConfig), nil
}

func (m *Typewriter) WitCheck(
	ctx context.Context,
	// +optional
	// +defaultPath="/"
	// +ignore=["*", "!wkg.lock", "!.wasm-pkg/config.toml", "!backend/**/wkg.lock", "!backend/**/wit/**", "!backend/**/wasmcloud.toml", "!backend/**/Cargo.toml"]
	source *dagger.Directory,
	// Docker config.json used to authenticate WIT registry requests.
	// +optional
	ociConfig *dagger.Secret,
) (*dagger.Changeset, error) {
	nestedLocks, err := source.Glob(ctx, "backend/**/wkg.lock")
	if err != nil {
		return nil, err
	}
	if len(nestedLocks) > 0 {
		return nil, fmt.Errorf("nested WIT locks are forbidden: %v", nestedLocks)
	}
	return m.witChanges(source, ociConfig), nil
}
