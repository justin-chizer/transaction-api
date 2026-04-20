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
sqlcmd -S <your-server>.database.windows.net \
  -d BankingDb \
  -G \
  -Q "
CREATE USER [<managed-identity-display-name>] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [<managed-identity-display-name>];
ALTER ROLE db_datawriter ADD MEMBER [<managed-identity-display-name>];
"

curl -LO https://github.com/microsoft/go-sqlcmd/releases/download/v1.8.2/sqlcmd-v1.8.2-linux-amd64.tar.bz2
tar -xjf sqlcmd-v1.8.2-linux-amd64.tar.bz2
chmod +x sqlcmd

./sqlcmd -S <your-server>.database.windows.net \
  -d BankingDb \
  --authentication-method ActiveDirectoryManagedIdentity \
  -Q "SELECT 1"