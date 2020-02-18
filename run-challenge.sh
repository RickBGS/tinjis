#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace


command -v jq >/dev/null 2>&1 || { echo "jq would improve the output of this script, but it's not installed." >&2; }


function show_invoices() {
    if $(hash jq); then
        curl --silent --fail --insecure --header 'Host: test.development.com' 'https://localhost/rest/v1/invoices' | jq '.[] | {invoice: .id, status: .status} | [.invoice, .status] | @sh'
    else
        curl --silent --fail --insecure --header 'Host: test.development.com' 'https://localhost/rest/v1/invoices' | grep --color status
    fi
}



# Ensure the environment is clean.
# Left overs from previous runs that have been interrupted are removed.
set +o errexit
make cleanup
set -o errexit

# Deploy all Kubernetes resources.
make setup

# Wait for Payments service to be ready.
echo "Waiting for $(kubectl get pods -n payments | grep payments-api | cut -d ' ' -f 1) to be ready…"
kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/name=Payments \
    -n payments \
    --timeout=60s
printf "\n"

# Wait for Antaeus service to be ready.
echo "Waiting for $(kubectl get pods -n antaeus | grep antaeus-api | cut -d ' ' -f 1) to be ready…"
kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/name=Antaeus \
    -n antaeus \
    --timeout=600s
printf "\n"


echo "Testing the Antaeus service…"
until $(curl --output /dev/null --silent --fail --insecure --header 'Host: test.development.com' 'https://localhost/rest/health'); do
    printf '.'
    sleep 2
done
printf "\n"

# Call payment URL until all invoices are paid
until $(curl --silent --show-error --fail --insecure --header 'Host: test.development.com' -XPOST 'https://localhost/rest/v1/invoices/pay'); do
    printf "INVOICES: "
    show_invoices
    printf "\n"

    sleep 1
done
show_invoices

# Clean up
make cleanup
