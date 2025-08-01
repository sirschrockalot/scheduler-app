const express = require('express');
const cors = require('cors');
const app = express();
const PORT = process.env.PORT || 8080;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Request logging middleware
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${req.method} ${req.path} - ${req.ip}`);
  console.log('Headers:', req.headers);
  if (req.body && Object.keys(req.body).length > 0) {
    console.log('Body:', req.body);
  }
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'test-api-server'
  });
});

// Status endpoint
app.get('/status', (req, res) => {
  res.json({
    status: 'running',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    endpoints: [
      'GET /health',
      'GET /status',
      'POST /report/afternoon'
    ]
  });
});

// KPI Afternoon Report endpoint
app.post('/report/afternoon', (req, res) => {
  // Check for Authorization header
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      status: 'error',
      message: 'Missing or invalid Authorization header',
      timestamp: new Date().toISOString()
    });
  }

  // Simulate processing time
  setTimeout(() => {
    const response = {
      status: 'success',
      timestamp: new Date().toISOString(),
      data: {
        report_type: 'afternoon_kpi',
        generated_at: new Date().toISOString(),
        user_activity: {
          total_calls: Math.floor(Math.random() * 100) + 20,
          avg_duration: `${Math.floor(Math.random() * 5) + 1}m ${Math.floor(Math.random() * 60)}s`,
          success_rate: (Math.random() * 0.3 + 0.7).toFixed(2),
          peak_hours: ['10:00', '14:00', '16:00'],
          top_performers: [
            { name: 'John Doe', calls: 15, avg_duration: '4m 12s' },
            { name: 'Jane Smith', calls: 12, avg_duration: '3m 45s' },
            { name: 'Bob Johnson', calls: 10, avg_duration: '5m 20s' }
          ]
        },
        metrics: {
          response_time: `${Math.floor(Math.random() * 200) + 50}ms`,
          error_rate: (Math.random() * 0.1).toFixed(3),
          uptime: '99.8%'
        }
      }
    };

    console.log('✅ KPI Report generated successfully');
    res.json(response);
  }, 1000); // Simulate 1 second processing time
});

// Catch-all for undefined routes
app.use('*', (req, res) => {
  res.status(404).json({
    status: 'error',
    message: 'Endpoint not found',
    available_endpoints: [
      'GET /health',
      'GET /status',
      'POST /report/afternoon'
    ],
    timestamp: new Date().toISOString()
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    status: 'error',
    message: 'Internal server error',
    timestamp: new Date().toISOString()
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🧪 Test API Server running on port ${PORT}`);
  console.log(`📊 Available endpoints:`);
  console.log(`   GET  http://localhost:${PORT}/health`);
  console.log(`   GET  http://localhost:${PORT}/status`);
  console.log(`   POST http://localhost:${PORT}/report/afternoon`);
  console.log(`📝 Ready to receive KPI job requests!`);
}); 