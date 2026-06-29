using Microsoft.EntityFrameworkCore;
using TransactionApi.Data;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi(options =>
{
    options.OpenApiVersion = Microsoft.OpenApi.OpenApiSpecVersion.OpenApi3_0;

    // Strip duplicate/wildcard request-body media types that ASP.NET adds by default.
    // Cloudflare API Shield's schema validator doesn't handle the application/*+json
    // wildcard well; text/json and text/plain are just redundant noise.
    options.AddDocumentTransformer((doc, ctx, ct) =>
    {
        var operations = doc.Paths.Values
            .SelectMany(p => p.Operations?.Values ?? Enumerable.Empty<Microsoft.OpenApi.OpenApiOperation>());

        foreach (var op in operations)
        {
            var content = op.RequestBody?.Content;
            content?.Remove("text/json");
            content?.Remove("application/*+json");
            content?.Remove("text/plain");
        }
        return Task.CompletedTask;
    });
});
builder.Services.AddHealthChecks();
builder.Services.AddRouting(options =>
{
    options.LowercaseUrls = true;
    options.LowercaseQueryStrings = true;
});

builder.Services.AddDbContext<BankingDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<BankingDbContext>();
    db.Database.Migrate();
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

//app.UseHttpsRedirection(); //Removed because this will run in AKS

app.UseAuthorization();

app.MapHealthChecks("/health");
app.MapControllers();

app.Run();
