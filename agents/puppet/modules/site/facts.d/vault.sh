#!/usr/bin/env bash
META=$(curl -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2019-08-15" 2>/dev/null)
ROLE=$(echo $META | jq -r '.compute.tagsList[] | select(.name == "role").value')
SUBSCRIPTION_ID=$(echo $META | jq -r .compute.subscriptionId)
VM_NAME=$(echo $META | jq -r .compute.name)
RESOURCE_GROUP_NAME=$(echo $META | jq -r .compute.resourceGroupName)

JWT=$(curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=http%3A%2F%2Fvault.srnd.cloud' -H Metadata:true | jq -r '.access_token' 2>/dev/null)
JSON="{\"role\": \"nomad-server\", \"jwt\": \"$JWT\", \"subscription_id\": \"$SUBSCRIPTION_ID\", \"resource_group_name\": \"$RESOURCE_GROUP_NAME\", \"vm_name\": \"$VM_NAME\"}"

VAULT_TOKEN=$(curl --request POST --data "$JSON"  http://vault.srnd.cloud:8200/v1/auth/azure/login 2>/dev/null | jq -r '.auth.client_token')
VAULT_RESP=$(curl --header "X-Vault-Token: $VAULT_TOKEN" http://vault.srnd.cloud:8200/v1/kv/data/nomad-agent 2>/dev/null)

echo $VAULT_RESP | jq -r ".data.data|to_entries|map(\"vault_\(.key)=\(.value|tostring)\")|.[]"
