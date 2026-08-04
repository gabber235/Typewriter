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
