
param(
    [string]$Url = "http://localhost:8081/",
    [int]$DuracaoSegundos = 180,
    [int]$Concorrencia = 10
)

Write-Host "`nIniciando teste de carga..." -ForegroundColor Cyan
Write-Host "URL: $Url"
Write-Host "Duração: $DuracaoSegundos segundos"
Write-Host "Requisições concorrentes: $Concorrencia`n"

$jobs = 1..$Concorrencia | ForEach-Object {
    Start-Job -ArgumentList $Url, $DuracaoSegundos -ScriptBlock {
        param($Url, $DuracaoSegundos)

        $sucessos = 0
        $falhas = 0
        $cronometro = [System.Diagnostics.Stopwatch]::StartNew()

        while ($cronometro.Elapsed.TotalSeconds -lt $DuracaoSegundos) {
            try {
                Invoke-RestMethod `
                    -Uri $Url `
                    -Method Get `
                    -TimeoutSec 5 `
                    -ErrorAction Stop | Out-Null

                $sucessos++
            }
            catch {
                $falhas++
            }
        }

        $cronometro.Stop()

        [PSCustomObject]@{
            Sucessos = $sucessos
            Falhas   = $falhas
            Segundos = [math]::Round(
                $cronometro.Elapsed.TotalSeconds, 1
            )
        }
    }
}

$jobs | Wait-Job | Out-Null
$resultados = $jobs | Receive-Job

$totalSucessos = ($resultados | Measure-Object Sucessos -Sum).Sum
$totalFalhas = ($resultados | Measure-Object Falhas -Sum).Sum
$totalRequisicoes = $totalSucessos + $totalFalhas

$tempoReal = ($resultados | Measure-Object Segundos -Maximum).Maximum

Write-Host "`n===== RESULTADO DO TESTE =====" -ForegroundColor Green
Write-Host "Requisições bem-sucedidas: $totalSucessos"
Write-Host "Requisições com falha:     $totalFalhas"
Write-Host "Total de requisições:      $totalRequisicoes"
Write-Host "Duração aproximada:        $tempoReal segundos"

if ($tempoReal -gt 0) {
    $rps = [math]::Round($totalRequisicoes / $tempoReal, 2)
    Write-Host "Requisições por segundo:   $rps"
}

$jobs | Remove-Job -Force