helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
k create namespace istio-system
helm install istio-base istio/base -n istio-system --set defaultRevision=default
helm install istiod istio/istiod -n  istio-system --wait
k create namespace istio-ingress
helm install istio-ingress istio/gateway -n istio-ingress -f values.yaml

k create namespace dev

# sql commands to prep the Azure SQL db run from the Azure Portal Query Editor or Azure Data Studio
CREATE USER [aks-chizer-agentpool] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [aks-chizer-agentpool];
ALTER ROLE db_datawriter ADD MEMBER [aks-chizer-agentpool];