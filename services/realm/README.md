# Realm

Realm is a loader managed deployment and does not expose a process entry point. The standalone and Paper loaders own
its startup, replacement, and shutdown lifecycle.

## Development

```shell
build-logic/gradlew devStandalone
```

Run this command from the `services` directory. It builds the Realm artifact and starts the standalone loader. The local
loader requires a deployment source before it can select and start child runtimes.

Realm and loader settings use separate properties files through the loader process environment:

```shell
LOADER_CONFIG_FILE=loader/standalone/config/local.properties REALM_CONFIG_FILE=realm/config/local.properties build-logic/gradlew devStandalone
```

System properties and environment variables override values from that file.

## Database

Realm uses an embedded, persistent, versioned SurrealKV database by default:

```properties
REALM_DB_ENDPOINT_TYPE=embedded
REALM_DB_ENGINE=surrealkv
REALM_DB_PATH=database/realm
REALM_DB_NAMESPACE=typewriter
REALM_DB_DATABASE=realm
REALM_DB_AUTHENTICATION=none
```

Embedded databases always enable versioned storage. Set `REALM_DB_RETENTION` to bound retained history.
The embedded engine may be `memory`, `surrealkv`, or `rocksdb`. The pinned Java SDK currently lacks RocksDB
support, so selecting it produces an explicit startup error.

Remote HTTP and WebSocket databases remain available:

```properties
REALM_DB_ENDPOINT_TYPE=remote
REALM_DB_URL=wss://database.example.com
REALM_DB_NAMESPACE=typewriter
REALM_DB_DATABASE=realm
REALM_DB_AUTHENTICATION=database
REALM_DB_USERNAME=realm
REALM_DB_PASSWORD=secret
```

Authentication may be `none`, `root`, `namespace`, `database`, or `bearer`. Bearer authentication reads
`REALM_DB_TOKEN`.
