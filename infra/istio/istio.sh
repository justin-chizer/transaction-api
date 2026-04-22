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
ALTER ROLE db_ddladmin ADD MEMBER [aks-chizer-agentpool]; # This is because the cluster needs to run ef migration


#Helm for the transaction-api
helm install transaction-api infra/helm/transaction-api -n dev --set connectionString="Server=sql-server-chizer.database.windows.net;Database=BankingDb;Authentication=Active Directory Managed Identity;Encrypt=True;"


#Secrets for gateway
kubectl create secret generic cloudflare-origin-cert \
  -n istio-ingress \
  --from-file=tls.crt=origin.crt \
  --from-file=tls.key=origin.key \
  --from-file=ca.crt=authenticated_origin_pull_ca.pem
  
# Watch out for case sensitivity on Schema Validation

#Cloudflare Tunnel
helm repo add cloudflare https://cloudflare.github.io/helm-charts
helm repo update
kubectl create namespace cf-tunnel
helm install cloudflare-tunnel cloudflare/cloudflare-tunnel \
  -n cf-tunnel \
  -f infra/helm/cloudflare-tunnel/values.yaml

  2026-04-22T21:51:20Z ERR  error="Unable to reach the origin service. The service may be down or it may not be responding to traffic from cloudflared: dial tcp: lookup istio-gateway.istio-ingress.svc.cluster.local on 10.0.0.10:53: no such host" connIndex=3 event=1 ingressRule=0 originService=https://istio-gateway.istio-ingress.svc.cluster.local:443
2026-04-22T21:51:20Z ERR Request failed error="Unable to reach the origin service. The service may be down or it may not be responding to traffic from cloudflared: dial tcp: lookup istio-gateway.istio-ingress.svc.cluster.local on 10.0.0.10:53: no such host" connIndex=3 dest=https://chizer.dev.nationsbenefits.com/api/accounts event=0 ip=198.41.192.37 type=http


more logs

2026-04-22T21:59:02Z INF Starting tunnel tunnelID=ef84d242-e67d-4d4e-8d54-781cdc1584ef
2026-04-22T21:59:02Z INF Version 2026.3.0 (Checksum 4f15721f176cd8f6a9cfed7390d0b713538c829995923eda49fa82c7c974f403)
2026-04-22T21:59:02Z INF GOOS: linux, GOVersion: go1.24.13, GoArch: amd64
2026-04-22T21:59:02Z INF Settings: map[no-autoupdate:true token:*****]
2026-04-22T21:59:02Z INF Environmental variables map[TUNNEL_TOKEN:*****]
2026-04-22T21:59:02Z INF Generated Connector ID: 044b6e6b-6a22-4e8f-b0f1-dfbf139c278b
2026-04-22T21:59:02Z INF Initial protocol quic
2026-04-22T21:59:02Z INF ICMP proxy will use 10.244.0.2 as source for IPv4
2026-04-22T21:59:02Z INF ICMP proxy will use fe80::c4de:68ff:fe5e:9366 in zone eth0 as source for IPv6
2026-04-22T21:59:02Z WRN The user running cloudflared process has a GID (group ID) that is not within ping_group_range. You might need to add that user to a group within that range, or instead update the range to encompass a group the user is already in by modifying /proc/sys/net/ipv4/ping_group_range. Otherwise cloudflared will not be able to ping this network error="Group ID 65532 is not between ping group 1 to 0"
2026-04-22T21:59:02Z WRN ICMP proxy feature is disabled error="cannot create ICMPv4 proxy: Group ID 65532 is not between ping group 1 to 0 nor ICMPv6 proxy: socket: permission denied"
2026-04-22T21:59:02Z INF ICMP proxy will use 10.244.0.2 as source for IPv4
2026-04-22T21:59:02Z INF ICMP proxy will use fe80::c4de:68ff:fe5e:9366 in zone eth0 as source for IPv6
2026-04-22T21:59:02Z INF Starting metrics server on [::]:20241/metrics
2026-04-22T21:59:02Z INF Tunnel connection curve preferences: [X25519MLKEM768 CurveP256] connIndex=0 event=0 ip=198.41.200.13
2026/04/22 21:59:02 failed to sufficiently increase receive buffer size (was: 1024 kiB, wanted: 7168 kiB, got: 2048 kiB). See https://github.com/quic-go/quic-go/wiki/UDP-Buffer-Sizes for details.
2026-04-22T21:59:02Z INF Registered tunnel connection connIndex=0 connection=00088a2f-b878-4234-b708-e86aa99a8b5d event=0 ip=198.41.200.13 location=iad07 protocol=quic
2026-04-22T21:59:02Z INF Tunnel connection curve preferences: [X25519MLKEM768 CurveP256] connIndex=1 event=0 ip=198.41.192.227
2026-04-22T21:59:02Z INF Updated to new configuration config="{\"ingress\":[{\"hostname\":\"chizer.dev.nationsbenefits.com\", \"service\":\"https://istio-ingressgateway.istio-ingress.svc.cluster.local:443\"}, {\"service\":\"http_status:404\"}], \"warp-routing\":{\"enabled\":false}}" version=2
2026-04-22T21:59:02Z INF Registered tunnel connection connIndex=1 connection=1f613d9e-6ad3-4a44-a291-4560a583e776 event=0 ip=198.41.192.227 location=iad10 protocol=quic
2026-04-22T21:59:03Z INF Tunnel connection curve preferences: [X25519MLKEM768 CurveP256] connIndex=2 event=0 ip=198.41.200.43
2026-04-22T21:59:03Z INF Registered tunnel connection connIndex=2 connection=1d6a0e4f-ae18-4fcf-905d-369822053acf event=0 ip=198.41.200.43 location=iad05 protocol=quic
2026-04-22T21:59:04Z INF Tunnel connection curve preferences: [X25519MLKEM768 CurveP256] connIndex=3 event=0 ip=198.41.192.47
2026-04-22T21:59:04Z INF Registered tunnel connection connIndex=3 connection=b757f959-d8e1-437e-a86c-ed46cbca1e89 event=0 ip=198.41.192.47 location=iad16 protocol=quic
2026-04-22T21:59:53Z ERR  error="Unable to reach the origin service. The service may be down or it may not be responding to traffic from cloudflared: read tcp 10.244.0.2:50180->10.0.217.67:443: read: connection reset by peer" connIndex=3 event=1 ingressRule=0 originService=https://istio-ingressgateway.istio-ingress.svc.cluster.local:443
2026-04-22T21:59:53Z ERR Request failed error="Unable to reach the origin service. The service may be down or it may not be responding to traffic from cloudflared: read tcp 10.244.0.2:50180->10.0.217.67:443: read: connection reset by peer" connIndex=3 dest=https://chizer.dev.nationsbenefits.com/api/accounts event=0 ip=198.41.192.47 type=http
2026-04-22T21:59:00Z INF Starting tunnel tunnelID=ef84d242-e67d-4d4e-8d54-781cdc1584ef
2026-04-22T21:59:00Z INF Version 2026.3.0 (Checksum 4f15721f176cd8f6a9cfed7390d0b713538c829995923eda49fa82c7c974f403)
2026-04-22T21:59:00Z INF GOOS: linux, GOVersion: go1.24.13, GoArch: amd64
2026-04-22T21:59:00Z INF Settings: map[no-autoupdate:true token:*****]
2026-04-22T21:59:00Z INF Environmental variables map[TUNNEL_TOKEN:*****]
2026-04-22T21:59:00Z INF Generated Connector ID: dd8b8cbb-45c5-4cd3-a3b4-a4da9d8975f0
2026-04-22T21:59:00Z INF Initial protocol quic
2026-04-22T21:59:00Z INF ICMP proxy will use 10.244.2.121 as source for IPv4
2026-04-22T21:59:00Z INF ICMP proxy will use fe80::20a3:61ff:fe9e:3a89 in zone eth0 as source for IPv6
2026-04-22T21:59:00Z WRN The user running cloudflared process has a GID (group ID) that is not within ping_group_range. You might need to add that user to a group within that range, or instead update the range to encompass a group the user is already in by modifying /proc/sys/net/ipv4/ping_group_range. Otherwise cloudflared will not be able to ping this network error="Group ID 65532 is not between ping group 1 to 0"
2026-04-22T21:59:00Z WRN ICMP proxy feature is disabled error="cannot create ICMPv4 proxy: Group ID 65532 is not between ping group 1 to 0 nor ICMPv6 proxy: socket: permission denied"
2026-04-22T21:59:00Z INF ICMP proxy will use 10.244.2.121 as source for IPv4
2026-04-22T21:59:00Z INF ICMP proxy will use fe80::20a3:61ff:fe9e:3a89 in zone eth0 as source for IPv6
2026-04-22T21:59:00Z INF Starting metrics server on [::]:20241/metrics
2026-04-22T21:59:00Z INF Tunnel connection curve preferences: [X25519MLKEM768 CurveP256] connIndex=0 event=0 ip=198.41.192.77
2026/04/22 21:59:00 failed to sufficiently increase receive buffer size (was: 1024 kiB, wanted: 7168 kiB, got: 2048 kiB). See https://github.com/quic-go/quic-go/wiki/UDP-Buffer-Sizes for details.
2026-04-22T21:59:00Z INF Registered tunnel connection connIndex=0 connection=5b6f1444-ea6d-40ec-abed-74c0c5f9bcee event=0 ip=198.41.192.77 location=iad10 protocol=quic
2026-04-22T21:59:00Z INF Tunnel connection curve preferences: [X25519MLKEM768 CurveP256] connIndex=1 event=0 ip=198.41.200.193
2026-04-22T21:59:00Z INF Updated to new configuration config="{\"ingress\":[{\"hostname\":\"chizer.dev.nationsbenefits.com\", \"service\":\"https://istio-ingressgateway.istio-ingress.svc.cluster.local:443\"}, {\"service\":\"http_status:404\"}], \"warp-routing\":{\"enabled\":false}}" version=2
2026-04-22T21:59:01Z INF Registered tunnel connection connIndex=1 connection=5da29c52-ad3c-4fb0-8e03-fa687e6a7383 event=0 ip=198.41.200.193 location=iad08 protocol=quic
2026-04-22T21:59:01Z INF Tunnel connection curve preferences: [X25519MLKEM768 CurveP256] connIndex=2 event=0 ip=198.41.200.233
2026-04-22T21:59:02Z INF Registered tunnel connection connIndex=2 connection=3bf1ca93-84e0-4fc3-8453-8baf4be790de event=0 ip=198.41.200.233 location=iad14 protocol=quic
2026-04-22T21:59:02Z INF Tunnel connection curve preferences: [X25519MLKEM768 CurveP256] connIndex=3 event=0 ip=198.41.192.7
2026-04-22T21:59:03Z INF Registered tunnel connection connIndex=3 connection=d5e35036-ef57-4008-9b81-0e69f522b3ef event=0 ip=198.41.192.7 location=iad02 protocol=quic