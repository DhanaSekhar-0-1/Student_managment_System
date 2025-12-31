// test-com4.js - Buffered NFC Reader
const { SerialPort } = require('serialport');

console.log('🧪 Testing COM4 with Buffering...');
console.log('📋 Target: 10-character alphanumeric NFC ID\n');

const port = new SerialPort({ 
  path: 'COM4', 
  baudRate: 9600,
  autoOpen: false
});

let buffer = '';
let lastNfcId = null;
let timeout = null;

port.open((err) => {
  if (err) {
    console.error('❌ Failed to open COM4:', err.message);
    process.exit(1);
  }
  
  console.log('✅ COM4 Opened Successfully');
  console.log('📡 Waiting for NFC card... (Scan now)\n');
});

port.on('data', (data) => {
  const chunk = data.toString();
  buffer += chunk;
  
  // Clear existing timeout
  if (timeout) {
    clearTimeout(timeout);
  }
  
  // Set new timeout - process buffer after 100ms of no new data
  timeout = setTimeout(() => {
    processBuffer();
  }, 100);
});

function processBuffer() {
  // Remove all whitespace and newlines
  const cleaned = buffer.replace(/[\r\n\s]/g, '');
  
  if (cleaned.length === 0) {
    buffer = '';
    return;
  }
  
  console.log('─────────────────────────────────────');
  console.log('📥 BUFFERED DATA:', cleaned);
  console.log('📏 LENGTH:', cleaned.length);
  
  // Take first 10 characters
  const nfcId = cleaned.substring(0, 10);
  console.log('✂️ FIRST 10 CHARS:', nfcId);
  
  // Validate: alphanumeric only
  const isAlphanumeric = /^[A-Za-z0-9]+$/.test(nfcId);
  console.log('✓ Alphanumeric:', isAlphanumeric ? 'YES ✅' : 'NO ❌');
  
  // Validate: exactly 10 characters
  const isValidLength = nfcId.length === 10;
  console.log('✓ Length = 10:', isValidLength ? 'YES ✅' : 'NO ❌');
  
  // Check if it's a duplicate
  const isDuplicate = nfcId === lastNfcId;
  console.log('✓ New ID:', isDuplicate ? 'NO (duplicate) ⚠️' : 'YES ✅');
  
  if (isAlphanumeric && isValidLength && !isDuplicate) {
    console.log('');
    console.log('🎯🎯🎯 ACCEPTED NFC ID: ' + nfcId + ' 🎯🎯🎯');
    console.log('');
    lastNfcId = nfcId;
  } else {
    if (isDuplicate) {
      console.log('');
      console.log('⏭️ SKIPPED - Duplicate of previous scan');
      console.log('');
    } else {
      console.log('');
      console.log('❌ REJECTED - Validation failed');
      console.log('');
    }
  }
  
  console.log('─────────────────────────────────────\n');
  
  // Clear buffer
  buffer = '';
}

port.on('error', (err) => {
  console.error('❌ Error:', err.message);
});

process.on('SIGINT', () => {
  console.log('\n\n🛑 Stopping...');
  if (timeout) clearTimeout(timeout);
  port.close();
  process.exit();
});