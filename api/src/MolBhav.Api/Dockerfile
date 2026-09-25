# Build from the repository root:  docker build -f src/MolBhav.Api/Dockerfile -t molbhav-api .
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Restore layer (cached until a project/props file changes).
COPY global.json Directory.Build.props Directory.Packages.props .editorconfig ./
COPY src/MolBhav.Domain/MolBhav.Domain.csproj src/MolBhav.Domain/
COPY src/MolBhav.Application/MolBhav.Application.csproj src/MolBhav.Application/
COPY src/MolBhav.Infrastructure/MolBhav.Infrastructure.csproj src/MolBhav.Infrastructure/
COPY src/MolBhav.Api/MolBhav.Api.csproj src/MolBhav.Api/
RUN dotnet restore src/MolBhav.Api/MolBhav.Api.csproj

COPY src/ src/
RUN dotnet publish src/MolBhav.Api/MolBhav.Api.csproj -c Release -o /app/publish --no-restore /p:UseAppHost=false

# Debian-based runtime image ships ICU, required for hi/mr/gu/ta/te/kn cultures.
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
ENV ASPNETCORE_HTTP_PORTS=8080 \
    DOTNET_RUNNING_IN_CONTAINER=true
EXPOSE 8080
COPY --from=build /app/publish .
USER $APP_UID
ENTRYPOINT ["dotnet", "MolBhav.Api.dll"]
