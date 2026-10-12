<#
.SYNOPSIS
  Tira um print da tela inteira e grava em <PastaDeProvas>\maquete-NN.png.

.DESCRIPTION
  Usado pela skill /prompt (Passo 5). Cria a pasta se ela nao existir e numera
  os arquivos sozinho: rodar de novo gera maquete-02.png, nunca sobrescreve.
  Funciona no Windows PowerShell 5.1 e no PowerShell 7.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\capturar-tela.ps1 -Pasta ".prompt-provas\2026-01-31-filtro-vencido"
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][Alias('Pasta')][string]$PastaDeProvas,
  [string]$PrefixoDoArquivo = 'maquete'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $PastaDeProvas)) { New-Item -ItemType Directory -Path $PastaDeProvas -Force | Out-Null }
$PastaDeProvas = (Resolve-Path $PastaDeProvas).Path

Add-Type -AssemblyName System.Windows.Forms, System.Drawing
# Sem isto, com escala do Windows acima de 100% o VirtualScreen vem reduzido e o print sai cortado.
Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();' -Name EscalaDaTela -Namespace CapturarTela
[void][CapturarTela.EscalaDaTela]::SetProcessDPIAware()
$areaDeTodosOsMonitores = [System.Windows.Forms.SystemInformation]::VirtualScreen
$imagemDaTela = New-Object System.Drawing.Bitmap($areaDeTodosOsMonitores.Width, $areaDeTodosOsMonitores.Height)
try {
  $pincelDaImagem = [System.Drawing.Graphics]::FromImage($imagemDaTela)
  try {
    $pincelDaImagem.CopyFromScreen($areaDeTodosOsMonitores.X, $areaDeTodosOsMonitores.Y, 0, 0, $imagemDaTela.Size)
  } finally { $pincelDaImagem.Dispose() }

  $numeroDoPrint = 1
  while (Test-Path (Join-Path $PastaDeProvas ("{0}-{1:d2}.png" -f $PrefixoDoArquivo, $numeroDoPrint))) { $numeroDoPrint++ }
  $caminhoDoPrint = Join-Path $PastaDeProvas ("{0}-{1:d2}.png" -f $PrefixoDoArquivo, $numeroDoPrint)
  $imagemDaTela.Save($caminhoDoPrint, [System.Drawing.Imaging.ImageFormat]::Png)
} finally { $imagemDaTela.Dispose() }

Write-Output "PRINT: $caminhoDoPrint"
