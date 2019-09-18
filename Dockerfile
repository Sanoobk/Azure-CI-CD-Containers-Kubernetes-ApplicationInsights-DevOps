FROM microsoft/dotnet:2.1-aspnetcore-runtime AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM microsoft/dotnet:2.1-sdk AS build
WORKDIR /src
COPY ["CICDContainers-Demo02/CICDContainers-Demo02.csproj", "CICDContainers-Demo02/"]
RUN dotnet restore "CICDContainers-Demo02/CICDContainers-Demo02.csproj"
COPY . .
WORKDIR "/src/CICDContainers-Demo02"
RUN dotnet build "CICDContainers-Demo02.csproj" -c Release -o /app

FROM build AS publish
RUN dotnet publish "CICDContainers-Demo02.csproj" -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=publish /app .
ENTRYPOINT ["dotnet", "CICDContainers-Demo02.dll"]