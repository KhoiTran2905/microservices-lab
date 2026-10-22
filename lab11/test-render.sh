#!/bin/bash
# test-render.sh - chạy: ./test-render.sh [GATEWAY_URL]
# Mặc định test bản deploy trên Render; chạy local thì: ./test-render.sh http://localhost:3000

GATEWAY_URL="${1:-https://mslab11-1ic2-api-gateway.onrender.com}"

# jq là tuỳ chọn: có thì in đẹp, không có thì in thô
if command -v jq >/dev/null 2>&1; then PRETTY="jq ."; else PRETTY="cat"; fi

echo "Testing API Gateway at $GATEWAY_URL (lần đầu có thể mất ~1 phút để service free thức dậy)..."
curl -s --max-time 120 "$GATEWAY_URL/" | $PRETTY

echo -e "\n\nTesting health checks..."
curl -s --max-time 120 "$GATEWAY_URL/health" | $PRETTY

echo -e "\n\nTesting Users service..."
curl -s "$GATEWAY_URL/users" | $PRETTY

echo -e "\n\nCreating new user..."
curl -s -X POST "$GATEWAY_URL/users" \
  -H "Content-Type: application/json" \
  -d '{"name": "Test User", "email": "test@render.com"}' | $PRETTY

echo -e "\n\nTesting Products service..."
curl -s "$GATEWAY_URL/products" | $PRETTY

echo -e "\n\nCreating new product..."
curl -s -X POST "$GATEWAY_URL/products" \
  -H "Content-Type: application/json" \
  -d '{"name": "Render Product", "price": 50, "stock": 100}' | $PRETTY

echo -e "\n\nCreating order..."
curl -s -X POST "$GATEWAY_URL/orders" \
  -H "Content-Type: application/json" \
  -d '{"userId": 1, "productId": 1, "quantity": 2}' | $PRETTY

echo -e "\n\nGetting all orders..."
curl -s "$GATEWAY_URL/orders" | $PRETTY

echo -e "\n\nUser service health (qua gateway, có kiểm tra DB)..."
curl -s "$GATEWAY_URL/users/health" | $PRETTY
echo
