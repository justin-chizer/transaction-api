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
  │   ├── Program.cs              ← calls builder.Services.AddApiShieldReady()
  │   ├── ApiShieldExtensions.cs  ← drop-in API Shield config (OpenAPI 3.0 + lowercase routing)
  │   ├── appsettings.json
  │   └── openapi.json            ← OpenAPI 3.0, uploaded to Cloudflare API Shield
  └── dev.sh                      ← local dev reset script
```

---

## Local Development

### Prerequisites

- .NET 10 SDK
- Rancher Desktop (containerd runtime)
- `dotnet-ef` CLI tools

```bash
dotnet tool install --global dotnet-ef
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

The spec is generated directly from the controllers as OpenAPI 3.0, ready for Cloudflare API Shield — no conversion script. All the configuration lives in one drop-in file, [`ApiShieldExtensions.cs`](TransactionApi/ApiShieldExtensions.cs), and `Program.cs` wires it up with a single call:

```csharp
builder.Services.AddApiShieldReady();
```

### Regenerate the spec

Start the API and save the document:

```bash
curl http://localhost:8080/openapi/v1.json -o TransactionApi/openapi.json
```

That single file is what the dev team consumes for client generation, what's uploaded to Cloudflare API Shield, and what the Redoc docs render (`infra/rdocly/openapi.json`).

### Make another .NET 10 API API-Shield-ready

`ApiShieldExtensions.cs` is self-contained and has no app-specific code, so adopting it elsewhere is two steps:

1. Copy `ApiShieldExtensions.cs` into the target project.
2. Call `builder.Services.AddApiShieldReady();` in its `Program.cs`.

That's it — no extra `using` (the file lives in the `Microsoft.Extensions.DependencyInjection` namespace). `AddApiShieldReady()` bundles both things API Shield requires; the pieces are also exposed individually (`AddApiShieldOpenApi()`, `AddLowercaseRouting()`) if a service only needs one.

> Set the API's real `servers` URL before uploading the schema to Cloudflare — by default it's the request URL (`localhost:8080`). Pass a transformer to the optional callback:
> ```csharp
> builder.Services.AddApiShieldReady(o => o.AddDocumentTransformer((doc, _, _) =>
> {
>     doc.Servers = [new() { Url = "https://api.example.com" }];
>     return Task.CompletedTask;
> }));
> ```

### What `AddApiShieldReady()` does, and why

API Shield validates each incoming request against the uploaded schema at the edge, so the schema must be both **3.0** and an **exact match** for what the API serves:

| Step | Reason |
|---|---|
| Emit **OpenAPI 3.0** (not the .NET 10 default 3.1) | API Shield and most gateways are built against 3.0. The framework serializer handles the downgrade, including `type: [..,"null"]` → `nullable: true`. |
| Strip `text/json`, `application/*+json`, `text/plain` request bodies | The `application/*+json` wildcard trips up strict schema validators; the others are redundant noise. |
| Give `decimal`/enum schemas an explicit `type` | The .NET generator omits `type` on those (and adds a meaningless regex `pattern` to decimals), which breaks client generators and can cause valid payloads to be rejected. |
| **Lowercase routing** (`LowercaseUrls` + `LowercaseQueryStrings`) | API Shield matches request paths to schema operations case-sensitively. The documented paths are lowercase, so the served paths must be too. |

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

The `openapi.json` is uploaded to Cloudflare API Shield which validates every incoming request at the edge against the schema before it reaches AKS. Invalid requests are rejected by Cloudflare — the pod never sees them.

---

## Observability

OpenTelemetry is configured to export traces to DataDog. A Cloudflare Worker injects the Cloudflare Ray ID and OTel trace ID into request headers so traces can be correlated end-to-end from the Cloudflare edge to the pod.

---

## Deployment

Target environment: AKS in namespace `prod` behind Cloudflare Tunnels.

Connection strings and secrets are managed via Kubernetes secrets and Azure Key Vault — never stored in `appsettings.json` or committed to source control.