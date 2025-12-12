# SurrealDB Component Library

This directory contains the `surrealdb-component` library - a Rust crate that WebAssembly components use to interact with SurrealDB through the `seamlezz:surrealdb@0.1.0` WIT interface.

## Architecture

The SurrealDB integration uses a two-part architecture:

1. **Host Plugin** (in `wash` runtime) - Implements the `seamlezz:surrealdb/call@0.1.0` interface and manages the actual SurrealDB connection
2. **Component Library** (`surrealdb-component`) - A Rust library that WASM components use to call the SurrealDB interface with a convenient API

## Directory Structure

```
surrealdb/
├── surrealdb-component/    # Library for WASM components to use
│   ├── src/lib.rs          # Query builder and result handling
│   └── wit/                # WIT interface definitions
├── component/              # Example/test component using surrealdb-component
└── wit/                    # Canonical WIT interface definition
```

## Usage

Components can use the `surrealdb-component` library to execute SurrealDB queries:

```rust
use surrealdb_component::query;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
struct User {
    name: String,
    email: Option<String>,
}

// Execute a query with bound parameters
let result = query("SELECT * FROM user WHERE name = $name")
    .bind("name", "Alice")
    .execute()?;

// Extract results
let users: Vec<User> = result.take(0)?;
```

## WIT Interface

The `seamlezz:surrealdb@0.1.0` interface defines a single function:

```wit
interface call {
    query: func(
        query: string, 
        params: list<tuple<string, list<u8>>>
    ) -> list<result<list<u8>, string>>;
}
```

- Parameters and results are CBOR-encoded for flexibility
- Multiple statements in a query return multiple results
- Each result is either the CBOR-encoded response or an error string

## Host Configuration

The wash runtime provides the SurrealDB plugin. Configure it with these environment variables or CLI flags:

| Environment Variable | CLI Flag | Description |
|---------------------|----------|-------------|
| `SURREALDB_URL` | `--surrealdb-url` | Connection URL (e.g., `ws://localhost:8000`) |
| `SURREALDB_NAMESPACE` | `--surrealdb-namespace` | Database namespace |
| `SURREALDB_DATABASE` | `--surrealdb-database` | Database name |
| `SURREALDB_AUTH` | `--surrealdb-auth` | Auth type: `root`, `namespace`, or `database` |
| `SURREALDB_USERNAME` | `--surrealdb-username` | Username for authentication |
| `SURREALDB_PASSWORD` | `--surrealdb-password` | Password for authentication |

## Building

```bash
# Build the component library
cd surrealdb-component
cargo build

# Build the test component
cd component
wash build
```
