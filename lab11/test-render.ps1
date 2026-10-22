# test-render.ps1 - chạy: .\test-render.ps1 [-Gateway <url>]
# Chạy local: .\test-render.ps1 -Gateway http://localhost:3000
param([string]$Gateway = "https://mslab11-1ic2-api-gateway.onrender.com")

function Show($title, $obj) {
    Write-Host "`n=== $title" -ForegroundColor Cyan
    $obj | ConvertTo-Json -Depth 6
}

Write-Host "Testing API Gateway at $Gateway (lan dau co the mat ~1 phut de service free thuc day)..."
Show "Gateway info" (Invoke-RestMethod "$Gateway/" -TimeoutSec 120)
Show "Health checks" (Invoke-RestMethod "$Gateway/health" -TimeoutSec 120)
Show "Users" (Invoke-RestMethod "$Gateway/users")

try {
    Show "Create user" (Invoke-RestMethod -Method Post "$Gateway/users" -ContentType "application/json" `
        -Body '{"name": "Test User", "email": "test@render.com"}')
} catch { Write-Host "Create user: $($_.ErrorDetails.Message)" -ForegroundColor Yellow }

Show "Products" (Invoke-RestMethod "$Gateway/products")
Show "Create product" (Invoke-RestMethod -Method Post "$Gateway/products" -ContentType "application/json" `
    -Body '{"name": "Render Product", "price": 50, "stock": 100}')

try {
    Show "Create order" (Invoke-RestMethod -Method Post "$Gateway/orders" -ContentType "application/json" `
        -Body '{"userId": 1, "productId": 1, "quantity": 2}')
} catch { Write-Host "Create order: $($_.ErrorDetails.Message)" -ForegroundColor Yellow }

Show "Orders" (Invoke-RestMethod "$Gateway/orders")
Show "User service health (co kiem tra DB)" (Invoke-RestMethod "$Gateway/users/health")
