#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

command -v jq >/dev/null 2>&1 || { echo "jq would improve the output of this script, but it's not installed." >&2; }


function show_invoices() {
    if $(hash jq); then
        curl --silent --fail 'http://localhost:8080/rest/v1/invoices' | jq '.[] | {invoice: .id, status: .status} | [.invoice, .status] | @sh'
    else
        curl --silent --fail 'http://localhost:8080/rest/v1/invoices' | grep --color status
    fi
}



set +o errexit
kubectl delete -f ./kubernetes/payments.yaml 2>/dev/null
kubectl delete -f ./kubernetes/antaeus.yaml 2>/dev/null
set -o errexit


# Build and publish images
# docker-compose build --pull
# for image in antaeus payments; do
#     docker tag ${image} rickbgs/tinjis-${image}:demo
#     docker push rickbgs/tinjis-${image}:demo
# done

# Deploy Payments Service
kubectl create -f ./kubernetes/payments.yaml
sleep 2
echo "Waiting for $(kubectl get pods -n payments | grep payments-api | cut -d ' ' -f 1) to be ready…"
kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/name=Payments \
    -n payments \
    --timeout=60s

# Deploy Antaeus Service
kubectl create -f ./kubernetes/antaeus.yaml
echo "Waiting for Antaeus service to be ready…"
until $(curl --output /dev/null --silent --fail 'http://localhost:8080/rest/health'); do
    printf '.'
    sleep 2
done
printf "\n"

# Call payment URL until all invoices are paid
show_invoices
until $(curl --silent --show-error --fail -XPOST 'http://localhost:8080/rest/v1/invoices/pay'); do
    printf "INVOICES: "
    show_invoices
    printf "\n\n"

    sleep 1
done

# Clean up
kubectl delete -f ./kubernetes/payments.yaml
kubectl delete -f ./kubernetes/antaeus.yaml
