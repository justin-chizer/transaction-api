FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 8080

FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG TARGETARCH
WORKDIR /src
COPY ["TransactionApi.csproj", "."]
RUN dotnet restore -a $TARGETARCH
COPY . .
RUN dotnet publish -c Release -o /app/publish -a $TARGETARCH --no-self-contained

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "TransactionApi.dll"]