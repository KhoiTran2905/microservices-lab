Dùng Heroku cloud.
Tham khảo lại lab7 trong quá trình làm


Bước 1:  Cài đặt Heroku CLI, nếu đã cài ở lab 6 thì không cần cài lại.
đăng nhập
heroku login
Bước 2: Chuẩn bị code cho Heroku
2.1 Cập nhật User Service cho Heroku
Sửa user-service/server.js

const express = require('express');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());

// In-memory database
let users = [
    { id: 1, name: 'John Doe', email: 'john@example.com' },
    { id: 2, name: 'Jane Smith', email: 'jane@example.com' }
];

// Get all users
app.get('/users', (req, res) => {
    res.json(users);
});

// Get user by ID
app.get('/users/:id', (req, res) => {
    const user = users.find(u => u.id === parseInt(req.params.id));
    if (!user) {
        return res.status(404).json({ error: 'User not found' });
    }
    res.json(user);
});

// Create new user
app.post('/users', (req, res) => {
    const { name, email } = req.body;
    const newUser = {
        id: users.length + 1,
        name,
        email
    };
    users.push(newUser);
    res.status(201).json(newUser);
});

// Update user
app.put('/users/:id', (req, res) => {
    const userId = parseInt(req.params.id);
    const userIndex = users.findIndex(u => u.id === userId);
   
    if (userIndex === -1) {
        return res.status(404).json({ error: 'User not found' });
    }
   
    users[userIndex] = { ...users[userIndex], ...req.body };
    res.json(users[userIndex]);
});

// Delete user
app.delete('/users/:id', (req, res) => {
    const userId = parseInt(req.params.id);
    users = users.filter(u => u.id !== userId);
    res.status(204).send();
});

// Health check
app.get('/health', (req, res) => {
    res.json({
        service: 'user-service',
        status: 'healthy',
        timestamp: new Date().toISOString()
    });
});

// Root endpoint
app.get('/', (req, res) => {
    res.json({
        service: 'User Service',
        version: '1.0.0',
        endpoints: [
            'GET /users - Get all users',
            'GET /users/:id - Get user by ID',
            'POST /users - Create user',
            'PUT /users/:id - Update user',
            'DELETE /users/:id - Delete user',
            'GET /health - Health check'
        ]
    });
});

// IMPORTANT: Use process.env.PORT for Heroku
const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
    console.log(`User Service running on port ${PORT}`);
});

Tạo user-service/Procfile

web: node server.js

Cập nhật user-service/package.json

{
  "name": "user-service",
  "version": "1.0.0",
  "description": "User microservice for Heroku deployment",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "echo \"No tests yet\" && exit 0"
  },
  "engines": {
    "node": "16.x",
    "npm": "8.x"
  },
  "dependencies": {
    "express": "^4.18.2",
    "body-parser": "^1.20.2"
  },
  "devDependencies": {
    "nodemon": "^2.0.22"
  },
  "keywords": ["microservice", "api", "heroku"],
  "author": "Your Name",
  "license": "MIT"
}

2.2 Cập nhật Product Service
Sửa product-service/server.js

const express = require('express');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());

// In-memory database
let products = [
    { id: 1, name: 'Laptop', price: 999, stock: 10 },
    { id: 2, name: 'Mouse', price: 25, stock: 50 },
    { id: 3, name: 'Keyboard', price: 75, stock: 30 }
];

// Get all products
app.get('/products', (req, res) => {
    res.json(products);
});

// Get product by ID
app.get('/products/:id', (req, res) => {
    const product = products.find(p => p.id === parseInt(req.params.id));
    if (!product) {
        return res.status(404).json({ error: 'Product not found' });
    }
    res.json(product);
});

// Create new product
app.post('/products', (req, res) => {
    const { name, price, stock } = req.body;
    const newProduct = {
        id: products.length + 1,
        name,
        price: parseFloat(price),
        stock: parseInt(stock)
    };
    products.push(newProduct);
    res.status(201).json(newProduct);
});

// Update product stock
app.patch('/products/:id/stock', (req, res) => {
    const productId = parseInt(req.params.id);
    const { quantity } = req.body;
    const product = products.find(p => p.id === productId);
   
    if (!product) {
        return res.status(404).json({ error: 'Product not found' });
    }
   
    if (product.stock < quantity) {
        return res.status(400).json({ error: 'Insufficient stock' });
    }
   
    product.stock -= quantity;
    res.json(product);
});

// Health check
app.get('/health', (req, res) => {
    res.json({
        service: 'product-service',
        status: 'healthy',
        timestamp: new Date().toISOString()
    });
});

// Root endpoint
app.get('/', (req, res) => {
    res.json({
        service: 'Product Service',
        version: '1.0.0',
        endpoints: [
            'GET /products - Get all products',
            'GET /products/:id - Get product by ID',
            'POST /products - Create product',
            'PATCH /products/:id/stock - Update stock',
            'GET /health - Health check'
        ]
    });
});

const PORT = process.env.PORT || 3002;
app.listen(PORT, () => {
    console.log(`Product Service running on port ${PORT}`);
});


Tạo các file cần thiết cho Product Service

product-service/Procfile

web: node server.js


product-service/package.json


{
  "name": "product-service",
  "version": "1.0.0",
  "description": "Product microservice for Heroku deployment",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "echo \"No tests yet\" && exit 0"
  },
  "engines": {
    "node": "16.x",
    "npm": "8.x"
  },
  "dependencies": {
    "express": "^4.18.2",
    "body-parser": "^1.20.2"
  },
  "devDependencies": {
    "nodemon": "^2.0.22"
  },
  "keywords": ["microservice", "api", "heroku"],
  "author": "Your Name",
  "license": "MIT"
}

2.3 Cập nhật Order Service
Sửa order-service/server.js

const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');

const app = express();
app.use(bodyParser.json());

// Environment variables for service URLs
const USER_SERVICE_URL = process.env.USER_SERVICE_URL || 'http://localhost:3001&#39;;
const PRODUCT_SERVICE_URL = process.env.PRODUCT_SERVICE_URL || 'http://localhost:3002&#39;;

// In-memory database
let orders = [];

// Get all orders
app.get('/orders', (req, res) => {
    res.json(orders);
});

// Get order by ID
app.get('/orders/:id', (req, res) => {
    const order = orders.find(o => o.id === parseInt(req.params.id));
    if (!order) {
        return res.status(404).json({ error: 'Order not found' });
    }
    res.json(order);
});

// Create new order
app.post('/orders', async (req, res) => {
    try {
        const { userId, productId, quantity } = req.body;
       
        console.log(`Creating order: userId=${userId}, productId=${productId}, quantity=${quantity}`);
       
        // Verify user exists
        try {
            const userResponse = await axios.get(`${USER_SERVICE_URL}/users/${userId}`, {
                timeout: 5000
            });
            console.log('User verified:', userResponse.data);
        } catch (error) {
            console.error('User verification failed:', error.message);
            return res.status(400).json({ error: 'Invalid user or user service unavailable' });
        }
       
        // Verify product and check stock
        let product;
        try {
            const productResponse = await axios.get(`${PRODUCT_SERVICE_URL}/products/${productId}`, {
                timeout: 5000
            });
            product = productResponse.data;
            console.log('Product verified:', product);
        } catch (error) {
            console.error('Product verification failed:', error.message);
            return res.status(400).json({ error: 'Invalid product or product service unavailable' });
        }
       
        if (product.stock < quantity) {
            return res.status(400).json({ error: 'Insufficient stock' });
        }
       
        // Update product stock
        try {
            await axios.patch(`${PRODUCT_SERVICE_URL}/products/${productId}/stock`, {
                quantity
            }, { timeout: 5000 });
            console.log('Stock updated successfully');
        } catch (error) {
            console.error('Stock update failed:', error.message);
            return res.status(500).json({ error: 'Failed to update product stock' });
        }
       
        // Create order
        const newOrder = {
            id: orders.length + 1,
            userId: parseInt(userId),
            productId: parseInt(productId),
            quantity: parseInt(quantity),
            totalPrice: product.price * quantity,
            status: 'completed',
            createdAt: new Date().toISOString()
        };
       
        orders.push(newOrder);
        console.log('Order created:', newOrder);
        res.status(201).json(newOrder);
       
    } catch (error) {
        console.error('Order creation error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Health check
app.get('/health', (req, res) => {
    res.json({
        service: 'order-service',
        status: 'healthy',
        timestamp: new Date().toISOString(),
        dependencies: {
            userService: USER_SERVICE_URL,
            productService: PRODUCT_SERVICE_URL
        }
    });
});

// Root endpoint
app.get('/', (req, res) => {
    res.json({
        service: 'Order Service',
        version: '1.0.0',
        endpoints: [
            'GET /orders - Get all orders',
            'GET /orders/:id - Get order by ID',
            'POST /orders - Create order',
            'GET /health - Health check'
        ],
        dependencies: {
            userService: USER_SERVICE_URL,
            productService: PRODUCT_SERVICE_URL
        }
    });
});

const PORT = process.env.PORT || 3003;
app.listen(PORT, () => {
    console.log(`Order Service running on port ${PORT}`);
    console.log(`User Service URL: ${USER_SERVICE_URL}`);
    console.log(`Product Service URL: ${PRODUCT_SERVICE_URL}`);
});

Tạo các file cần thiết cho Order Service

order-service/Procfile

web: node server.js

order-service/package.json

{
  "name": "order-service",
  "version": "1.0.0",
  "description": "Order microservice for Heroku deployment",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "echo \"No tests yet\" && exit 0"
  },
  "engines": {
    "node": "16.x",
    "npm": "8.x"
  },
  "dependencies": {
    "express": "^4.18.2",
    "body-parser": "^1.20.2",
    "axios": "^1.4.0"
  },
  "devDependencies": {
    "nodemon": "^2.0.22"
  },
  "keywords": ["microservice", "api", "heroku"],
  "author": "Your Name",
  "license": "MIT"
}

2.4 Tạo API Gateway đơn giản
Tạo api-gateway/server.js

const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const cors = require('cors');

const app = express();

// Enable CORS
app.use(cors());
app.use(express.json());

// Environment variables for service URLs
const USER_SERVICE_URL = process.env.USER_SERVICE_URL || 'http://localhost:3001&#39;;
const PRODUCT_SERVICE_URL = process.env.PRODUCT_SERVICE_URL || 'http://localhost:3002&#39;;
const ORDER_SERVICE_URL = process.env.ORDER_SERVICE_URL || 'http://localhost:3003&#39;;

console.log('Service URLs:');
console.log('User Service:', USER_SERVICE_URL);
console.log('Product Service:', PRODUCT_SERVICE_URL);
console.log('Order Service:', ORDER_SERVICE_URL);

// Health check endpoint
app.get('/health', async (req, res) => {
    const healthChecks = {
        gateway: { status: 'healthy', timestamp: new Date().toISOString() },
        services: {}
    };
   
    // Check user service
    try {
        const userHealth = await fetch(`${USER_SERVICE_URL}/health`);
        healthChecks.services.userService = { status: 'healthy', url: USER_SERVICE_URL };
    } catch (error) {
        healthChecks.services.userService = { status: 'unhealthy', url: USER_SERVICE_URL, error: error.message };
    }
   
    // Check product service
    try {
        const productHealth = await fetch(`${PRODUCT_SERVICE_URL}/health`);
        healthChecks.services.productService = { status: 'healthy', url: PRODUCT_SERVICE_URL };
    } catch (error) {
        healthChecks.services.productService = { status: 'unhealthy', url: PRODUCT_SERVICE_URL, error: error.message };
    }
   
    // Check order service
    try {
        const orderHealth = await fetch(`${ORDER_SERVICE_URL}/health`);
        healthChecks.services.orderService = { status: 'healthy', url: ORDER_SERVICE_URL };
    } catch (error) {
        healthChecks.services.orderService = { status: 'unhealthy', url: ORDER_SERVICE_URL, error: error.message };
    }
   
    res.json(healthChecks);
});

// Proxy configuration với error handling
const createProxyWithErrorHandling = (target, pathRewrite) => {
    return createProxyMiddleware({
        target,
        changeOrigin: true,
        pathRewrite,
        timeout: 10000,
        onError: (err, req, res) => {
            console.error(`Proxy error for ${req.url}:`, err.message);
            res.status(503).json({
                error: 'Service temporarily unavailable',
                service: target,
                timestamp: new Date().toISOString()
            });
        },
        onProxyReq: (proxyReq, req, res) => {
            console.log(`Proxying ${req.method} ${req.url} to ${target}`);
        }
    });
};

// Create proxy middleware for each service
app.use('/users', createProxyWithErrorHandling(USER_SERVICE_URL, { '^/users': '' }));
app.use('/products', createProxyWithErrorHandling(PRODUCT_SERVICE_URL, { '^/products': '' }));
app.use('/orders', createProxyWithErrorHandling(ORDER_SERVICE_URL, { '^/orders': '' }));

// Default route
app.get('/', (req, res) => {
    res.json({
        message: 'Microservices API Gateway',
        version: '1.0.0',
        services: {
            userService: USER_SERVICE_URL,
            productService: PRODUCT_SERVICE_URL,
            orderService: ORDER_SERVICE_URL
        },
        endpoints: [
            'GET /users - Get all users',
            'POST /users - Create user',
            'GET /products - Get all products',
            'POST /products - Create product',
            'GET /orders - Get all orders',
            'POST /orders - Create order',
            'GET /health - Health check all services'
        ],
        timestamp: new Date().toISOString()
    });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`API Gateway running on port ${PORT}`);
});

Tạo các file cần thiết cho API Gateway

api-gateway/Procfile

web: node server.js

api-gateway/package.json


{
  "name": "api-gateway",
  "version": "1.0.0",
  "description": "API Gateway for microservices on Heroku",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "echo \"No tests yet\" && exit 0"
  },
  "engines": {
    "node": "16.x",
    "npm": "8.x"
  },
  "dependencies": {
    "express": "^4.18.2",
    "http-proxy-middleware": "^2.0.6",
    "cors": "^2.8.5"
  },
  "devDependencies": {
    "nodemon": "^2.0.22"
  },
  "keywords": ["api-gateway", "microservice", "heroku"],
  "author": "Your Name",
  "license": "MIT"
}

Bước 3: Deploy từng service lên Heroku
3.1 Deploy User Service

cd user-service

# Khởi tạo git repository
git init
git add .
git commit -m "Initial commit - User Service"

# Tạo Heroku app
heroku create your-username-user-service

# Deploy
git push heroku main

# Kiểm tra logs
heroku logs --tail

# Test service
heroku open
# hoặc
curl https://your-username-user-service.herokuapp.com/health

3.2 Deploy Product Service

cd ../product-service

# Khởi tạo git repository
git init
git add .
git commit -m "Initial commit - Product Service"

# Tạo Heroku app
heroku create your-username-product-service

# Deploy
git push heroku main

# Test service
curl https://your-username-product-service.herokuapp.com/health

3.3 Deploy Order Service

cd ../order-service

# Khởi tạo git repository
git init
git add .
git commit -m "Initial commit - Order Service"

# Tạo Heroku app
heroku create your-username-order-service

# Set environment variables cho service URLs
heroku config:set USER_SERVICE_URL=https://your-username-user-service.herokuapp.com
heroku config:set PRODUCT_SERVICE_URL=https://your-username-product-service.herokuapp.com

# Deploy
git push heroku main

# Test service
curl https://your-username-order-service.herokuapp.com/health

3.4 Deploy API Gateway

cd ../api-gateway

# Khởi tạo git repository
git init
git add .
git commit -m "Initial commit - API Gateway"

# Tạo Heroku app
heroku create your-username-api-gateway

# Set environment variables
heroku config:set USER_SERVICE_URL=https://your-username-user-service.herokuapp.com
heroku config:set PRODUCT_SERVICE_URL=https://your-username-product-service.herokuapp.com
heroku config:set ORDER_SERVICE_URL=https://your-username-order-service.herokuapp.com

# Deploy
git push heroku main

# Test gateway
curl https://your-username-api-gateway.herokuapp.com/health

Bước 4: Testing toàn bộ hệ thống

4.1 Test script
#!/bin/bash
# test-heroku.sh

GATEWAY_URL="https://your-username-api-gateway.herokuapp.com&quot;

echo "Testing API Gateway..."
curl -s "$GATEWAY_URL/" | jq .

echo -e "\n\nTesting health checks..."
curl -s "$GATEWAY_URL/health" | jq .

echo -e "\n\nTesting Users service..."
curl -s "$GATEWAY_URL/users" | jq .

echo -e "\n\nCreating new user..."
curl -s -X POST "$GATEWAY_URL/users" \
  -H "Content-Type: application/json" \
  -d '{"name": "Test User", "email": "test@heroku.com"}' | jq .

echo -e "\n\nTesting Products service..."
curl -s "$GATEWAY_URL/products" | jq .

echo -e "\n\nCreating new product..."
curl -s -X POST "$GATEWAY_URL/products" \
  -H "Content-Type: application/json" \
  -d '{"name": "Heroku Product", "price": 50, "stock": 100}' | jq .

echo -e "\n\nCreating order..."
curl -s -X POST "$GATEWAY_URL/orders" \
  -H "Content-Type: application/json" \
  -d '{"userId": 1, "productId": 1, "quantity": 2}' | jq .

echo -e "\n\nGetting all orders..."
curl -s "$GATEWAY_URL/orders" | jq .

4.2 Chạy test

chmod +x test-heroku.sh
./test-heroku.sh

Bước 5: Giám sát Logging

5.1 Xem logs từng service

# User service logs
heroku logs --tail --app your-username-user-service

# Product service logs
heroku logs --tail --app your-username-product-service

# Order service logs
heroku logs --tail --app your-username-order-service

# API Gateway logs
heroku logs --tail --app your-username-api-gateway

5.2 Truy cập Heroku Dashboard
Truy cập: https://dashboard.heroku.com/apps
Monitor metrics: Response time, throughput, errors
View logs trực tiếp từ web interface

5.3 Thêm Add-ons cho monitoring

 # Papertrail cho loggingheroku addons:create papertrail --app your-username-api-gateway

# New Relic cho APM
heroku addons:create newrelic --app your-username-api-gateway

# Heroku Postgres cho database

heroku addons:create heroku-postgresql:hobby-dev --app your-username-user-service 

Bước 6: Quản lý Environment Variables
Set config vars

# Cho từng app
heroku config:set NODE_ENV=production --app your-username-user-service
heroku config:set LOG_LEVEL=info --app your-username-user-service

# Cho API Gateway
heroku config:set NODE_ENV=production --app your-username-api-gateway
heroku config:set RATE_LIMIT=1000 --app your-username-api-gateway

Xem config vars
heroku config --app your-username-api-gateway

Bước 7: Custom Domain và SSL
7.1 Add custom domain
heroku domains:add api.yourdomain.com --app your-username-api-gateway
heroku certs:auto:enable --app your-username-api-gateway
7.2 DNS Configuration
# Add CNAME record in your DNS provider:
api.yourdomain.com CNAME your-username-api-gateway.herokuapp.com

Bước 8: CI/CD với GitHub
8.1 Connect GitHub repository
# Enable GitHub integration
heroku git:remote -a your-username-api-gateway

# Or connect via Heroku Dashboard:
1. Go to Deploy tab
2. Connect GitHub
3. Enable automatic deploys

8.2 GitHub Actions workflow
# .github/workflows/heroku-deploy.yml
name: Deploy to Heroku

on:
  push:
    branches: [ main ]

jobs:
  deploy-user-service:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: akhileshns/heroku-deploy@v3.12.12
      with:
        heroku_api_key: ${{secrets.HEROKU_API_KEY}}
        heroku_app_name: "your-username-user-service"
        heroku_email: "your-email@example.com"
        appdir: "user-service"

  deploy-product-service:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: akhileshns/heroku-deploy@v3.12.12
      with:
        heroku_api_key: ${{secrets.HEROKU_API_KEY}}
        heroku_app_name: "your-username-product-service"
        heroku_email: "your-email@example.com"
        appdir: "product-service"

  deploy-order-service:
    runs-on: ubuntu-latest
    needs: [deploy-user-service, deploy-product-service]
    steps:
    - uses: actions/checkout@v2
    - uses: akhileshns/heroku-deploy@v3.12.12
      with:
        heroku_api_key: ${{secrets.HEROKU_API_KEY}}
        heroku_app_name: "your-username-order-service"
        heroku_email: "your-email@example.com"
        appdir: "order-service"

  deploy-api-gateway:
    runs-on: ubuntu-latest
    needs: [deploy-user-service, deploy-product-service, deploy-order-service]
    steps:
    - uses: actions/checkout@v2
    - uses: akhileshns/heroku-deploy@v3.12.12
      with:
        heroku_api_key: ${{secrets.HEROKU_API_KEY}}
        heroku_app_name: "your-username-api-gateway"
        heroku_email: "your-email@example.com"
        appdir: "api-gateway"

Bước 9: Database Integration
9.1 Add Heroku Postgres

# Add Postgres addon
heroku addons:create heroku-postgresql:hobby-dev --app your-username-user-service
heroku addons:create heroku-postgresql:hobby-dev --app your-username-product-service
heroku addons:create heroku-postgresql:hobby-dev --app your-username-order-service

# Get database URL
heroku config:get DATABASE_URL --app your-username-user-service
9.2 Update User Service với Postgres
// user-service/db.js
const { Pool } = require('pg');

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

// Initialize tables
const initDB = async () => {
    try {
        await pool.query(`
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                email VARCHAR(255) UNIQUE NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        `);
        console.log('Users table initialized');
    } catch (error) {
        console.error('Database initialization error:', error);
    }
};

module.exports = { pool, initDB };
----------------------------------------------------------------------------------------------------------------------------------------
// Update user-service/server.js, de khoai tao DB
const express = require('express');
const bodyParser = require('body-parser');
const { pool, initDB } = require('./db');

const app = express();
app.use(bodyParser.json());

// Initialize database
initDB();

// Get all users
app.get('/users', async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM users ORDER BY id');
        res.json(result.rows);
    } catch (error) {
        console.error('Database error:', error);
        res.status(500).json({ error: 'Database error' });
    }
});

// Get user by ID
app.get('/users/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query('SELECT * FROM users WHERE id = $1', [id]);
       
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }
       
        res.json(result.rows[0]);
    } catch (error) {
        console.error('Database error:', error);
        res.status(500).json({ error: 'Database error' });
    }
});

// Create new user
app.post('/users', async (req, res) => {
    try {
        const { name, email } = req.body;
        const result = await pool.query(
            'INSERT INTO users (name, email) VALUES ($1, $2) RETURNING *',
            [name, email]
        );
        res.status(201).json(result.rows[0]);
    } catch (error) {
        if (error.code === '23505') { // Unique violation
            res.status(400).json({ error: 'Email already exists' });
        } else {
            console.error('Database error:', error);
            res.status(500).json({ error: 'Database error' });
        }
    }
});

// Update user
app.put('/users/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { name, email } = req.body;
       
        const result = await pool.query(
            'UPDATE users SET name = $1, email = $2, updated_at = CURRENT_TIMESTAMP WHERE id = $3 RETURNING *',
            [name, email, id]
        );
       
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }
       
        res.json(result.rows[0]);
    } catch (error) {
        console.error('Database error:', error);
        res.status(500).json({ error: 'Database error' });
    }
});

// Delete user
app.delete('/users/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query('DELETE FROM users WHERE id = $1', [id]);
       
        if (result.rowCount === 0) {
            return res.status(404).json({ error: 'User not found' });
        }
       
        res.status(204).send();
    } catch (error) {
        console.error('Database error:', error);
        res.status(500).json({ error: 'Database error' });
    }
});

// Health check
app.get('/health', async (req, res) => {
    try {
        await pool.query('SELECT 1');
        res.json({
            service: 'user-service',
            status: 'healthy',
            database: 'connected',
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        res.status(500).json({
            service: 'user-service',
            status: 'unhealthy',
            database: 'disconnected',
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

// Root endpoint
app.get('/', (req, res) => {
    res.json({
        service: 'User Service',
        version: '2.0.0',
        database: 'PostgreSQL',
        endpoints: [
            'GET /users - Get all users',
            'GET /users/:id - Get user by ID',
            'POST /users - Create user',
            'PUT /users/:id - Update user',
            'DELETE /users/:id - Delete user',
            'GET /health - Health check'
        ]
    });
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
    console.log(`User Service running on port ${PORT}`);
});


9.3 Update package.json cho database
{
  "dependencies": {
    "express": "^4.18.2",
    "body-parser": "^1.20.2",
    "pg": "^8.11.0"
  }
}

9.4 Deploy code mới

cd user-service
# Commit changes
git add .
git commit -m "Add PostgreSQL integration"

# Deploy
git push heroku main

# Xem logs
heroku logs --tail --app your-username-user-service

9.5 Test Database Connection
Test qua Heroku CLI

# Connect to database
heroku pg:psql --app your-username-user-service

# Trong PostgreSQL console:
# List tables
\dt


# Query users
SELECT * FROM users;


# Count users
SELECT COUNT(*) FROM users WHERE deleted_at IS NULL;

# Exit
\q

Test qua API  

# Set your app URL
GATEWAY_URL="https://your-username-api-gateway.herokuapp.com&quot;

# Test health check
curl -s "$GATEWAY_URL/users/health" | jq .

# Expected:
{
  "service": "user-service",
  "status": "healthy",
  "database": "connected",
  "timestamp": "2024-01-15T10:30:00.000Z"
}