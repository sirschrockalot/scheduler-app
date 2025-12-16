#!/usr/bin/env node

const axios = require('axios');

async function checkHerokuStatus() {
  const appUrl = 'https://your-app.herokuapp.com'; // Replace with your actual Heroku app URL
  
  console.log('🔍 Checking Heroku Deployment Status');
  console.log('=====================================');
  
  try {
    // Check health endpoint
    console.log('\n1. Health Check:');
    const healthResponse = await axios.get(`${appUrl}/health`, { timeout: 10000 });
    console.log(`✅ Health: ${healthResponse.data.status}`);
    console.log(`📅 Timestamp: ${healthResponse.data.timestamp}`);
    
    // Check detailed status
    console.log('\n2. Detailed Status:');
    const statusResponse = await axios.get(`${appUrl}/status`, { timeout: 10000 });
    const status = statusResponse.data;
    
    console.log(`📊 Total Jobs: ${status.totalJobs}`);
    console.log(`▶️  Running Jobs: ${status.runningJobs}`);
    console.log(`🌍 Timezone: ${status.timezone}`);
    console.log(`🕐 Current Time (UTC): ${status.currentTime}`);
    console.log(`🕐 Current Time (Local): ${status.currentTimeLocal}`);
    console.log(`📦 Node Environment: ${status.nodeEnv}`);
    console.log(`⏱️  Uptime: ${Math.round(status.uptime)} seconds`);
    
    // Check environment variables
    console.log('\n3. Environment Variables:');
    console.log(`🔑 JWT Token Set: ${status.environment.JWT_TOKEN_SET ? '✅ Yes' : '❌ No'}`);
    console.log(`🌍 TZ: ${status.environment.TZ || 'Not set'}`);
    console.log(`📦 NODE_ENV: ${status.environment.NODE_ENV || 'Not set'}`);
    
    // Check individual jobs
    console.log('\n4. Registered Jobs:');
    status.jobNames.forEach((jobName, index) => {
      console.log(`   ${index + 1}. ${jobName}`);
    });
    
    // Check jobs endpoint
    console.log('\n5. Job Details:');
    const jobsResponse = await axios.get(`${appUrl}/jobs`, { timeout: 10000 });
    const jobs = jobsResponse.data;
    
    console.log(`📋 Total Jobs: ${jobs.totalJobs}`);
    jobs.jobs.forEach((job, index) => {
      console.log(`   ${index + 1}. ${job.name} - ${job.isRunning ? '✅ Running' : '❌ Not Running'}`);
    });
    
    console.log('\n✅ Heroku deployment is working correctly!');
    console.log('\n📋 Next Steps:');
    console.log('1. Monitor logs: heroku logs --tail --app your-app-name');
    console.log('2. Watch for job execution at scheduled times');
    console.log('3. Afternoon job: 1:01 PM CST (Monday-Friday)');
    console.log('4. Evening jobs: 6:30 PM CST and 6:35 PM CST (Monday-Friday)');
    
  } catch (error) {
    console.error('❌ Error checking Heroku status:');
    if (error.response) {
      console.error(`📊 Status Code: ${error.response.status}`);
      console.error(`📄 Response:`, JSON.stringify(error.response.data, null, 2));
    } else if (error.request) {
      console.error('🌐 Network Error:', error.message);
      console.error('💡 Make sure to replace "your-app.herokuapp.com" with your actual Heroku app URL');
    } else {
      console.error('💥 Error:', error.message);
    }
  }
}

checkHerokuStatus();
