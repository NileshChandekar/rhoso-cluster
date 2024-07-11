#!/bin/bash

## Global Variables
WORK_DIR_LOC="mirror-registry"
TARGET_DIR_LOC="mirror-registry"
LOC_MIRROR_REGISTRY="https://developers.redhat.com/content-gateway/rest/mirror/pub/openshift-v4/clients/mirror-registry/latest/mirror-registry.tar.gz"

## Download & untar mirror-registry.tar.gz
curl -L -O --create-dirs --output-dir $WORK_DIR_LOC $LOC_MIRROR_REGISTRY
tar -zxf $WORK_DIR_LOC/mirror-registry.tar.gz -C $WORK_DIR_LOC/

## Pre-requisites for mirror-registry.tar.gz
dnf install container-tools

## Install mirror registry as super user (sudo)
echo "./mirror-registry install --quayRoot /opt/quay-registry/ --quayStorage /var/lib/quay-registry/  --initUser quay-admin --init Password "redhat""

exit 0
