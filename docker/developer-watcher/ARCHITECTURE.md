# Developer Watcher Architecture

## Overview

The Developer Watcher is a file-watching service that automatically builds, publishes, and deploys wasmCloud projects when changes are detected. It operates in distinct stages to ensure proper ordering of operations.

## Directory Structure

```
src/
├── main.rs          # Entry point and application initialization
├── config.rs        # Configuration constants and CLI argument parsing
├── project.rs       # Project enum and type definitions
├── discovery.rs     # Functions to discover projects and manifests
├── wash.rs          # Wash command execution wrapper
├── build.rs         # Project building logic
├── publish.rs       # Artifact publishing logic
├── deploy.rs        # Manifest deployment logic
├── pipeline.rs      # Multi-stage orchestration (build → publish → deploy)
└── watcher.rs       # File watching and change detection
```

## Module Responsibilities

### `config.rs`
- Defines all application constants (file names, extensions, patterns)
- Contains the `Config` struct with CLI arguments and environment variable bindings
- Central location for all configuration values

### `project.rs`
- Defines the `Project` enum (Component or Provider)
- Implements project metadata access methods (name, version, directory)
- Handles image reference generation for registry push operations

### `discovery.rs`
- `find_projects()`: Recursively searches for wasmCloud projects (by `wasmcloud.toml` marker)
- `find_all_deployment_manifests()`: Finds all `develop.wadm.yaml` files in the directory tree
- Sorts manifests by depth for breadth-first deployment (root level first)

### `wash.rs`
- `run_wash_command()`: Executes wash CLI commands with proper environment variables
- Handles command output, logging, and error reporting
- Validates credentials file existence before execution

### `build.rs`
- `build_project()`: Builds a single project using `wash build`
- Returns success/failure status without throwing errors on build failures
- Allows pipeline to continue with successful builds only

### `publish.rs`
- `push_project()`: Scans build directory for artifacts and pushes to registry
- Handles both component (`.wasm`) and provider (`.par.gz`) artifacts
- Supports insecure registry connections via configuration

### `deploy.rs`
- `deploy_manifest()`: Deploys a single wadm manifest using `wash app deploy --replace`
- Simple wrapper around wash deployment command

### `pipeline.rs`
- **Stage-based orchestration** of the entire build/deploy workflow
- `build_all_projects()`: Stage 1 - Builds all projects, collects successful ones
- `publish_all_projects()`: Stage 2 - Publishes all successfully built projects
- `deploy_all_manifests()`: Stage 3 - Deploys all manifests in order
- `rebuild_and_redeploy_all()`: Combines all three stages in sequence

### `watcher.rs`
- Sets up file system watching with debouncing
- Filters relevant file changes (ignores build artifacts, node_modules, etc.)
- Maps changed files to their containing projects
- Triggers rebuild/redeploy pipeline for changed projects

### `main.rs`
- Initializes tracing/logging
- Parses configuration
- Performs initial discovery of projects and manifests
- Runs initial build/publish/deploy cycle
- Starts file watcher for continuous monitoring

## Execution Flow

### Initial Startup
1. **Stage 0: Collection**
   - Discover all projects in the base directory
   - Find all `develop.wadm.yaml` files (sorted by depth)
   - Log discovery results

2. **Stage 1: Build**
   - Build all discovered projects
   - Track successful builds
   - Continue on individual build failures

3. **Stage 2: Publish**
   - Push artifacts from all successfully built projects
   - Each project's artifacts uploaded to registry

4. **Stage 3: Deploy**
   - Deploy all wadm manifests in breadth-first order
   - Root-level manifests deployed first

5. **Watch Mode**
   - Monitor all project directories for changes
   - React to file modifications

### File Change Response
When relevant files change:
1. Detect which project(s) contain the changed files
2. Run full pipeline (build → publish → deploy) for changed projects
3. Deploy **all** manifests (not just those related to changed projects)
4. Continue watching

## Key Design Decisions

### Separation of Stages
All projects are built before any publishing begins, and all publishing completes before deployment starts. This ensures:
- Consistent state across the system
- Easier debugging (clear stage boundaries)
- Better error isolation

### Manifest Discovery
All `develop.wadm.yaml` files are discovered independently of projects, allowing:
- Manifests at any directory level
- Multiple manifests per project
- Shared manifests across projects
- Breadth-first deployment order (root to leaf)

### Error Handling
- Build failures don't halt the pipeline; successful builds continue
- Publish and deploy errors are logged but don't stop other operations
- Allows partial success rather than all-or-nothing

### Debouncing
File system changes are debounced (default 1000ms) to avoid:
- Repeated builds from multiple rapid file saves
- Resource contention during active development
- Unnecessary processing of intermediate states

## Configuration

All configuration is via environment variables or CLI flags:
- `WDEV_PROJECTS_BASE_DIR`: Root directory to search for projects
- `WASH_NATS_HOST`: NATS server hostname
- `WASH_NATS_PORT`: NATS server port
- `WASH_REGISTRY`: Container registry URL
- `WASH_REGISTRY_INSECURE`: Allow insecure registry connections
- `WASMCLOUD_CTL_HOST`: wasmCloud control plane host
- `WASMCLOUD_CTL_PORT`: wasmCloud control plane port
- `WDEV_DEBOUNCE_MS`: File watcher debounce delay

## Extension Points

To add new functionality:
- **New build step**: Add function to `pipeline.rs` and call in sequence
- **New project type**: Extend `Project` enum in `project.rs`
- **Custom filtering**: Modify `is_relevant_change()` in `watcher.rs`
- **Additional discovery**: Add functions to `discovery.rs`
