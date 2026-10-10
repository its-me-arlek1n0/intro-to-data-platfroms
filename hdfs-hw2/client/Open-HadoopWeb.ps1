param(
    [string]$EdgeHost = '111.88.130.12',
    [string]$KeyPath = "$HOME/.ssh/id_ed25519",
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'

$rows = Get-Content "$PSScriptRoot/../config/web-interfaces.tsv" | Where-Object { $_ -and -not $_.StartsWith('#') }

$sshArgs = @('-NT', '-i', $KeyPath, '-o', 'StrictHostKeyChecking=yes', '-o', 'ExitOnForwardFailure=yes')

foreach ($row in $rows) {
    $id, $service, $node, $backend, $port, $page = $row -split "`t"
    $url = "http://127.0.0.1:$port$page"
    if ($CheckOnly) {
        $status = & curl.exe --noproxy '*' -fsSL --connect-timeout 3 -o NUL -w '%{http_code}' $url
        if ($LASTEXITCODE -ne 0 -or $status -ne '200') {
            Write-Host "Не открывается: $url"
            exit 1
        }
        Write-Host "$service ($node): OK, HTTP $status"
    } else {
        $sshArgs += '-L', "127.0.0.1:${port}:127.0.0.1:${port}"
        Write-Host "$service ($node) -> $url"
    }
}

if (-not $CheckOnly) {
    Write-Host "Туннель открыт, окно не закрывать. Остановить - Ctrl+C."
    & ssh @sshArgs "team@$EdgeHost"
}
