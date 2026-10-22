const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const cors = require('cors');

const app = express();

// Enable CORS
// Lưu ý: KHÔNG dùng express.json() trước proxy - nó đọc hết body nên request POST bị treo khi chuyển tiếp
app.use(cors());

// Environment variables for service URLs
const USER_SERVICE_URL = process.env.USER_SERVICE_URL || 'http://localhost:3001';
const PRODUCT_SERVICE_URL = process.env.PRODUCT_SERVICE_URL || 'http://localhost:3002';
const ORDER_SERVICE_URL = process.env.ORDER_SERVICE_URL || 'http://localhost:3003';
// Đủ dài để chờ service free trên Render thức dậy
const PROXY_TIMEOUT = parseInt(process.env.PROXY_TIMEOUT || '90000');

console.log('Service URLs:');
console.log('User Service:', USER_SERVICE_URL);
console.log('Product Service:', PRODUCT_SERVICE_URL);
console.log('Order Service:', ORDER_SERVICE_URL);

const checkService = async (url) => {
    try {
        const response = await fetch(`${url}/health`, { signal: AbortSignal.timeout(PROXY_TIMEOUT) });
        return { status: response.ok ? 'healthy' : 'unhealthy', url, httpStatus: response.status };
    } catch (error) {
        return { status: 'unhealthy', url, error: error.message };
    }
};

// Health check endpoint
app.get('/health', async (req, res) => {
    const [userService, productService, orderService] = await Promise.all([
        checkService(USER_SERVICE_URL),
        checkService(PRODUCT_SERVICE_URL),
        checkService(ORDER_SERVICE_URL)
    ]);
    res.json({
        gateway: { status: 'healthy', timestamp: new Date().toISOString() },
        services: { userService, productService, orderService }
    });
});

// Proxy configuration với error handling
const createProxyWithErrorHandling = (target, pathRewrite) => {
    return createProxyMiddleware({
        target,
        changeOrigin: true,
        pathRewrite,
        timeout: PROXY_TIMEOUT,
        proxyTimeout: PROXY_TIMEOUT,
        onError: (err, req, res) => {
            console.error(`Proxy error for ${req.url}:`, err.message);
            res.status(503).json({
                error: 'Service temporarily unavailable',
                service: target,
                timestamp: new Date().toISOString()
            });
        },
        onProxyReq: (proxyReq, req, res) => {
            console.log(`Proxying ${req.method} ${req.originalUrl} to ${target}`);
        }
    });
};

// Giữ nguyên path (/users/1 -> /users/1), chỉ đổi /users/health -> /health của service
app.use('/users', createProxyWithErrorHandling(USER_SERVICE_URL, { '^/users/health$': '/health' }));
app.use('/products', createProxyWithErrorHandling(PRODUCT_SERVICE_URL, { '^/products/health$': '/health' }));
app.use('/orders', createProxyWithErrorHandling(ORDER_SERVICE_URL, { '^/orders/health$': '/health' }));

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
