#!/usr/bin/env bash
set -eu -o pipefail

vpc=stable
subnet=stable-private
security_group=https-client

vpc_id=$(aws ec2 describe-vpcs --filter "Name=tag:Name,Values=$vpc" | jq -er '.Vpcs[].VpcId')
subnet_id=$(aws ec2 describe-subnets --filter "Name=vpc-id,Values=$vpc_id" "Name=tag:Name,Values=$subnet" | jq -er '.Subnets[].SubnetId')
security_group_id=$(aws ec2 describe-security-groups --filter "Name=vpc-id,Values=$vpc_id" "Name=group-name,Values=$security_group" | jq -er '.SecurityGroups[].GroupId')

revision=$(aws ecs describe-task-definition --task-definition nix-build-s3 | jq -er '.taskDefinition.revision')

overrides=$(jq '.containerOverrides[].environment |= map(. + { value: env[.name] })' <<EOF
{
  "containerOverrides": [
    {
      "name": "nix-build-s3",
      "environment": [
        {
          "name": "DRV_BUCKET_NAME"
        },
        {
          "name": "DRV_OBJECT_KEY"
        },
        {
          "name": "RESULT_BUCKET_NAME"
        },
        {
          "name": "RESULT_OBJECT_KEY"
        }
      ]
    }
  ]
}
EOF
)

aws ecs run-task --task "nix-build-s3:$revision" --cluster nix-build --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[$subnet_id],securityGroups=[$security_group_id],assignPublicIp=DISABLED}" --overrides "$overrides"
