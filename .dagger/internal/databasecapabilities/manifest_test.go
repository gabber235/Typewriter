package databasecapabilities

import (
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

func existingFiles(files ...string) fileExists {
	set := make(map[string]struct{}, len(files))
	for _, file := range files {
		set[file] = struct{}{}
	}
	return func(file string) (bool, error) {
		_, found := set[file]
		return found, nil
	}
}

func validManifest() string {
	return `
[schema.kernel]
files = ["kernel.surql"]

[schema.application]
depends_on = ["kernel"]
files = ["application.surql"]

[preset.full]
capabilities = ["application"]

[deployment]
capabilities = ["application"]
`
}

func TestRejectsUnknownCapability(t *testing.T) {
	contents := strings.Replace(validManifest(), `capabilities = ["application"]`, `capabilities = ["missing"]`, 1)
	_, err := Parse(contents, existingFiles("kernel.surql", "application.surql"))
	if err == nil || !strings.Contains(err.Error(), `unknown capability "missing"`) {
		t.Fatalf("expected unknown capability error, got %v", err)
	}
}

func TestRejectsDependencyCycle(t *testing.T) {
	contents := strings.Replace(validManifest(), "[schema.kernel]\nfiles", "[schema.kernel]\ndepends_on = [\"application\"]\nfiles", 1)
	_, err := Parse(contents, existingFiles("kernel.surql", "application.surql"))
	if err == nil || !strings.Contains(err.Error(), "dependency cycle") {
		t.Fatalf("expected dependency cycle error, got %v", err)
	}
}

func TestRejectsDuplicateFile(t *testing.T) {
	contents := strings.Replace(validManifest(), `files = ["application.surql"]`, `files = ["kernel.surql"]`, 1)
	_, err := Parse(contents, existingFiles("kernel.surql"))
	if err == nil || !strings.Contains(err.Error(), `schema file "kernel.surql" is declared by both`) {
		t.Fatalf("expected duplicate file error, got %v", err)
	}
}

func TestRejectsMissingFile(t *testing.T) {
	_, err := Parse(validManifest(), existingFiles("kernel.surql"))
	if err == nil || !strings.Contains(err.Error(), `schema file "application.surql" does not exist`) {
		t.Fatalf("expected missing file error, got %v", err)
	}
}

func TestPreservesDependencyAndDeclarationOrder(t *testing.T) {
	manifest, err := Parse(validManifest(), existingFiles("kernel.surql", "application.surql"))
	if err != nil {
		t.Fatal(err)
	}
	got := manifest.DeploymentFiles()
	want := []string{"kernel.surql", "application.surql"}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("deployment files = %v, want %v", got, want)
	}
}

func TestRejectsDeploymentAndFullPresetMismatch(t *testing.T) {
	contents := strings.Replace(validManifest(), "[deployment]\ncapabilities = [\"application\"]", "[deployment]\ncapabilities = [\"kernel\"]", 1)
	_, err := Parse(contents, existingFiles("kernel.surql", "application.surql"))
	if err == nil || !strings.Contains(err.Error(), "same schema files") {
		t.Fatalf("expected deployment equality error, got %v", err)
	}
}

func TestRepositoryManifestDeclaresEverySchemaFile(t *testing.T) {
	databaseRoot := filepath.Join("..", "..", "..", "backend", "database")
	contents, err := os.ReadFile(filepath.Join(databaseRoot, "capabilities.toml"))
	if err != nil {
		t.Fatal(err)
	}
	manifest, err := Parse(string(contents), func(file string) (bool, error) {
		info, err := os.Stat(filepath.Join(databaseRoot, "schema", filepath.FromSlash(file)))
		if os.IsNotExist(err) {
			return false, nil
		}
		return err == nil && info.Mode().IsRegular(), err
	})
	if err != nil {
		t.Fatal(err)
	}
	var actual []string
	err = filepath.WalkDir(filepath.Join(databaseRoot, "schema"), func(path string, entry os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if !entry.IsDir() && filepath.Ext(path) == ".surql" {
			actual = append(actual, path)
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if len(manifest.DeploymentFiles()) != len(actual) {
		t.Fatalf("deployment declares %d files, schema directory contains %d", len(manifest.DeploymentFiles()), len(actual))
	}
}
