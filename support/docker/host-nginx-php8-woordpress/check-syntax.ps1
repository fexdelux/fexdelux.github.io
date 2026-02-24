$errors = @()
$null = [System.Management.Automation.Language.Parser]::ParseFile(
    "$PSScriptRoot\publish.ps1",
    [ref]$null,
    [ref]$errors
)

if ($errors) {
    Write-Host "Erros encontrados:" -ForegroundColor Red
    $errors | ForEach-Object {
        Write-Host "Linha $($_.Extent.StartLineNumber): $($_.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "Nenhum erro de sintaxe encontrado!" -ForegroundColor Green
}
