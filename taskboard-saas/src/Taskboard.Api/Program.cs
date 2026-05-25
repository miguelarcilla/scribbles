using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Identity.Web;
using Taskboard.Api.Repositories;
using Taskboard.Api.Services;

var builder = WebApplication.CreateBuilder(args);

// ── Authentication (Entra ID multi-tenant) ──────────────────────────────────
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"));

// ── CORS ────────────────────────────────────────────────────────────────────
var allowedOrigins = builder.Configuration.GetSection("AllowedOrigins").Get<string[]>() ?? [];
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
        policy.WithOrigins(allowedOrigins)
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials());
});

// ── CosmosDB ─────────────────────────────────────────────────────────────────
builder.Services.AddSingleton(sp =>
{
    var connectionString = builder.Configuration["CosmosDb:ConnectionString"]
        ?? throw new InvalidOperationException("CosmosDb:ConnectionString is not configured.");
    return new Microsoft.Azure.Cosmos.CosmosClient(connectionString, new Microsoft.Azure.Cosmos.CosmosClientOptions
    {
        SerializerOptions = new Microsoft.Azure.Cosmos.CosmosSerializationOptions
        {
            PropertyNamingPolicy = Microsoft.Azure.Cosmos.CosmosPropertyNamingPolicy.CamelCase
        }
    });
});

// ── Repositories ─────────────────────────────────────────────────────────────
builder.Services.AddScoped<IBoardRepository, CosmosBoardRepository>();
builder.Services.AddScoped<ITaskRepository, CosmosTaskRepository>();
builder.Services.AddScoped<IUserRepository, CosmosUserRepository>();
builder.Services.AddScoped<ITenantRepository, CosmosTenantRepository>();

// ── Services ─────────────────────────────────────────────────────────────────
builder.Services.AddScoped<IBoardService, BoardService>();
builder.Services.AddScoped<ITaskService, TaskService>();
builder.Services.AddScoped<ITenantService, TenantService>();
builder.Services.AddScoped<IUserService, UserService>();

// ── Controllers + Swagger ────────────────────────────────────────────────────
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "Taskboard API", Version = "v1" });
    c.AddSecurityDefinition("Bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT"
    });
});

builder.Services.AddHealthChecks();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapHealthChecks("/health");

app.Run();
