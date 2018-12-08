#!/usr/bin/env bash
set -eux -o pipefail

nix build -f task.nix
tag=$(basename "$(readlink -f result)" | cut -d- -f1)
sudo docker load --input result

drv_closure=$(./instantiate-closure -E 'with (import <nixpkgs>) {}; runCommand "test" {} "echo hi >$out"')
DRV_OBJECT_KEY="$drv_closure"
aws s3 cp "$drv_closure" "s3://$DRV_BUCKET_NAME/$DRV_OBJECT_KEY"

set +x
sudo docker run -it --rm \
    --env AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION" \
    --env AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
    --env AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
    --env AWS_SESSION_TOKEN="$AWS_SESSION_TOKEN" \
    --env DRV_BUCKET_NAME="$DRV_BUCKET_NAME" \
    --env DRV_OBJECT_KEY="$DRV_OBJECT_KEY" \
    --env RESULT_BUCKET_NAME="$RESULT_BUCKET_NAME" \
    --env RESULT_OBJECT_KEY="$RESULT_OBJECT_KEY" \
    "nix-build/s3:$tag"
