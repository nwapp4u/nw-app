$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, 8000)
$listener.Start()
Write-Output "TCP static server started at http://localhost:8000/"

function Get-ContentType($path) {
  $ext = [System.IO.Path]::GetExtension($path).ToLower()
  switch ($ext) {
    '.html' { return 'text/html' }
    '.css'  { return 'text/css' }
    '.js'   { return 'application/javascript' }
    '.json' { return 'application/json' }
    '.png'  { return 'image/png' }
    '.jpg'  { return 'image/jpeg' }
    '.jpeg' { return 'image/jpeg' }
    '.svg'  { return 'image/svg+xml' }
    default { return 'application/octet-stream' }
  }
}

while ($true) {
  $client = $listener.AcceptTcpClient()
  Start-Job -ScriptBlock {
    param($client)
    $stream = $client.GetStream()
    $reader = New-Object System.IO.StreamReader($stream)
    $writer = New-Object System.IO.StreamWriter($stream)
    $requestLine = $reader.ReadLine()
    if ($requestLine -match '^GET\s+([^\s]+)') {
      $path = $Matches[1].TrimStart('/'); if ([string]::IsNullOrWhiteSpace($path)) { $path = 'index.html' }
      $fullPath = Join-Path -Path $pwd -ChildPath $path
      if (Test-Path $fullPath) {
        $bytes = [System.IO.File]::ReadAllBytes($fullPath)
        $contentType = Get-ContentType $fullPath
        $writer.WriteLine("HTTP/1.1 200 OK")
        $writer.WriteLine("Content-Type: $contentType")
        $writer.WriteLine("Content-Length: $($bytes.Length)")
        $writer.WriteLine("Connection: close")
        $writer.WriteLine("")
        $writer.Flush()
        $stream.Write($bytes, 0, $bytes.Length)
      } else {
        $writer.WriteLine("HTTP/1.1 404 Not Found")
        $writer.WriteLine("Connection: close")
        $writer.WriteLine("")
        $writer.Flush()
      }
    }
    $writer.Dispose(); $reader.Dispose(); $stream.Dispose(); $client.Close()
  } -ArgumentList $client | Out-Null
}