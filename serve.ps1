Add-Type -AssemblyName System.Net
$listener = New-Object System.Net.HttpListener
$port = $env:PORT
if ([string]::IsNullOrWhiteSpace($port)) { $port = '8000' }
$prefix = "http://localhost:$port/"
$listener.Prefixes.Clear()
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Output "Static server started at $prefix. Root: $pwd"
while ($true) {
  try {
    $context = $listener.GetContext()
    $request = $context.Request
    $path = $request.Url.AbsolutePath.TrimStart('/')
    if ([string]::IsNullOrWhiteSpace($path)) { $path = 'index.html' }
    $fullPath = Join-Path -Path $pwd -ChildPath $path
    $response = $context.Response
    if (Test-Path $fullPath) {
      $bytes = [System.IO.File]::ReadAllBytes($fullPath)
      $ext = [System.IO.Path]::GetExtension($fullPath).ToLower()
      switch ($ext) {
        '.html' { $response.ContentType = 'text/html' }
        '.css'  { $response.ContentType = 'text/css' }
        '.js'   { $response.ContentType = 'application/javascript' }
        '.json' { $response.ContentType = 'application/json' }
        '.png'  { $response.ContentType = 'image/png' }
        '.jpg'  { $response.ContentType = 'image/jpeg' }
        '.jpeg' { $response.ContentType = 'image/jpeg' }
        '.svg'  { $response.ContentType = 'image/svg+xml' }
        default { $response.ContentType = 'application/octet-stream' }
      }
      $response.ContentLength64 = $bytes.Length
      $response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $response.StatusCode = 404
    }
  } catch {
    # swallow errors to keep server running
  } finally {
    if ($null -ne $response) { $response.OutputStream.Close() }
  }
}