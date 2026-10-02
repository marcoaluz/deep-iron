# Bloco 53: benchmark reproduzível (tests/bench_cena.gd) com a pasta de usuário isolada.
#   powershell -ExecutionPolicy Bypass -File tools\bench_cena.ps1 [-Godot <caminho>] [-Saida <arquivo>]
# Abre uma janela 1920x1080 (sem vsync) por ~5 min; não mexa no PC enquanto mede.
param(
    [string]$Godot = "D:\DEV\Godot\Godot_v4.7.2-stable_win64.exe",
    [string]$Saida = "",
    [switch]$Rapido
)
$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
$proj = Join-Path $raiz "project.godot"
if (-not (Test-Path $Godot)) { Write-Host "Godot não encontrado: $Godot"; exit 3 }
$fake = Join-Path $env:TEMP "deep_iron_testes\fake_appdata_bench"
New-Item -ItemType Directory -Force $fake | Out-Null
if ($Saida -eq "") { $Saida = Join-Path $raiz ("docs\bench\bench_" + (Get-Date -Format "yyyy-MM-dd_HH-mm") + ".txt") }
New-Item -ItemType Directory -Force (Split-Path -Parent $Saida) | Out-Null
$env:APPDATA = $fake; $env:XDG_DATA_HOME = $fake; $env:LOCALAPPDATA = $fake
$log = Join-Path $env:TEMP "deep_iron_testes\bench_ultimo.log"
$argumentos = @("--path", "`"$proj`"", "-s", "res://tests/bench_cena.gd", "--", "`"$Saida`"")
if ($Rapido) { $argumentos += "rapido" }
$p = Start-Process -FilePath $Godot -ArgumentList $argumentos `
    -NoNewWindow -Wait -PassThru -RedirectStandardOutput $log -RedirectStandardError "$log.err"
Get-Content $Saida -Encoding UTF8
Write-Host "(resultado: $Saida)"
exit $p.ExitCode
