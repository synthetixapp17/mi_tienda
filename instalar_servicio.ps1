Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  INICIANDO CONFIGURACIÓN DE MI TIENDA   " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$rutaActual = Get-Location
Write-Host "Carpeta de trabajo actual: $rutaActual" -ForegroundColor Yellow

Write-Host "Actualizando dependencias de Flutter..." -ForegroundColor Green
flutter pub get

if ($LASTEXITCODE -eq 0) {
    Write-Host "¡Dependencias actualizadas con éxito!" -ForegroundColor Green
} else {
    Write-Host "Hubo un error al ejecutar flutter pub get." -ForegroundColor Red
}

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "¡Proceso finalizado con éxito!" -ForegroundColor Cyan
Pause
