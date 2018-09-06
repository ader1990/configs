#!/bin/bash
# Azure automation script
# This script will clean containers in a storage account or blobls in a container
# Usage (container):
# ./clean_azure_storage.sh --resource container --account-name $STORAGE_ACCOUNT_NAME --partial-name "logs"
#
# Usage (blobs):
# ./clean_azure_storage.sh --resource blob --container_name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --partial-name "vhd"
#
# Note: IF --partial-name IS "" , THE SCRIPT WILL DELETE ALL CONTAINERS / BLOBS

set -e

resource=""
account_name=""
container_name=""
partial_name=""

while true;do
    case "$1" in
        --resource)
            resource="$2"
            shift 2;;
        --account-name)
            account_name="$2"
            shift 2;;
        --container-name)
            container_name="$2"
            shift 2;;
        --partial-name)
            partial_name="$2"
            shift 2;;   
        --) shift; break ;;
        *) break ;;
    esac
done

if [[ "$resource" == "" ]] || [[ "$account-name" ]];then
    exit 1
fi

if [[ "$resource" == "blob" ]];then
    if [[ "$container_name" != "" ]];then
        tagets="$(az storage blob list --container-name $container_name --account-name $account_name | grep name)"
    else
        echo "You need to specify a container name"
        exit 1
    fi
elif [[ "$resource" == "container" ]];then
    targets="$(az storage container list --account-name $account_name | grep name)"
fi

if [[ "$targets" == "" ]];then
    echo "Cannot find any resource"
    exit 1
else
    IFS=$'\n' targets=($targets)
fi

for target in "${targets[@]}" ;do
    target="${target#*: }"
    if [[ "$target" == *"$partial_name"* ]];then
        target="${boot%\"*}"
        target="${boot#*\"}"
        if [[ "$target" != "" ]];then
            if [[ "$resource" == "blob" ]];then
                az storage blob delete -c $container_name -n "$target" --account-name $account_name
            elif [[ "$resource" == "container" ]];then
                az storage container delete --name "$target" --account-name $account_name
            fi
        fi
    fi
done



