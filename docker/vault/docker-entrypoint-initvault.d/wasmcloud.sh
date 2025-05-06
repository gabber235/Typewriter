#!/bin/sh

vault auth enable -path=jwt jwt

vault write auth/jwt/config jwks_url="http://secrets-vault:3456/.well-known/keys"
vault write auth/jwt/role/auth-callout-role @docker-entrypoint-initvault.d/auth-callout-role.json

vault policy write auth-callout-role-policy - << EOF
# Dev servers have version 2 of KV secrets engine mounted by default, so will
# need this path to grant permissions:
path "secret/*" {
  capabilities = ["create", "update", "read"]
}
EOF


# As this is only used for development, and everything is ephemeral, we can store it as plaintext.

vault kv put secret/nats/auth jwt="eyJ0eXAiOiJKV1QiLCJhbGciOiJlZDI1NTE5LW5rZXkifQ.eyJqdGkiOiI0QUtOS1JURkZCR1FTWVJSQ1lVN1YyNkFZMlNIUFAySEFWVFhWNE41UlhITjVFVE4zNTRBIiwiaWF0IjoxNzQ1NzI4MDM0LCJpc3MiOiJBQlU2SFRaTEpETUU3TFBHU0xBVkdNSjJXS0Y1TUlOQzZKTlRIR0JLMlFKRzJRNjVKUkU0VEFOUSIsIm5hbWUiOiJ3YXNtY2xvdWQiLCJzdWIiOiJVQVNKVFVJT0tGWU1CNklGRUVETjdGTURUUFlBWUw0QjVLNVlNT1FLMllSTTJJQk5TSUVQSUJEVSIsIm5hdHMiOnsicHViIjp7fSwic3ViIjp7fSwic3VicyI6LTEsImRhdGEiOi0xLCJwYXlsb2FkIjotMSwiaXNzdWVyX2FjY291bnQiOiJBQ05BWVZJQVZNQ0FVU0c1NUg2WUhXT0dRVlUzQUhNRVoyNFBYNVVPMkEyNkYzTUZBSVFSM0dGSyIsInR5cGUiOiJ1c2VyIiwidmVyc2lvbiI6Mn19.weoQo4WJpaSt33wEFe9Nv37d8TNqK-k6VkQgiGe3UbZlWi990SwYgOk9J9mwwlei6vK2eKogOInxY2PLwgrEDg" seed="SUADJWVMIVBGVBRGAAVQDLPAQQREXNXRVCHLJ22UW3J6JL3LX2CIM3CRHA"

vault kv put secret/nats/auth-callout/issuer seed="SAAHONUWV3R4RXI3SGIQ4K6EKL5RRFANSOU6EW36453FIRNA6XBW5S2VGI"

vault kv put secret/nats/auth-callout/signing-keys typewriter="SAAAVHDUSPVSBCKCFO5GGF26YEBLK3QXZCO3V5CPKW2KB65ZNZ5VEFNP44"
