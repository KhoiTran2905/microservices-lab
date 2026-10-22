Xây dựng hệ thống gồm:

3 microservices: User, Product, Order
API Gateway
PostgreSQL cho mỗi service
Docker containerization
Inter-service communication qua REST API

Bước 1: Tạo cấu trúc thư mục

mkdir microservices-lab
cd microservices-lab

# Tạo thư mục cho các services
mkdir -p user-service/app
mkdir -p product-service/app
mkdir -p order-service/app
mkdir -p api-gateway

Bước 2: Tạo User Service
File: user-service/app/main.py

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional
import psycopg2
from psycopg2.extras import RealDictCursor
import os
import time

app = FastAPI(title="User Service")

# Database connection
def get_db_connection():
    max_retries = 5
    for i in range(max_retries):
        try:
            conn = psycopg2.connect(
                host=os.getenv("DB_HOST", "user-db"),
                database=os.getenv("DB_NAME", "userdb"),
                user=os.getenv("DB_USER", "postgres"),
                password=os.getenv("DB_PASSWORD", "postgres"),
                cursor_factory=RealDictCursor
            )
            return conn
        except psycopg2.OperationalError:
            if i < max_retries - 1:
                time.sleep(2)
            else:
                raise

# Models
class User(BaseModel):
    name: str
    email: str
    phone: Optional[str] = None

class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    phone: Optional[str]

# Initialize database
@app.on_event("startup")
def startup():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            email VARCHAR(100) UNIQUE NOT NULL,
            phone VARCHAR(20)
        )
    """)
    conn.commit()
    cur.close()
    conn.close()

@app.get("/")
def read_root():
    return {"service": "User Service", "status": "running"}

@app.post("/users", response_model=UserResponse)
def create_user(user: User):
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            "INSERT INTO users (name, email, phone) VALUES (%s, %s, %s) RETURNING *",
            (user.name, user.email, user.phone)
        )
        new_user = cur.fetchone()
        conn.commit()
        return new_user
    except psycopg2.IntegrityError:
        raise HTTPException(status_code=400, detail="Email already exists")
    finally:
        cur.close()
        conn.close()

@app.get("/users/{user_id}", response_model=UserResponse)
def get_user(user_id: int):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM users WHERE id = %s", (user_id,))
    user = cur.fetchone()
    cur.close()
    conn.close()
   
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@app.get("/users")
def get_all_users():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM users")
    users = cur.fetchall()
    cur.close()
    conn.close()
    return users


File: user-service/requirements.txt

fastapi==0.104.1
uvicorn==0.24.0
psycopg2-binary==2.9.9
pydantic==2.5.0

File: user-service/Dockerfile

FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

Bước 3: Tạo Product Service
File: product-service/app/main.py

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional
import psycopg2
from psycopg2.extras import RealDictCursor
import os
import time

app = FastAPI(title="Product Service")

def get_db_connection():
    max_retries = 5
    for i in range(max_retries):
        try:
            conn = psycopg2.connect(
                host=os.getenv("DB_HOST", "product-db"),
                database=os.getenv("DB_NAME", "productdb"),
                user=os.getenv("DB_USER", "postgres"),
                password=os.getenv("DB_PASSWORD", "postgres"),
                cursor_factory=RealDictCursor
            )
            return conn
        except psycopg2.OperationalError:
            if i < max_retries - 1:
                time.sleep(2)
            else:
                raise

class Product(BaseModel):
    name: str
    description: Optional[str] = None
    price: float
    stock: int = 0

class ProductResponse(BaseModel):
    id: int
    name: str
    description: Optional[str]
    price: float
    stock: int

@app.on_event("startup")
def startup():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS products (
            id SERIAL PRIMARY KEY,
            name VARCHAR(200) NOT NULL,
            description TEXT,
            price DECIMAL(10, 2) NOT NULL,
            stock INTEGER DEFAULT 0
        )
    """)
    conn.commit()
    cur.close()
    conn.close()

@app.get("/")
def read_root():
    return {"service": "Product Service", "status": "running"}

@app.post("/products", response_model=ProductResponse)
def create_product(product: Product):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO products (name, description, price, stock) VALUES (%s, %s, %s, %s) RETURNING *",
        (product.name, product.description, product.price, product.stock)
    )
    new_product = cur.fetchone()
    conn.commit()
    cur.close()
    conn.close()
    return new_product

@app.get("/products/{product_id}", response_model=ProductResponse)
def get_product(product_id: int):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM products WHERE id = %s", (product_id,))
    product = cur.fetchone()
    cur.close()
    conn.close()
   
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return product

@app.get("/products")
def get_all_products():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM products")
    products = cur.fetchall()
    cur.close()
    conn.close()
    return products

@app.put("/products/{product_id}/stock")
def update_stock(product_id: int, quantity: int):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        "UPDATE products SET stock = stock + %s WHERE id = %s RETURNING *",
        (quantity, product_id)
    )
    product = cur.fetchone()
    conn.commit()
    cur.close()
    conn.close()
   
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return product

File: product-service/requirements.txt

fastapi==0.104.1
uvicorn==0.24.0
psycopg2-binary==2.9.9
pydantic==2.5.0

File: product-service/Dockerfile

FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

Bước 4: Tạo Order Service (với inter-service communication)
File: order-service/app/main.py

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List
import psycopg2
from psycopg2.extras import RealDictCursor
import os
import time
import httpx

app = FastAPI(title="Order Service")

USER_SERVICE_URL = os.getenv("USER_SERVICE_URL", "http://user-service:8000&quot;)
PRODUCT_SERVICE_URL = os.getenv("PRODUCT_SERVICE_URL", "http://product-service:8000&quot;)

def get_db_connection():
    max_retries = 5
    for i in range(max_retries):
        try:
            conn = psycopg2.connect(
                host=os.getenv("DB_HOST", "order-db"),
                database=os.getenv("DB_NAME", "orderdb"),
                user=os.getenv("DB_USER", "postgres"),
                password=os.getenv("DB_PASSWORD", "postgres"),
                cursor_factory=RealDictCursor
            )
            return conn
        except psycopg2.OperationalError:
            if i < max_retries - 1:
                time.sleep(2)
            else:
                raise

class OrderItem(BaseModel):
    product_id: int
    quantity: int

class Order(BaseModel):
    user_id: int
    items: List[OrderItem]

class OrderResponse(BaseModel):
    id: int
    user_id: int
    total_amount: float
    status: str

@app.on_event("startup")
def startup():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS orders (
            id SERIAL PRIMARY KEY,
            user_id INTEGER NOT NULL,
            total_amount DECIMAL(10, 2) NOT NULL,
            status VARCHAR(50) DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    cur.execute("""
        CREATE TABLE IF NOT EXISTS order_items (
            id SERIAL PRIMARY KEY,
            order_id INTEGER REFERENCES orders(id),
            product_id INTEGER NOT NULL,
            quantity INTEGER NOT NULL,
            price DECIMAL(10, 2) NOT NULL
        )
    """)
    conn.commit()
    cur.close()
    conn.close()

@app.get("/")
def read_root():
    return {"service": "Order Service", "status": "running"}

@app.post("/orders", response_model=OrderResponse)
async def create_order(order: Order):
    # Verify user exists
    async with httpx.AsyncClient() as client:
        try:
            user_response = await client.get(f"{USER_SERVICE_URL}/users/{order.user_id}")
            if user_response.status_code != 200:
                raise HTTPException(status_code=404, detail="User not found")
        except httpx.RequestError:
            raise HTTPException(status_code=503, detail="User service unavailable")
   
    # Calculate total and verify products
    total_amount = 0
    order_items_data = []
   
    async with httpx.AsyncClient() as client:
        for item in order.items:
            try:
                product_response = await client.get(
                    f"{PRODUCT_SERVICE_URL}/products/{item.product_id}"
                )
                if product_response.status_code != 200:
                    raise HTTPException(
                        status_code=404,
                        detail=f"Product {item.product_id} not found"
                    )
               
                product = product_response.json()
               
                if product['stock'] < item.quantity:
                    raise HTTPException(
                        status_code=400,
                        detail=f"Insufficient stock for product {item.product_id}"
                    )
               
                item_total = float(product['price']) * item.quantity
                total_amount += item_total
                order_items_data.append({
                    'product_id': item.product_id,
                    'quantity': item.quantity,
                    'price': product['price']
                })
               
                # Update stock
                await client.put(
                    f"{PRODUCT_SERVICE_URL}/products/{item.product_id}/stock",
                    params={"quantity": -item.quantity}
                )
               
            except httpx.RequestError:
                raise HTTPException(status_code=503, detail="Product service unavailable")
   
    # Create order in database
    conn = get_db_connection()
    cur = conn.cursor()
   
    try:
        cur.execute(
            "INSERT INTO orders (user_id, total_amount, status) VALUES (%s, %s, %s) RETURNING *",
            (order.user_id, total_amount, 'confirmed')
        )
        new_order = cur.fetchone()
       
        for item_data in order_items_data:
            cur.execute(
                "INSERT INTO order_items (order_id, product_id, quantity, price) VALUES (%s, %s, %s, %s)",
                (new_order['id'], item_data['product_id'], item_data['quantity'], item_data['price'])
            )
       
        conn.commit()
        return new_order
    finally:
        cur.close()
        conn.close()

@app.get("/orders/{order_id}")
def get_order(order_id: int):
    conn = get_db_connection()
    cur = conn.cursor()
   
    cur.execute("SELECT * FROM orders WHERE id = %s", (order_id,))
    order = cur.fetchone()
   
    if not order:
        cur.close()
        conn.close()
        raise HTTPException(status_code=404, detail="Order not found")
   
    cur.execute("SELECT * FROM order_items WHERE order_id = %s", (order_id,))
    items = cur.fetchall()
   
    cur.close()
    conn.close()
   
    return {
        "order": order,
        "items": items
    }

@app.get("/orders")
def get_all_orders():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM orders ORDER BY created_at DESC")
    orders = cur.fetchall()
    cur.close()
    conn.close()
    return orders

File: order-service/requirements.txt

fastapi==0.104.1
uvicorn==0.24.0
psycopg2-binary==2.9.9
pydantic==2.5.0
httpx==0.25.2

File: order-service/Dockerfile

FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

Bước 5: Cấu hình Nginx làm API Gateway
File: api-gateway/nginx.conf


events {
    worker_connections 1024;
}

http {
    upstream user_service {
        server user-service:8000;
    }

    upstream product_service {
        server product-service:8000;
    }

    upstream order_service {
        server order-service:8000;
    }

    server {
        listen 80;

        # User Service routes
        location /api/users {
            rewrite ^/api/users(.*)$ /users$1 break;
            proxy_pass http://user_service;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        # Product Service routes
        location /api/products {
            rewrite ^/api/products(.*)$ /products$1 break;
            proxy_pass http://product_service;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        # Order Service routes
        location /api/orders {
            rewrite ^/api/orders(.*)$ /orders$1 break;
            proxy_pass http://order_service;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        # Health check
        location /health {
            return 200 "API Gateway is running\n";
            add_header Content-Type text/plain;
        }
    }
}

File: api-gateway/Dockerfile


FROM nginx:alpine

COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

Bước 6: Tạo Docker Compose file
File: docker-compose.yml

version: '3.8'

services:
  # User Service
  user-db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: userdb
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - user-db-data:/var/lib/postgresql/data
    networks:
      - microservices-network

  user-service:
    build: ./user-service
    environment:
      DB_HOST: user-db
      DB_NAME: userdb
      DB_USER: postgres
      DB_PASSWORD: postgres
    depends_on:
      - user-db
    networks:
      - microservices-network

  # Product Service
  product-db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: productdb
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - product-db-data:/var/lib/postgresql/data
    networks:
      - microservices-network

  product-service:
    build: ./product-service
    environment:
      DB_HOST: product-db
      DB_NAME: productdb
      DB_USER: postgres
      DB_PASSWORD: postgres
    depends_on:
      - product-db
    networks:
      - microservices-network

  # Order Service
  order-db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: orderdb
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - order-db-data:/var/lib/postgresql/data
    networks:
      - microservices-network

  order-service:
    build: ./order-service
    environment:
      DB_HOST: order-db
      DB_NAME: orderdb
      DB_USER: postgres
      DB_PASSWORD: postgres
      USER_SERVICE_URL: http://user-service:8000
      PRODUCT_SERVICE_URL: http://product-service:8000
    depends_on:
      - order-db
      - user-service
      - product-service
    networks:
      - microservices-network

  # API Gateway
  api-gateway:
    build: ./api-gateway
    ports:
      - "8080:80"
    depends_on:
      - user-service
      - product-service
      - order-service
    networks:
      - microservices-network

volumes:
  user-db-data:
  product-db-data:
  order-db-data:

networks:
  microservices-network:
    driver: bridge

Bước 7: Build và chạy hệ thống

# Build tất cả services
docker-compose build

# Chạy hệ thống
docker-compose up -d

# Xem logs
docker-compose logs -f

# Kiểm tra status
docker-compose ps

Bước 8: Test API với cURL
1. Tạo User:
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "0123456789"
  }'
2. Tạo Product:
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Laptop Dell XPS",
    "description": "High performance laptop",
    "price": 1500.00,
    "stock": 10
  }'
3.Tạo Order (inter-service communication):
curl -X POST http://localhost:8080/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "items": [
      {
        "product_id": 1,
        "quantity": 2
      }
    ]
  }'
4. Lấy thông tin

Lấy danh sách user: curl http://localhost:8080/api/users
Lấy danh dách products: curl http://localhost:8080/api/products
Lấy danh sách orders: curl http://localhost:8080/api/orders/1

5. Kiểm tra Inter-service Communication

# 1. Tạo user
USER_RESPONSE=$(curl -s -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice", "email": "alice@example.com", "phone": "1234567890"}')
USER_ID=$(echo $USER_RESPONSE | grep -o '"id":[0-9]*' | grep -o '[0-9]*')

# 2. Tạo product
PRODUCT_RESPONSE=$(curl -s -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{"name": "iPhone 15", "description": "Latest iPhone", "price": 999.99, "stock": 50}')
PRODUCT_ID=$(echo $PRODUCT_RESPONSE | grep -o '"id":[0-9]*' | grep -o '[0-9]*')

# 3. Tạo order (sẽ gọi cả User và Product service)
curl -X POST http://localhost:8080/api/orders \
  -H "Content-Type: application/json" \
  -d "{\"user_id\": $USER_ID, \"items\": [{\"product_id\": $PRODUCT_ID, \"quantity\": 2}]}"

# 4. Kiểm tra stock đã giảm
curl http://localhost:8080/api/products/$PRODUCT_ID

Bước 9: Kiểm tra Database

# User Database
docker-compose exec user-db psql -U postgres -d userdb -c "SELECT * FROM users;"

# Product Database
docker-compose exec product-db psql -U postgres -d productdb -c "SELECT * FROM products;"

# Order Database
docker-compose exec order-db psql -U postgres -d orderdb -c "SELECT * FROM orders;"
docker-compose exec order-db psql -U postgres -d orderdb -c "SELECT * FROM order_items;"