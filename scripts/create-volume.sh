#!/usr/bin/env bash

if [ $# -ne 2 ]
  then
    echo "Argument error: please ensure command matches the following format:"
    echo "create-volume.sh [NAME] [SIZE IN GiB]"
    exit 1
fi
SIZE=`echo "x=l($2-0.1)/l(2); scale=0; 2^((x+1)/1)" | bc -l;` # Round to next power of 2 for billing.
echo "Creating disk $1 with $SIZE gb"
az disk create \
  --name srnd-nomad-volume-$1 \
  --resource-group srnd-nomad \
  --tags volume=$1 \
  --size-gb $SIZE \
  --location northcentralus \
  --subscription 49f7105a-6649-48da-b7fd-97c41104d914
