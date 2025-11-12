using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Ocelot.DependencyInjection;
using Ocelot.Middleware;
using System.Security.Claims;

var builder = WebApplication.CreateBuilder(args);

// 🔹 Firebase Project ID
var firebaseProjectId = "mocha-app-bad3f";

// Authentication
builder.Services.AddAuthentication()
    .AddJwtBearer("Bearer", options =>
    {
        options.Authority = $"https://securetoken.google.com/{firebaseProjectId}";
        options.RequireHttpsMetadata = true;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = $"https://securetoken.google.com/{firebaseProjectId}",
            ValidateAudience = true,
            ValidAudience = firebaseProjectId,
            ValidateLifetime = true
        };
    });

// Authorization
builder.Services.AddAuthorization();

// Ocelot + CORS
builder.Services.AddOcelot();
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});

var app = builder.Build();

app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();

// 🔹 Middleware kiểm tra role nhiều giá trị
app.Use(async (context, next) =>
{
    var path = context.Request.Path.Value?.ToLower() ?? "";
    var method = context.Request.Method;
    var role = context.User.Claims.FirstOrDefault(c => c.Type == "role")?.Value;

    if (path.StartsWith("/api/users/me"))
    {
        // Cho phép User hoặc Admin
        if (role != "User" && role != "Admin")
        {
            context.Response.StatusCode = 403;
            await context.Response.WriteAsync("Access denied: User or Admin only");
            return;
        }
    }

    if (path.StartsWith("/api/users/all"))
    {
        // Chỉ Admin
        if (role != "Admin")
        {
            context.Response.StatusCode = 403;
            await context.Response.WriteAsync("Access denied: Admin only");
            return;
        }
    }

    if (path.StartsWith("/api/admin"))
    {
        // Chỉ Admin
        if (role != "Admin")
        {
            context.Response.StatusCode = 403;
            await context.Response.WriteAsync("Access denied: Admin only");
            return;
        }
    }

    await next();
});

// 🔹 Chạy Ocelot
await app.UseOcelot();
app.Run();
