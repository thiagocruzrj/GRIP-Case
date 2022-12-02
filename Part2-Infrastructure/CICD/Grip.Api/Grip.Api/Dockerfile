#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/aspnet:6.0.0-bullseye-slim-amd64 AS base
WORKDIR /app


FROM mcr.microsoft.com/dotnet/sdk:6.0.100-bullseye-slim-amd64 AS build
WORKDIR /src
RUN curl -L https://raw.githubusercontent.com/Microsoft/artifacts-credprovider/master/helpers/installcredprovider.sh  | sh

RUN apt-get update && apt-get install dos2unix

COPY ["nuget.config", "."]
COPY ["Grip.Api/Grip.Api/Grip.Api.csproj", "Grip.Api/"]
COPY ["Grip.Api/Grip.Api.Tests.UnitTests/Grip.Api.Tests.UnitTests.csproj", "Grip.Api.Tests.UnitTests/"]

RUN dotnet restore "Grip.Api/Grip.Api.csproj"
RUN dotnet restore "Grip.Api.Tests.UnitTests/Grip.Api.Tests.UnitTests.csproj"

COPY Grip.Api .

RUN dotnet build "Grip.Api/Grip.Api.csproj" -c Release -o /app/build

ARG RUN_TESTS 
RUN ./runTests.sh "Grip.Api.Tests.UnitTests/Grip.Api.Tests.UnitTests.csproj" ${RUN_TESTS}

FROM build AS publish

FROM base AS final

WORKDIR /app
COPY --from=publish /app/publish .
RUN chown -R Grip:Grip /app
USER Grip
ENTRYPOINT ["dotnet", "Grip.Api.dll"]
