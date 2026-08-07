# Realm

Realm has explicit local and production launch profiles, following the panel configuration model.

## Local

```shell
./gradlew runLocal
```

This loads `config/local.properties`.

## Production

```shell
./gradlew runProduction
```

This loads `config/production.properties`.

System properties and environment variables override values from the selected profile. For example:

```shell
API_BASE_URL=https://api.example.test ./gradlew runLocal
```

Plain `./gradlew run` remains available and uses the application defaults.

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
