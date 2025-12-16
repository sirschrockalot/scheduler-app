#!/usr/bin/env node

/**
 * Script to manually trigger the nightly KPI report job
 * This will send yesterday's data to the KPI service
 */

const axios = require('axios');
const jwt = require('jsonwebtoken');

// Load environment variables
require('dotenv').config();

async function triggerNightlyJob() {
  try {
    // Get JWT token - use JWT_SECRET if available, otherwise use JWT_TOKEN
    let token;
    
    if (process.env.JWT_SECRET) {
      // Generate token using TokenManager logic
      const secret = process.env.JWT_SECRET;
      const subject = process.env.JWT_SUB || 'scheduler-app';
      const now = Math.floor(Date.now() / 1000);
      const ttlSeconds = Number(process.env.JWT_TTL_SECONDS || 60 * 24 * 60 * 60);
      const exp = now + ttlSeconds;
      
      token = jwt.sign({ sub: subject, iat: now, exp }, secret);
      console.log('✅ Generated JWT token using JWT_SECRET');
    } else if (process.env.JWT_TOKEN) {
      token = process.env.JWT_TOKEN;
      console.log('✅ Using JWT_TOKEN from environment');
    } else {
      throw new Error('Either JWT_SECRET or JWT_TOKEN must be set');
    }

    // KPI service endpoint
    const url = 'https://slack-kpi-service-dbf2f7d60f2e.herokuapp.com/report/night';
    
    console.log('🚀 Triggering nightly KPI report...');
    console.log(`📡 Endpoint: ${url}`);
    
    const response = await axios.post(url, {}, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'X-Custom-Header': 'kpi-app',
        'Content-Type': 'application/json'
      },
      timeout: 30000
    });

    console.log('✅ Nightly job completed successfully!');
    console.log(`📊 Status Code: ${response.status}`);
    if (response.data) {
      console.log('📄 Response:', JSON.stringify(response.data, null, 2));
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Failed to trigger nightly job:');
    if (error.response) {
      console.error(`📊 Status Code: ${error.response.status}`);
      console.error(`📄 Response:`, JSON.stringify(error.response.data, null, 2));
    } else if (error.request) {
      console.error('🌐 Network Error:', error.message);
    } else {
      console.error('💥 Error:', error.message);
    }
    process.exit(1);
  }
}

triggerNightlyJob();

