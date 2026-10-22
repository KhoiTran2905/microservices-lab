Mục tiêu

Hiểu khái niệm microservices và cách triển khai cơ bản

Xây dựng 3 microservices độc lập

Sử dụng API Gateway để quản lý traffic

Triển khai với Docker và Docker Compose





1.Thiết kế kiến trúc hệ thống:

API Gateway (Port 3000)

├── User Service (Port 3001)

├── Product Service (Port 3002)

└── Order Service (Port 3003)



2.Thiết lập môi trường



2.1 Tạo thư mục dự án



mkdir microservices-lab

cd microservices-lab

mkdir api-gateway user-service product-service order-service



2.2.Khởi tạo package.json cho từng service



\# API Gateway

cd api-gateway

npm init -y

npm install express http-proxy-middleware cors



\# User Service

cd ../user-service

npm init -y

npm install express body-parser



\# Product Service

cd ../product-service

npm init -y

npm install express body-parser



\# Order Service

cd ../order-service

npm init -y

npm install express body-parser axios



cd ..



3\. Xây dựng User Service



\#Tạo file user-service/server.js

const express = require('express');

const bodyParser = require('body-parser');



const app = express();

app.use(bodyParser.json());



// In-memory database

let users = \[

&#x20;   { id: 1, name: 'John Doe', email: 'john@example.com' },

&#x20;   { id: 2, name: 'Jane Smith', email: 'jane@example.com' }

];



// Get all users

app.get('/users', (req, res) => {

&#x20;   res.json(users);

});



// Get user by ID

app.get('/users/:id', (req, res) => {

&#x20;   const user = users.find(u => u.id === parseInt(req.params.id));

&#x20;   if (!user) {

&#x20;       return res.status(404).json({ error: 'User not found' });

&#x20;   }

&#x20;   res.json(user);

});



// Create new user

app.post('/users', (req, res) => {

&#x20;   const { name, email } = req.body;

&#x20;   const newUser = {

&#x20;       id: users.length + 1,

&#x20;       name,

&#x20;       email

&#x20;   };

&#x20;   users.push(newUser);

&#x20;   res.status(201).json(newUser);

});



// Update user

app.put('/users/:id', (req, res) => {

&#x20;   const userId = parseInt(req.params.id);

&#x20;   const userIndex = users.findIndex(u => u.id === userId);

&#x20;  

&#x20;   if (userIndex === -1) {

&#x20;       return res.status(404).json({ error: 'User not found' });

&#x20;   }

&#x20;  

&#x20;   users\[userIndex] = { ...users\[userIndex], ...req.body };

&#x20;   res.json(users\[userIndex]);

});



// Delete user

app.delete('/users/:id', (req, res) => {

&#x20;   const userId = parseInt(req.params.id);

&#x20;   users = users.filter(u => u.id !== userId);

&#x20;   res.status(204).send();

});



// Health check

app.get('/health', (req, res) => {

&#x20;   res.json({ service: 'user-service', status: 'healthy' });

});



const PORT = process.env.PORT || 3001;

app.listen(PORT, () => {

&#x20;   console.log(`User Service running on port ${PORT}`);

});



4\. Xây dựng Product Service



\#Tạo file product-service/server.js

const express = require('express');

const bodyParser = require('body-parser');



const app = express();

app.use(bodyParser.json());



// In-memory database

let products = \[

&#x20;   { id: 1, name: 'Laptop', price: 999, stock: 10 },

&#x20;   { id: 2, name: 'Mouse', price: 25, stock: 50 },

&#x20;   { id: 3, name: 'Keyboard', price: 75, stock: 30 }

];



// Get all products

app.get('/products', (req, res) => {

&#x20;   res.json(products);

});



// Get product by ID

app.get('/products/:id', (req, res) => {

&#x20;   const product = products.find(p => p.id === parseInt(req.params.id));

&#x20;   if (!product) {

&#x20;       return res.status(404).json({ error: 'Product not found' });

&#x20;   }

&#x20;   res.json(product);

});



// Create new product

app.post('/products', (req, res) => {

&#x20;   const { name, price, stock } = req.body;

&#x20;   const newProduct = {

&#x20;       id: products.length + 1,

&#x20;       name,

&#x20;       price,

&#x20;       stock

&#x20;   };

&#x20;   products.push(newProduct);

&#x20;   res.status(201).json(newProduct);

});



// Update product stock

app.patch('/products/:id/stock', (req, res) => {

&#x20;   const productId = parseInt(req.params.id);

&#x20;   const { quantity } = req.body;

&#x20;   const product = products.find(p => p.id === productId);

&#x20;  

&#x20;   if (!product) {

&#x20;       return res.status(404).json({ error: 'Product not found' });

&#x20;   }

&#x20;  

&#x20;   if (product.stock < quantity) {

&#x20;       return res.status(400).json({ error: 'Insufficient stock' });

&#x20;   }

&#x20;  

&#x20;   product.stock -= quantity;

&#x20;   res.json(product);

});



// Health check

app.get('/health', (req, res) => {

&#x20;   res.json({ service: 'product-service', status: 'healthy' });

});



const PORT = process.env.PORT || 3002;

app.listen(PORT, () => {

&#x20;   console.log(`Product Service running on port ${PORT}`);

});



5.Xây dựng Order Service



\#Tạo file order-service/server.js



const express = require('express');

const bodyParser = require('body-parser');

const axios = require('axios');



const app = express();

app.use(bodyParser.json());



// In-memory database

let orders = \[];



// Get all orders

app.get('/orders', (req, res) => {

&#x20;   res.json(orders);

});



// Get order by ID

app.get('/orders/:id', (req, res) => {

&#x20;   const order = orders.find(o => o.id === parseInt(req.params.id));

&#x20;   if (!order) {

&#x20;       return res.status(404).json({ error: 'Order not found' });

&#x20;   }

&#x20;   res.json(order);

});



// Create new order

app.post('/orders', async (req, res) => {

&#x20;   try {

&#x20;       const { userId, productId, quantity } = req.body;

&#x20;      

&#x20;       // Verify user exists

&#x20;       const userResponse = await axios.get(`http://user-service:3001/users/${userId}`);

&#x20;       if (userResponse.status !== 200) {

&#x20;           return res.status(400).json({ error: 'Invalid user' });

&#x20;       }

&#x20;      

&#x20;       // Verify product and check stock

&#x20;       const productResponse = await axios.get(`http://product-service:3002/products/${productId}`);

&#x20;       if (productResponse.status !== 200) {

&#x20;           return res.status(400).json({ error: 'Invalid product' });

&#x20;       }

&#x20;      

&#x20;       const product = productResponse.data;

&#x20;       if (product.stock < quantity) {

&#x20;           return res.status(400).json({ error: 'Insufficient stock' });

&#x20;       }

&#x20;      

&#x20;       // Update product stock

&#x20;       await axios.patch(`http://product-service:3002/products/${productId}/stock`, {

&#x20;           quantity

&#x20;       });

&#x20;      

&#x20;       // Create order

&#x20;       const newOrder = {

&#x20;           id: orders.length + 1,

&#x20;           userId,

&#x20;           productId,

&#x20;           quantity,

&#x20;           totalPrice: product.price \* quantity,

&#x20;           status: 'completed',

&#x20;           createdAt: new Date().toISOString()

&#x20;       };

&#x20;      

&#x20;       orders.push(newOrder);

&#x20;       res.status(201).json(newOrder);

&#x20;      

&#x20;   } catch (error) {

&#x20;       console.error('Order creation error:', error.message);

&#x20;       res.status(500).json({ error: 'Failed to create order' });

&#x20;   }

});



// Health check

app.get('/health', (req, res) => {

&#x20;   res.json({ service: 'order-service', status: 'healthy' });

});



const PORT = process.env.PORT || 3003;

app.listen(PORT, () => {

&#x20;   console.log(`Order Service running on port ${PORT}`);

});



6.Xây dựng API Gateway



\#Tạo file api-gateway/server.js

const express = require('express');

const { createProxyMiddleware } = require('http-proxy-middleware');

const cors = require('cors');



const app = express();



// Enable CORS

app.use(cors());

app.use(express.json());



// Health check endpoint

app.get('/health', (req, res) => {

&#x20;   res.json({ service: 'api-gateway', status: 'healthy' });

});



// Proxy configuration

const services = {

&#x20;   users: 'http://user-service:3001\&#39;,

&#x20;   products: 'http://product-service:3002\&#39;,

&#x20;   orders: 'http://order-service:3003\&#39;

};



// Create proxy middleware for each service

Object.keys(services).forEach(path => {

&#x20;   app.use(`/${path}`, createProxyMiddleware({

&#x20;       target: services\[path],

&#x20;       changeOrigin: true,

&#x20;       pathRewrite: {

&#x20;           \[`^/${path}`]: ''

&#x20;       }

&#x20;   }));

});



// Default route

app.get('/', (req, res) => {

&#x20;   res.json({

&#x20;       message: 'API Gateway',

&#x20;       services: Object.keys(services),

&#x20;       endpoints: \[

&#x20;           'GET /users - Get all users',

&#x20;           'POST /users - Create user',

&#x20;           'GET /products - Get all products',

&#x20;           'POST /products - Create product',

&#x20;           'GET /orders - Get all orders',

&#x20;           'POST /orders - Create order'

&#x20;       ]

&#x20;   });

});



const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {

&#x20;   console.log(`API Gateway running on port ${PORT}`);

});



7\. Khai triển lên docker

7.1. Tạo Dockerfile cho từng service



\-Dockerfile cho User Service (user-service/Dockerfile)

FROM node:14-alpine

WORKDIR /app

COPY package\*.json ./

RUN npm install

COPY . .

EXPOSE 3001

CMD \["node", "server.js"]

\-Dockerfile cho Product Service (product-service/Dockerfile)

FROM node:14-alpine

WORKDIR /app

COPY package\*.json ./

RUN npm install

COPY . .

EXPOSE 3002

CMD \["node", "server.js"]

\-Dockerfile cho Order Service (order-service/Dockerfile)

FROM node:14-alpine

WORKDIR /app

COPY package\*.json ./

RUN npm install

COPY . .

EXPOSE 3003

CMD \["node", "server.js"]

\-Dockerfile cho API Gateway (api-gateway/Dockerfile)

FROM node:14-alpine

WORKDIR /app

COPY package\*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD \["node", "server.js"]



7.2 Tạo Docker Compose file (docker-compose.yml)

version: '3.8'

services:

&#x20; api-gateway:

&#x20;   build: ./api-gateway

&#x20;   ports:

&#x20;     - "3000:3000"

&#x20;   depends\_on:

&#x20;     - user-service

&#x20;     - product-service

&#x20;     - order-service

&#x20;   networks:

&#x20;     - microservices-network



&#x20; user-service:

&#x20;   build: ./user-service

&#x20;   ports:

&#x20;     - "3001:3001"

&#x20;   networks:

&#x20;     - microservices-network



&#x20; product-service:

&#x20;   build: ./product-service

&#x20;   ports:

&#x20;     - "3002:3002"

&#x20;   networks:

&#x20;     - microservices-network



&#x20; order-service:

&#x20;   build: ./order-service

&#x20;   ports:

&#x20;     - "3003:3003"

&#x20;   depends\_on:

&#x20;     - user-service

&#x20;     - product-service

&#x20;   networks:

&#x20;     - microservices-network



networks:

&#x20; microservices-network:

&#x20;   driver: bridge



8.Chạy ứng dụng

8.1 Build và chạy với Docker Compose



\# Build và chạy tất cả services

docker-compose up --build



\# Chạy ở background

docker-compose up -d --build



\# Xem logs

docker-compose logs -f



\# Dừng services

docker-compose down



8.2 Kiểm tra các services



curl http://localhost:3000/health  # API Gateway

curl http://localhost:3001/health  # User Service

curl http://localhost:3002/health  # Product Service

curl http://localhost:3003/health  # Order Service



9.Test API

9.1Test qua API Gateway



\# Get all users

curl http://localhost:3000/users



\# Create new user

curl -X POST http://localhost:3000/users \\

&#x20; -H "Content-Type: application/json" \\

&#x20; -d '{"name": "Test User", "email": "test@example.com"}'



\# Get all products

curl http://localhost:3000/products



\# Create new product

curl -X POST http://localhost:3000/products \\

&#x20; -H "Content-Type: application/json" \\

&#x20; -d '{"name": "Test Product", "price": 100, "stock": 20}'



\# Create order

curl -X POST http://localhost:3000/orders \\

&#x20; -H "Content-Type: application/json" \\

&#x20; -d '{"userId": 1, "productId": 1, "quantity": 2}'



\# Get all orders

curl http://localhost:3000/orders



9.2 Test với Postman

Import collection với các endpoint sau:

GET http://localhost:3000/users

POST http://localhost:3000/users

GET http://localhost:3000/products

POST http://localhost:3000/products

POST http://localhost:3000/orders

GET http://localhost:3000/orders



10\. Nộp báo cáo

