#!/bin/bash

## Global Variables
HOSTNAME=`hostname -f`
RANDOM_NUMBER=`date | md5sum`
REGISTRY_NAME="local-registry"
REGISTRY_USERNAME="registry-admin"
REGISTRY_PASSWORD="redhat"

## Pre-Reqesites
mkdir -p /data/registry/{auth,certs,data}
dnf install podman container-tools httpd-tools

## Create Local Certificates
openssl req -newkey rsa:4096 -nodes -sha256 \
-keyout /data/registry/certs/$HOSTNAME.key -x509 -days 3650 \
-out /data/registry/certs/$HOSTNAME.crt \
-subj "/C=US/ST=NorthCarolina/L=Raleigh/O=Red Hat/OU=Engineering/CN=$HOSTNAME" \
-addext "subjectAltName = DNS:$HOSTNAME"

cp /data/registry/certs/$HOSTNAME.crt /etc/pki/ca-trust/source/anchors/

update-ca-trust

## Generate Local Registry Admin Username & Password
htpasswd -bBc /data/registry/auth/htpasswd $REGISTRY_USERNAME $REGISTRY_PASSWORD

## Create Local Registry 
podman create --replace --name $REGISTRY_NAME --net host -p 5000:5000 \
   -v /data/registry/data:/var/lib/registry:z -v /data/registry/auth:/auth:z \
   -e "REGISTRY_AUTH=htpasswd" -e "REGISTRY_AUTH_HTPASSWD_REALM=$REGISTRY_NAME" \
   -e "REGISTRY_HTTP_SECRET=$RANDOM_NUMBER" \
   -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd -v /data/registry/certs:/certs:z \
   -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/$HOSTNAME.crt \
   -e REGISTRY_HTTP_TLS_KEY=/certs/$HOSTNAME.key docker.io/library/registry:2

## Create Local Registry Service
cat << EOF > /etc/systemd/system/${REGISTRY_NAME}.service
[Unit]
Description=RHOCP Registry
[Service]
Restart=always
ExecStart=/usr/bin/podman start -a $REGISTRY_NAME
ExecStop=/usr/bin/podman stop -t 10 $REGISTRY_NAME
[Install]
WantedBy=network-online.target
EOF

## Start Local Registry
systemctl daemon-reload
systemctl enable --now $REGISTRY_NAME
systemctl daemon-reload
systemctl status $REGISTRY_NAME --no-pager

##  Authentication
echo
echo "### Try Me ###"
echo
echo "curl -k -u '$REGISTRY_USERNAME:$REGISTRY_PASSWORD' https://$HOSTNAME:5000/v2/_catalog"
echo "podman login -u $REGISTRY_USERNAME  -p  $REGISTRY_PASSWORD $HOSTNAME:5000"
echo
echo "##############"
exit 0
