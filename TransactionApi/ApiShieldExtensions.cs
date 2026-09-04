using Microsoft.AspNetCore.OpenApi;
using Microsoft.OpenApi;
using System.Text.Json.Nodes;

namespace Microsoft.Extensions.DependencyInjection;

/// <summary>
/// Drop-in configuration that makes an ASP.NET Core (.NET 10) API ready for Cloudflare API Shield.
///
/// Usage — copy this single file into any API project and call ONE line:
///
///     builder.Services.AddApiShieldReady();
///
/// It bundles the two things API Shield requires:
///   1. An OpenAPI 3.0 document (API Shield rejects 3.1) whose schema validators and client
///      generators consume cleanly.
///   2. Lowercase routing. API Shield matches each request's path against a schema operation
///      case-sensitively; since the documented paths are lowercase, the served paths must be too,
///      or otherwise-valid requests look non-conforming at the edge.
///
/// The file lives in the Microsoft.Extensions.DependencyInjection namespace on purpose, so the
/// method appears on builder.Services with no extra <c>using</c> directives, and contains no
/// app-specific logic, so it is safe to reuse verbatim across services.
/// </summary>
public static class ApiShieldExtensions
{
    /// <summary>Registers everything Cloudflare API Shield requires: OpenAPI 3.0 + lowercase routing.</summary>
    public static IServiceCollection AddApiShieldReady(
        this IServiceCollection services,
        Action<OpenApiOptions>? configureOpenApi = null)
    {
        services.AddApiShieldOpenApi(configureOpenApi);
        services.AddLowercaseRouting();
        return services;
    }

    /// <summary>
    /// Registers an OpenAPI 3.0 document tuned for strict gateways and client generators.
    /// </summary>
    public static IServiceCollection AddApiShieldOpenApi(
        this IServiceCollection services,
        Action<OpenApiOptions>? configure = null)
    {
        services.AddOpenApi(options =>
        {
            // 1. Emit OpenAPI 3.0 — the .NET default is 3.1, which API Shield and most gateways reject.
            options.OpenApiVersion = OpenApiSpecVersion.OpenApi3_0;

            // 2. Strip the duplicate/wildcard request-body media types ASP.NET adds by default.
            //    The application/*+json wildcard in particular trips up strict schema validators.
            options.AddDocumentTransformer((doc, ctx, ct) =>
            {
                var operations = doc.Paths?.Values
                    .SelectMany(p => p.Operations?.Values ?? Enumerable.Empty<OpenApiOperation>())
                    ?? Enumerable.Empty<OpenApiOperation>();

                foreach (var op in operations)
                {
                    var content = op.RequestBody?.Content;
                    content?.Remove("text/json");
                    content?.Remove("application/*+json");
                    content?.Remove("text/plain");
                }
                return Task.CompletedTask;
            });

            // 3. Give numeric and enum schemas an explicit "type". The .NET generator leaves
            //    decimal/enum schemas without a type (decimal also gets a meaningless regex
            //    pattern), which makes client generators emit untyped/object members and can
            //    cause strict validators to reject otherwise-valid payloads.
            options.AddSchemaTransformer((schema, ctx, ct) =>
            {
                var clrType = Nullable.GetUnderlyingType(ctx.JsonTypeInfo.Type) ?? ctx.JsonTypeInfo.Type;
                bool nullable = schema.Type is { } t && t.HasFlag(JsonSchemaType.Null);

                if (clrType == typeof(decimal) || clrType == typeof(double) || clrType == typeof(float))
                {
                    // "pattern" only applies to strings in JSON Schema; it is noise on a number.
                    schema.Type = nullable ? JsonSchemaType.Number | JsonSchemaType.Null : JsonSchemaType.Number;
                    schema.Pattern = null;
                }
                else if (clrType == typeof(int) || clrType == typeof(long) || clrType == typeof(short) ||
                         clrType == typeof(byte) || clrType == typeof(sbyte) || clrType == typeof(uint) ||
                         clrType == typeof(ulong) || clrType == typeof(ushort))
                {
                    schema.Type = nullable ? JsonSchemaType.Integer | JsonSchemaType.Null : JsonSchemaType.Integer;
                    schema.Pattern = null;
                }
                else if (clrType.IsEnum && schema.Enum is { Count: > 0 } enumValues
                         && enumValues[0] is JsonValue enumValue && enumValue.TryGetValue<string>(out _))
                {
                    // Only string-serialized enums (JsonStringEnumConverter) are emitted without a
                    // "type". Numeric enums already carry type: integer, so leave them untouched.
                    schema.Type = nullable ? JsonSchemaType.String | JsonSchemaType.Null : JsonSchemaType.String;
                }
                return Task.CompletedTask;
            });

            // Let the caller layer on app-specific metadata / transformers (title, servers, etc.).
            configure?.Invoke(options);
        });

        return services;
    }

    /// <summary>
    /// Forces lowercase URLs and query strings so served paths match the (lowercase) schema paths
    /// API Shield validates against.
    /// </summary>
    public static IServiceCollection AddLowercaseRouting(this IServiceCollection services)
    {
        services.AddRouting(options =>
        {
            options.LowercaseUrls = true;
            options.LowercaseQueryStrings = true;
        });
        return services;
    }
}
