// src/utils/scheduler.js
const cron = require('node-cron');
const attendanceService = require('../services/attendance.service');

/**
 * Schedule auto-absent marking at 10:05 AM every day
 * Runs Mon-Sat (1-6), skips Sunday (0)
 */
function startScheduler() {
  // Run at 10:05 AM every day (5 minutes after cutoff)
  cron.schedule('5 10 * * 1-6', async () => {
    console.log('🕒 Running auto-absent scheduler at', new Date().toISOString());
    
    try {
      const result = await attendanceService.autoMarkAbsent();
      console.log('✅ Auto-absent completed:', result);
    } catch (error) {
      console.error('❌ Auto-absent failed:', error);
    }
  }, {
    timezone: "Asia/Kolkata" // Set your timezone
  });

  console.log('📅 Attendance scheduler started - Auto-absent at 10:05 AM Mon-Sat');
}

module.exports = { startScheduler };