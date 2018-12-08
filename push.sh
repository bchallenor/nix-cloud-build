#!/usr/bin/env bash
set -eu -o pipefail

nix build -f task.nix

auth_token=$(aws ecr get-authorization-token)
creds=$(jq -er '.authorizationData[].authorizationToken' <<<"$auth_token" | base64 -d)
url=$(jq -er '.authorizationData[].proxyEndpoint | sub("^https://"; "")' <<<"$auth_token")

skopeo copy --dest-creds="$creds" docker-archive:result "docker://$url/stable/nix-build/s3"
