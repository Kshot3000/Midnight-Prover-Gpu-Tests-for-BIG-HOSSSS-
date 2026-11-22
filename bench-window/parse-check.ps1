$errs = 0
foreach ($f in 'restart-core.ps1','finisher.ps1','deadman.ps1','arm-dry.ps1','rebuild-record.ps1','register-deadman.ps1') {
    $tokens = $null; $parseerr = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile('C:\bench-window\' + $f, [ref]$tokens, [ref]$parseerr)
    if ($parseerr.Count -gt 0) {
        $errs++
        Write-Output ('PARSE-FAIL ' + $f + ': ' + (($parseerr | Select-Object -First 3) -join ' | '))
    } else {
        Write-Output ('PARSE-OK ' + $f)
    }
}
exit $errs
