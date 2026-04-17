# Banking API Demo

An enterprise-grade banking API built with .NET 10, demonstrating a production-ready architecture running on Azure Kubernetes Service (AKS) with Cloudflare API Shield, mTLS, OpenTelemetry, and DataDog observability.

---

## Architecture

```
Client
  └── mTLS (client cert)
        └── Cloudflare
              ├── API Shield (OpenAPI 3.0 request validation)
              ├── Cloudflare Worker (Ray ID + OTel ID injection)
              └── Cloudflare Tunnel
                    └── AKS Istio Gateway
                          └── .NET 10 API Pod
                                └── Azure SQL
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Runtime | .NET 10, ASP.NET Core |
| ORM | Entity Framework Core 10 |
| Database | Azure SQL |
| Container | Rancher Desktop (containerd) |
| Orchestration | Azure Kubernetes Service (AKS) |
| Service Mesh | Istio |
| Container Registry | Azure Container Registry (ACR) |
| Edge / Security | Cloudflare API Shield, Cloudflare Tunnels, mTLS |
| Observability | OpenTelemetry, DataDog |
| API Spec | OpenAPI 3.0.3 |

---

## Data Model

Two entities, three design principles:

```
Account                          Transaction
───────────────────────          ───────────────────────────────
id           guid (PK)           id             guid (PK)
owner        string              accountId      guid (FK)
balance      decimal(18,2)       type           Credit | Debit
createdAt    datetime            amount         decimal(18,2)  always positive
                                 description    string
                                 balanceBefore  decimal(18,2)
                                 balanceAfter   decimal(18,2)
                                 createdAt      datetime
```

**Design principles:**
- Transactions are immutable — never edited or deleted, only countered by new entries
- Amount is always positive — direction comes from `type`, not a negative sign
- Balance is snapshotted on every transaction so history is self-verifiable without replaying all records

---

## API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/accounts` | List all accounts |
| `POST` | `/api/accounts` | Create a new account |
| `GET` | `/api/accounts/{id}` | Get account by ID |
| `GET` | `/api/transactions/{accountId}` | Get transaction history for an account |
| `POST` | `/api/transactions/{accountId}/credit` | Credit an account |
| `POST` | `/api/transactions/{accountId}/debit` | Debit an account |

### Request bodies

**Create account:**
```json
{
  "owner": "Jane Smith"
}
```

**Credit / Debit:**
```json
{
  "amount": 500.00,
  "description": "Payroll deposit"
}
```

---

## Project Structure

```
transaction-api/
  ├── TransactionApi/
  │   ├── Controllers/
  │   │   ├── AccountsController.cs
  │   │   └── TransactionsController.cs
  │   ├── Data/
  │   │   ├── BankingDbContext.cs
  │   │   └── BankingDbContextFactory.cs
  │   ├── Migrations/
  │   ├── Models/
  │   │   ├── Account.cs
  │   │   ├── Transaction.cs
  │   │   └── TransactionRequest.cs
  │   ├── Dockerfile
  │   ├── Program.cs
  │   ├── appsettings.json
  │   ├── openapi.yaml            ← uploaded to Cloudflare API Shield
  │   ├── openapi.json
  │   ├── openapi.3.1.json        ← raw generated spec
  │   └── convert-openapi.js      ← converts 3.1 → 3.0, outputs JSON + YAML
  ├── dev.sh                      ← local dev reset script
  └── openapi-format.config.json
```

---

## Local Development

### Prerequisites

- .NET 10 SDK
- Rancher Desktop (containerd runtime)
- Node.js
- `dotnet-ef` CLI tools

```bash
dotnet tool install --global dotnet-ef
npm install -g openapi-format
```

### Run locally

**1. Start SQL Edge and the API in one command:**

```bash
./dev.sh
```

This stops all containers, starts Azure SQL Edge, runs a fresh build, and starts the API on `http://localhost:8080`.

**2. Apply migrations manually if needed:**

```bash
cd TransactionApi
dotnet ef database update
```

**3. Run without container:**

```bash
cd TransactionApi
dotnet run
```

API will be available at `http://localhost:5297`.

### Environment variables

| Variable | Description |
|---|---|
| `ASPNETCORE_ENVIRONMENT` | Set to `Development` to enable OpenAPI endpoint |
| `ConnectionStrings__DefaultConnection` | Azure SQL connection string |

---

## OpenAPI Spec

The spec is generated from the controllers and converted to OpenAPI 3.0.3 for Cloudflare API Shield.

### Regenerate the spec

**1. Start the API and export the raw spec:**

```bash
curl http://localhost:8080/openapi/v1.json -o TransactionApi/openapi.3.1.json
```

**2. Convert to OpenAPI 3.0.3 (JSON + YAML):**

```bash
cd TransactionApi
node convert-openapi.js
```

This outputs:
- `openapi.json` — OpenAPI 3.0.3 in JSON format
- `openapi.yaml` — OpenAPI 3.0.3 in YAML format, ready for Cloudflare API Shield

### Why OpenAPI 3.0 and not 3.1?

Cloudflare API Shield and most enterprise API gateways are built against OpenAPI 3.0. The .NET 10 generator outputs 3.1 natively, so the conversion script handles the downgrade automatically.

---

## Container

### Build

```bash
nerdctl build -t transaction-api:latest ./TransactionApi
```

### Run

```bash
nerdctl run \
  -e ASPNETCORE_ENVIRONMENT=Development \
  -e ConnectionStrings__DefaultConnection="Server=host.docker.internal,1433;Database=BankingDb;User Id=sa;Password=<password>;TrustServerCertificate=True" \
  -p 8080:8080 \
  transaction-api:latest
```

### Push to ACR

```bash
nerdctl tag transaction-api:latest <acr-name>.azurecr.io/transaction-api:latest
nerdctl push <acr-name>.azurecr.io/transaction-api:latest
```

---

## Security

### TLS lifecycle

```
Client → mTLS (client cert) → Cloudflare → Origin cert → AKS Istio Gateway → .NET pod
```

TLS is terminated at Cloudflare and re-established by Istio. The .NET pod operates inside the secure mesh and does not handle TLS directly. `UseHttpsRedirection` is intentionally removed.

### Cloudflare API Shield

The `openapi.yaml` is uploaded to Cloudflare API Shield which validates every incoming request at the edge against the schema before it reaches AKS. Invalid requests are rejected by Cloudflare — the pod never sees them.

---

## Observability

OpenTelemetry is configured to export traces to DataDog. A Cloudflare Worker injects the Cloudflare Ray ID and OTel trace ID into request headers so traces can be correlated end-to-end from the Cloudflare edge to the pod.

---

## Deployment

Target environment: AKS in namespace `prod` behind Cloudflare Tunnels.

Connection strings and secrets are managed via Kubernetes secrets and Azure Key Vault — never stored in `appsettings.json` or committed to source control.