# Bloco 50: roda a suíte GUT inteira (headless) com a pasta de usuário ISOLADA e confere que o
# save de verdade não mudou. Sai com 0 se tudo passou; 1 se algum teste falhou; 2 se o save real
# mudou; 3 se não achou o Godot. Uso (da raiz do repositório):
#   powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 [-Godot <caminho do Godot>] [-Filtro b35]
param(
    [string]$Godot = $env:GODOT_BIN,
    [string]$Filtro = ""
)
$raiz = Split-Path -Parent $PSScriptRoot
if (-not $Godot) { $Godot = "D:\DEV\Godot\Godot_v4.7.2-stable_win64.exe" }
if (-not (Test-Path $Godot)) { Write-Host "Godot não encontrado: $Godot (passe -Godot ou defina GODOT_BIN)"; exit 3 }

$real = Join-Path $env:APPDATA "Godot\app_userdata\project.godot\savegame.json"
$md5Antes = if (Test-Path $real) { (Get-FileHash $real -Algorithm MD5).Hash } else { "-" }

$base = Join-Path $env:TEMP "deep_iron_testes"
$fake = Join-Path $base "fake_appdata"
New-Item -ItemType Directory -Force $fake | Out-Null
$appAntigo = $env:APPDATA; $xdgAntigo = $env:XDG_DATA_HOME; $localAntigo = $env:LOCALAPPDATA
$env:APPDATA = $fake; $env:XDG_DATA_HOME = $fake; $env:LOCALAPPDATA = $fake

$argumentos = @("--headless", "--path", "`"$(Join-Path $raiz 'project.godot')`"", "-s", "addons/gut/gut_cmdln.gd")
if ($Filtro) { $argumentos += "-gunit_test_name=$Filtro" }
$out = Join-Path $base "gut_ultimo.log"
$err = Join-Path $base "gut_ultimo_err.log"
$p = Start-Process -FilePath $Godot -ArgumentList $argumentos -RedirectStandardOutput $out -RedirectStandardError $err -NoNewWindow -PassThru -Wait
$env:APPDATA = $appAntigo; $env:XDG_DATA_HOME = $xdgAntigo; $env:LOCALAPPDATA = $localAntigo

$texto = Get-Content $out -Raw
$texto -split "`n" | Where-Object { $_ -match "Passing Tests|Failing Tests|\[Failed\]|^Tests " } | ForEach-Object { $_.Trim() }
$falhas = 0
if ($texto -match "Failing Tests\s+(\d+)") { $falhas = [int]$Matches[1] }
$passou = $texto -match "Passing Tests"

$md5Depois = if (Test-Path $real) { (Get-FileHash $real -Algorithm MD5).Hash } else { "-" }
Write-Host "save real: md5 antes $md5Antes / depois $md5Depois   (log completo: $out)"
if ($md5Antes -ne $md5Depois) { Write-Host "ATENÇÃO: o save real mudou durante os testes!"; exit 2 }
if (-not $passou -or $falhas -gt 0) { exit 1 }
exit 0
