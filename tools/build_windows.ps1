# Bloco 50: exporta o executável Windows (build/windows/DeepIron.exe) e faz o TESTE DE FUMAÇA:
# abre com a pasta de usuário isolada, começa uma partida, salva, carrega e fecha (scripts/core/smoke.gd).
# Uso (da raiz do repositório):
#   powershell -ExecutionPolicy Bypass -File tools\build_windows.ps1 [-Godot <caminho>] [-Debug]
# Precisa dos templates de exportação do Godot 4.7.2 (Editor > Gerenciar templates de exportação,
# ou os dois arquivos windows_*_x86_64.exe em %APPDATA%\Godot\export_templates\4.7.2.stable\).
param(
    [string]$Godot = $env:GODOT_BIN,
    [switch]$Debug
)
$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
if (-not $Godot) { $Godot = "D:\DEV\Godot\Godot_v4.7.2-stable_win64.exe" }
$tpl = Join-Path $env:APPDATA "Godot\export_templates\4.7.2.stable\windows_release_x86_64.exe"
if (-not (Test-Path $tpl)) { Write-Error "Templates de exportação do 4.7.2 não instalados ($tpl)"; exit 3 }

$saida = Join-Path $raiz "build\windows"
New-Item -ItemType Directory -Force $saida | Out-Null
$modo = if ($Debug) { "--export-debug" } else { "--export-release" }
Write-Host "Exportando ($modo)..."
& $Godot --headless --path (Join-Path $raiz "project.godot") $modo "Windows Desktop" (Join-Path $saida "DeepIron.exe") 2>&1 | Select-String -Pattern "ERROR|error|savepack|Export" | ForEach-Object { $_.Line }
$exe = Join-Path $saida "DeepIron.exe"
if (-not (Test-Path $exe)) { Write-Error "o executável não foi gerado"; exit 1 }

# o pacote não pode levar os testes nem o protótipo
$pck = Join-Path $saida "DeepIron.pck"
if (Test-Path $pck) {
    $bytes = [System.IO.File]::ReadAllBytes($pck)
    $txt = [System.Text.Encoding]::ASCII.GetString($bytes)
    if ($txt.Contains("res://tests/") -or $txt.Contains("tests/blocos/")) { Write-Host "ATENÇÃO: o pacote contém tests/"; exit 1 }
    Write-Host ("pacote: {0:N1} MB, sem tests/" -f ((Get-Item $pck).Length / 1MB))
}

# teste de fumaça com a pasta de usuário isolada (o save de verdade não é tocado)
$real = Join-Path $env:APPDATA "Godot\app_userdata\project.godot\savegame.json"
$md5Antes = if (Test-Path $real) { (Get-FileHash $real -Algorithm MD5).Hash } else { "-" }
$fake = Join-Path $env:TEMP "deep_iron_testes\fake_appdata_build"
if (Test-Path $fake) { Remove-Item -Recurse -Force $fake }
New-Item -ItemType Directory -Force $fake | Out-Null
$antigo = $env:APPDATA
$env:APPDATA = $fake; $env:LOCALAPPDATA = $fake
$log = Join-Path $saida "smoke.log"
$p = Start-Process -FilePath $exe -ArgumentList "--", "--smoke" -RedirectStandardOutput $log -RedirectStandardError (Join-Path $saida "smoke_err.log") -PassThru -Wait
$env:APPDATA = $antigo
Get-Content $log | Select-String -Pattern "SMOKE|SAVE_VERSION" | ForEach-Object { $_.Line }
$md5Depois = if (Test-Path $real) { (Get-FileHash $real -Algorithm MD5).Hash } else { "-" }
Write-Host "save real: md5 antes $md5Antes / depois $md5Depois"
if ($md5Antes -ne $md5Depois) { Write-Host "ATENÇÃO: o save real mudou!"; exit 2 }
if ($p.ExitCode -ne 0) { Write-Host "teste de fumaça falhou (código $($p.ExitCode))"; exit 1 }
Write-Host "build OK: $exe"
exit 0
