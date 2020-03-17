#!/usr/bin/env bash
########
# Usage: create-instance.sh [volume, volume, ...]
#
# (requires the az and jq utilities)
########

cd "$(dirname "$0")"
NAME=srnd-nomad-agent-$(hexdump -n 4 -e '4/4 "%08x" 1 "\n"' /dev/random)

echo "Creating VM..."
if [ $# -ge 1 ]; then
  az vm create \
    --name $NAME \
    --tags role=nomad-agent \
    --image UbuntuLTS \
    --size ${SIZE:-Standard_D2_v3} \
    --admin-username srnd \
    --subscription 49f7105a-6649-48da-b7fd-97c41104d914 \
    --location northcentralus \
    --ssh-key-value id_rsa.pub \
    --resource-group srnd-nomad \
    --availability-set SRND-NOMAD-AGENT \
    --vnet-name srnd-nomad-vnet \
    --subnet default \
    --nsg srnd-nomad-agent-nsg \
    --assign-identity \
    --custom-data ../agents/cloud-init.yml \
    --attach-data-disks $@
else
  az vm create \
    --name $NAME \
    --tags role=nomad-agent \
    --image UbuntuLTS \
    --size Standard_D2_v3 \
    --admin-username srnd \
    --subscription 49f7105a-6649-48da-b7fd-97c41104d914 \
    --location northcentralus \
    --ssh-key-value id_rsa.pub \
    --resource-group srnd-nomad \
    --availability-set SRND-NOMAD-AGENT \
    --vnet-name srnd-nomad-vnet \
    --subnet default \
    --nsg srnd-nomad-agent-nsg \
    --assign-identity \
    --custom-data ../agents/cloud-init.yml
fi

sleep 3

echo "Assigning permissions..."
ASSIGNED_IDENTITY=$(az vm identity show --name $NAME --resource-group srnd-nomad | jq -r ".principalId")
az role assignment create \
  --role Reader \
  --assignee-object-id $ASSIGNED_IDENTITY \
  --scope /subscriptions/49f7105a-6649-48da-b7fd-97c41104d914
