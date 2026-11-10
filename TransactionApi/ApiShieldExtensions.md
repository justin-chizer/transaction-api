# `ApiShieldExtensions.cs` — one file, one line, API Shield-ready

Reference for [`ApiShieldExtensions.cs`](ApiShieldExtensions.cs).

**The pitch:** Copy one file into your API, add one line to `Program.cs`, and your service
produces an OpenAPI spec that Cloudflare API Shield accepts and validates correctly. No
conversion scripts, no Node tooling, no hand-editing YAML, no per-service config.

```csharp
builder.Services.AddApiShieldReady();
```

That's the whole integration.

## The problem it solves

.NET 10 emits **OpenAPI 3.1** by default. Cloudflare API Shield (and most enterprise gateways)
only speak **3.0**. On top of that, the .NET generator produces a few quirks that make strict
validators reject *valid* traffic. If every team fixes this by hand, you get six different
half-right solutions. This file is the one right solution, written once.

## What it does under the hood (4 things)

1. **Emits OpenAPI 3.0** instead of 3.1 — the version API Shield requires.
2. **Cleans up request bodies** — removes the duplicate `text/json` / `text/plain` and the
   `application/*+json` wildcard that .NET auto-adds and that trips up schema validators.
3. **Fixes numeric & enum types** — .NET leaves `decimal` and enum properties without a `type`
   (and slaps a meaningless regex on decimals). This gives them the correct `type`, so client
   generators and edge validation don't choke.
4. **Forces lowercase routing** — API Shield matches request paths case-sensitively against your
   (lowercase) schema, so the served paths have to match.

## Why you can trust it in *your* service

- **It can't crash anything.** Everything runs at OpenAPI *document generation* time, not on the
  request path. Worst-case failure is a spec detail, never a downed service.
- **No app-specific code.** It keys off .NET types, not our models. Nothing in it knows or cares
  what your API does.
- **It's smart about your conventions.** String enums, numeric enums, nullable types — it detects
  the actual serialized form and does the right thing rather than assuming ours.
- **Zero friction.** It lives in the `Microsoft.Extensions.DependencyInjection` namespace, so the
  method just *appears* on `builder.Services` — no extra `using`, no wiring.

## The only two things you own

- Add `app.MapOpenApi();` to expose the spec endpoint.
- Set your real `servers` URL before uploading to Cloudflare (one optional callback):

  ```csharp
  builder.Services.AddApiShieldReady(o => o.AddDocumentTransformer((doc, _, _) =>
  {
      doc.Servers = [new() { Url = "https://api.example.com" }];
      return Task.CompletedTask;
  }));
  ```

**Requirement:** .NET 10 (uses the Microsoft.OpenApi 2.0 API).

## The 10-second version

> "It's a drop-in file — one line in `Program.cs` — that makes any .NET 10 API spit out a spec
> Cloudflare API Shield actually accepts. It runs at spec-generation time so it can't break your
> running service, and it has no app-specific code, so it's the same copy in every repo."
