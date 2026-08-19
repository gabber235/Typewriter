package databasecapabilities

import (
	"fmt"
	"path"
	"slices"
	"strings"

	"github.com/BurntSushi/toml"
)

type fileExists func(string) (bool, error)

type rawCapability struct {
	Files     []string `toml:"files"`
	DependsOn []string `toml:"depends_on"`
}

type rawSelection struct {
	Capabilities []string `toml:"capabilities"`
}

type rawManifest struct {
	Schema     map[string]rawCapability `toml:"schema"`
	Preset     map[string]rawSelection  `toml:"preset"`
	Deployment rawSelection             `toml:"deployment"`
}

type Manifest struct {
	schema      map[string]rawCapability
	schemaOrder []string
	presets     map[string]rawSelection
	deployment  rawSelection
}

func Parse(contents string, exists fileExists) (*Manifest, error) {
	var raw rawManifest
	metadata, err := toml.Decode(contents, &raw)
	if err != nil {
		return nil, fmt.Errorf("decode database capability manifest: %w", err)
	}
	if undecoded := metadata.Undecoded(); len(undecoded) > 0 {
		return nil, fmt.Errorf("unknown manifest key %q", undecoded[0].String())
	}

	manifest := &Manifest{
		schema:      raw.Schema,
		schemaOrder: declarationOrder(metadata.Keys(), "schema"),
		presets:     raw.Preset,
		deployment:  raw.Deployment,
	}
	if err := manifest.validate(exists); err != nil {
		return nil, err
	}
	return manifest, nil
}

func declarationOrder(keys []toml.Key, table string) []string {
	var order []string
	seen := make(map[string]struct{})
	for _, key := range keys {
		if len(key) < 2 || key[0] != table {
			continue
		}
		name := key[1]
		if _, found := seen[name]; found {
			continue
		}
		seen[name] = struct{}{}
		order = append(order, name)
	}
	return order
}

func (manifest *Manifest) validate(exists fileExists) error {
	if len(manifest.schema) == 0 {
		return fmt.Errorf("manifest must declare at least one schema capability")
	}
	if len(manifest.schemaOrder) != len(manifest.schema) {
		return fmt.Errorf("could not determine schema declaration order")
	}

	owners := make(map[string]string)
	for _, name := range manifest.schemaOrder {
		capability := manifest.schema[name]
		if strings.TrimSpace(name) == "" {
			return fmt.Errorf("schema capability identifier must not be blank")
		}
		if len(capability.Files) == 0 {
			return fmt.Errorf("schema capability %q must declare at least one file", name)
		}
		if err := rejectDuplicateStrings(capability.DependsOn, fmt.Sprintf("dependencies of schema capability %q", name)); err != nil {
			return err
		}
		for _, dependency := range capability.DependsOn {
			if _, found := manifest.schema[dependency]; !found {
				return fmt.Errorf("schema capability %q depends on unknown capability %q", name, dependency)
			}
		}
		for _, file := range capability.Files {
			if file == "" || path.Clean(file) != file || strings.HasPrefix(file, "../") || path.IsAbs(file) {
				return fmt.Errorf("schema capability %q contains invalid file %q", name, file)
			}
			if owner, duplicate := owners[file]; duplicate {
				return fmt.Errorf("schema file %q is declared by both %q and %q", file, owner, name)
			}
			owners[file] = name
			present, err := exists(file)
			if err != nil {
				return fmt.Errorf("check schema file %q: %w", file, err)
			}
			if !present {
				return fmt.Errorf("schema file %q does not exist", file)
			}
		}
	}

	if _, err := manifest.resolve(manifest.schemaOrder); err != nil {
		return err
	}
	for name, preset := range manifest.presets {
		if err := manifest.validateSelection("preset "+name, preset.Capabilities); err != nil {
			return err
		}
	}
	if err := manifest.validateSelection("deployment", manifest.deployment.Capabilities); err != nil {
		return err
	}
	full, found := manifest.presets["full"]
	if !found {
		return fmt.Errorf("manifest must declare preset %q", "full")
	}
	fullFiles, err := manifest.resolve(full.Capabilities)
	if err != nil {
		return err
	}
	deployedFiles, err := manifest.resolve(manifest.deployment.Capabilities)
	if err != nil {
		return err
	}
	if !sameSet(fullFiles, deployedFiles) {
		return fmt.Errorf("preset %q and deployment must resolve to the same schema files", "full")
	}
	return nil
}

func (manifest *Manifest) validateSelection(label string, capabilities []string) error {
	if len(capabilities) == 0 {
		return fmt.Errorf("%s must select at least one capability", label)
	}
	if err := rejectDuplicateStrings(capabilities, label+" capabilities"); err != nil {
		return err
	}
	for _, capability := range capabilities {
		if _, found := manifest.schema[capability]; !found {
			return fmt.Errorf("%s selects unknown capability %q", label, capability)
		}
	}
	return nil
}

func rejectDuplicateStrings(values []string, label string) error {
	seen := make(map[string]struct{})
	for _, value := range values {
		if _, duplicate := seen[value]; duplicate {
			return fmt.Errorf("%s contains duplicate %q", label, value)
		}
		seen[value] = struct{}{}
	}
	return nil
}

func (manifest *Manifest) resolve(roots []string) ([]string, error) {
	state := make(map[string]uint8)
	var stack []string
	var order []string
	var visit func(string) error
	visit = func(name string) error {
		switch state[name] {
		case 1:
			start := slices.Index(stack, name)
			cycle := append(slices.Clone(stack[start:]), name)
			return fmt.Errorf("schema capability dependency cycle: %s", strings.Join(cycle, " -> "))
		case 2:
			return nil
		}
		capability, found := manifest.schema[name]
		if !found {
			return fmt.Errorf("unknown schema capability %q", name)
		}
		state[name] = 1
		stack = append(stack, name)
		for _, dependency := range capability.DependsOn {
			if err := visit(dependency); err != nil {
				return err
			}
		}
		stack = stack[:len(stack)-1]
		state[name] = 2
		order = append(order, capability.Files...)
		return nil
	}
	for _, root := range roots {
		if err := visit(root); err != nil {
			return nil, err
		}
	}
	return order, nil
}

func (manifest *Manifest) DeploymentFiles() []string {
	files, err := manifest.resolve(manifest.deployment.Capabilities)
	if err != nil {
		panic("validated database capability manifest became invalid: " + err.Error())
	}
	return files
}

func (manifest *Manifest) PresetFiles(name string) ([]string, error) {
	preset, found := manifest.presets[name]
	if !found {
		return nil, fmt.Errorf("unknown schema preset %q", name)
	}
	return manifest.resolve(preset.Capabilities)
}

func sameSet(left, right []string) bool {
	if len(left) != len(right) {
		return false
	}
	seen := make(map[string]struct{}, len(left))
	for _, value := range left {
		seen[value] = struct{}{}
	}
	for _, value := range right {
		if _, found := seen[value]; !found {
			return false
		}
	}
	return true
}
