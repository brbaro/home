param(
  [Parameter(Position = 0)]
  $Target = $PWD,
  [int]$Port = 1234,
  [switch]$Open
)

function Test-AdministrativePrivileges {
  $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Elevate-ForLowPort {
  param([int]$RequestedPort)
  if ($RequestedPort -lt 1024 -and -not (Test-AdministrativePrivileges)) {
    Write-Host "[!] Port $RequestedPort requires Admin. Elevating..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File ""$PSCommandPath"" -Target ""$Target"" -Port $Port $(if($Open){'-Open'})" -Verb RunAs
    exit
  }
}

function Open-Browser {
  param([int]$RequestedPort)
  Start-Process "http://localhost:$RequestedPort"
}

function Start-HttpServer {
  param($BaseDir, $RequestedPort)

  $listener = New-Object Net.HttpListener
  $listener.Prefixes.Add("http://localhost:$RequestedPort/")

  try {
    $listener.Start()
    Write-Host "[+] Serving '$BaseDir' on http://localhost:$RequestedPort" -ForegroundColor Cyan
    if ($Open) { Open-Browser -RequestedPort $RequestedPort }
  } catch {
    Write-Host "[!] Error: Port $RequestedPort already in use or access denied." -ForegroundColor Red
    return
  }

  while ($listener.IsListening) {
    $context = $listener.GetContext()
    Process-HttpRequest -Context $context -BaseDir $BaseDir
  }
}

function Process-HttpRequest {
  param($Context, $BaseDir)

  $response = $Context.Response
  $relative = [uri]::UnescapeDataString($Context.Request.Url.LocalPath).TrimStart('/')
  $path = [IO.Path]::GetFullPath((Join-Path $BaseDir $relative))

  if ($path -notlike ($BaseDir + '*')) {
    $response.StatusCode = 403
    $response.Close()
    return
  }

  if (Test-Path $path -PathType Container) {
    $path = Join-Path $path "index.html"
  }

  if (Test-Path $path) {
    $buffer = [IO.File]::ReadAllBytes($path)
    $response.ContentLength64 = $buffer.Length
    $response.OutputStream.Write($buffer, 0, $buffer.Length)
  } else {
    $response.StatusCode = 404
  }
  $response.Close()
}

function Initialize-Service {
  Elevate-ForLowPort -RequestedPort $Port

  $resolvedPath = (Resolve-Path $Target).Path
  Start-HttpServer -BaseDir $resolvedPath -RequestedPort $Port
}

Initialize-Service
