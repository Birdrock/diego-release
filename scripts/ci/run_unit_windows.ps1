﻿$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

cd diego-release/

Add-Type -AssemblyName System.IO.Compression.FileSystem
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$CONSUL_DIR = "C:/consul"
# Remove-Item $CONSUL_DIR -Force
if(!(Test-Path -Path $CONSUL_DIR )) {
    New-Item -ItemType directory -Path $CONSUL_DIR
    (New-Object System.Net.WebClient).DownloadFile('https://releases.hashicorp.com/consul/0.7.0/consul_0.7.0_windows_amd64.zip', "$CONSUL_DIR/consul.zip")
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$CONSUL_DIR/consul.zip", "$CONSUL_DIR")
}

$env:GOPATH=($pwd).path
$env:GOBIN=$env:GOPATH + "/bin"
$env:PATH = $env:GOBIN +  ";" + $CONSUL_DIR + ";" + $env:PATH
# Write-Host "Gopath is " + $env:GOPATH
# Write-Host "PATH is " + $env:PATH

Write-Host "Installing nats-server"

$NATS_DIR = "C:/nats-server"
# Remove-Item $NATS_DIR -Force
if(!(Test-Path -Path $NATS_DIR )) {
  New-Item -ItemType directory -Path $NATS_DIR
  (New-Object System.Net.WebClient).DownloadFile('https://github.com/nats-io/nats-server/releases/download/v2.1.2/nats-server-v2.1.2-windows-amd64.zip', "nats-server.zip")
    [System.IO.Compression.ZipFile]::ExtractToDirectory("nats-server.zip", "$NATS_DIR")
    Move-Item -Path "$NATS_DIR/*/nats-server.exe" "$env:GOPATH/bin/nats-server.exe"
}
$env:NATS_DOCKERIZED = "1"

Write-Host "Installing Ginkgo"
go get github.com/onsi/ginkgo/ginkgo
if ($LastExitCode -ne 0) {
    throw "Ginkgo installation process returned error code: $LastExitCode"
} else {
  Write-Host "Ginkgo successfully installed"
}

Write-Host "Downloading winpty DLL"
$WINPTY_DIR = "C:\winpty"
if(!(Test-Path -Path $WINPTY_DIR )) {
    New-Item -ItemType directory -Path $WINPTY_DIR
    (New-Object System.Net.WebClient).DownloadFile('https://github.com/rprichard/winpty/releases/download/0.4.3/winpty-0.4.3-msvc2015.zip', "$WINPTY_DIR\winpty.zip")
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$WINPTY_DIR\winpty.zip", "$WINPTY_DIR")
}
$env:WINPTY_DLL_DIR="$WINPTY_DIR\x64\bin"

Write-Host "Running store-independent test suites against a MySQL database..."
$env:SQL_FLAVOR="mysql"

cd src/code.cloudfoundry.org/

ginkgo -r -keepGoing -trace -randomizeAllSpecs -progress -race `
  route-emitter `
  cfhttp `
  cacheddownloader `
  certsplitter `
  diego-logging-client `
  diego-ssh `
  executor `
  bytefmt `
  durationjson `
  eventhub `
  healthcheck `
  localip `
  operationq `
  rep `
  routing-info `
  workpool

if ($LastExitCode -ne 0) {
  Write-Host "Diego unit tests failed"
  exit 1
} else {
  Write-Host "Diego unit tests passed"
  exit 0
}
