helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
k create namespace istio-system
helm install istio-base istio/base -n istio-system --set defaultRevision=default
helm install istiod istio/istiod -n  istio-system --wait
k create namespace istio-ingress
helm install istio-ingress istio/gateway -n istio-ingress -f values.yaml

k create namespace dev

# sql commands to prep the Azure SQL db
k run sqlcmd --image=mcr.microsoft.com/mssql-tools --restart=Never -n dev -- sleep 3600
k exec -it sqlcmd -n dev -- /bin/bash
#from the pod
