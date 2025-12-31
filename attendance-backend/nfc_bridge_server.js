// nfc_bridge_server.js
const express = require('express');
const { SerialPort } = require('serialport');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

app.use(cors());
app.use(express.json());

let serialPort = null;
let lastNfcId = null;
let isConnected = false;
let buffer = '';
let timeout = null;

// ✅ Auto-clear NFC_ID after 5 seconds
let clearTimer = null;
const CLEAR_DELAY = 5000; // 5 seconds

// Get available ports
app.get('/api/serial/ports', async (req, res) => {
  try {
    const ports = await SerialPort.list();
    const portList = ports.map(port => ({
      path: port.path,
      manufacturer: port.manufacturer,
      serialNumber: port.serialNumber,
      pnpId: port.pnpId,
      locationId: port.locationId,
      vendorId: port.vendorId,
      productId: port.productId
    }));
    console.log('📋 Available ports:', portList.map(p => p.path).join(', '));
    res.json({ success: true, ports: portList });
  } catch (error) {
    console.error('❌ Error listing ports:', error.message);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ✅ Clear NFC_ID after 5 seconds
function clearNfcId() {
  console.log('');
  console.log('═════════════════════════════════════');
  console.log('🔄 AUTO-CLEARING NFC_ID AFTER 5 SECONDS');
  console.log('═════════════════════════════════════');
  
  const oldNfcId = lastNfcId;
  lastNfcId = null;
  clearTimer = null;
  
  console.log('🗑️ Cleared NFC_ID:', oldNfcId);
  console.log('✅ Ready for next card');
  console.log('═════════════════════════════════════');
  console.log('');
  
  // ✅ Broadcast clear signal to all WebSocket clients
  io.emit('nfc-cleared', { 
    clearedId: oldNfcId, 
    timestamp: new Date() 
  });
}

// Process buffered data
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
    console.log('🎯 ACCEPTED NFC ID: ' + nfcId);
    console.log('📤 Broadcasting to', io.sockets.sockets.size, 'clients');
    console.log('');
    
    lastNfcId = nfcId;
    
    // Broadcast to all WebSocket clients
    io.emit('nfc-data', { nfcId: nfcId, timestamp: new Date() });
    
    // ✅ Cancel previous clear timer if exists
    if (clearTimer) {
      clearTimeout(clearTimer);
      console.log('⏱️ Previous clear timer cancelled');
    }
    
    // ✅ Start new clear timer (5 seconds)
    clearTimer = setTimeout(() => {
      clearNfcId();
    }, CLEAR_DELAY);
    console.log('⏱️ Clear timer started (5 seconds)');
  } else {
    if (isDuplicate) {
      console.log('⏭️ SKIPPED - Duplicate');
    } else {
      console.log('❌ REJECTED - Validation failed');
    }
    console.log('');
  }
  
  console.log('─────────────────────────────────────\n');
  
  // Clear buffer
  buffer = '';
}

// Connect to serial port
app.post('/api/serial/connect', (req, res) => {
  const { port, baudRate = 9600 } = req.body;

  console.log('🔌 Connection request:', { port, baudRate });

  if (!port) {
    return res.status(400).json({ success: false, error: 'Port is required' });
  }

  // Close existing connection if any
  if (serialPort && serialPort.isOpen) {
    console.log('⚠️ Closing existing connection');
    serialPort.close();
  }

  try {
    serialPort = new SerialPort({
      path: port,
      baudRate: baudRate,
      autoOpen: false
    });

    serialPort.open((err) => {
      if (err) {
        console.error('❌ Failed to open port:', err.message);
        return res.status(500).json({ success: false, error: err.message });
      }

      console.log(`✅ Connected to ${port} at ${baudRate} baud`);
      isConnected = true;
      io.emit('status', { connected: true, port: port });
      res.json({ success: true, message: `Connected to ${port}` });
    });

    // Handle incoming data with buffering
    serialPort.on('data', (data) => {
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

    serialPort.on('error', (err) => {
      console.error('❌ Serial port error:', err.message);
      isConnected = false;
      io.emit('status', { connected: false, error: err.message });
    });

    serialPort.on('close', () => {
      console.log('🔒 Serial port closed');
      isConnected = false;
      buffer = '';
      if (timeout) clearTimeout(timeout);
      if (clearTimer) clearTimeout(clearTimer); // ✅ Cancel clear timer
      io.emit('status', { connected: false });
    });

  } catch (error) {
    console.error('❌ Connection error:', error.message);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Disconnect from serial port
app.post('/api/serial/disconnect', (req, res) => {
  console.log('🔌 Disconnect request');
  
  if (serialPort && serialPort.isOpen) {
    serialPort.close((err) => {
      if (err) {
        console.error('❌ Disconnect error:', err.message);
        return res.status(500).json({ success: false, error: err.message });
      }
      isConnected = false;
      lastNfcId = null;
      buffer = '';
      if (timeout) clearTimeout(timeout);
      if (clearTimer) clearTimeout(clearTimer); // ✅ Cancel clear timer
      console.log('✅ Disconnected successfully');
      io.emit('status', { connected: false });
      res.json({ success: true, message: 'Disconnected' });
    });
  } else {
    console.log('⚠️ Already disconnected');
    res.json({ success: true, message: 'Already disconnected' });
  }
});

// Get connection status
app.get('/api/serial/status', (req, res) => {
  const status = {
    success: true,
    connected: isConnected,
    lastNfcId: lastNfcId,
    port: serialPort ? serialPort.path : null,
    isOpen: serialPort ? serialPort.isOpen : false
  };
  res.json(status);
});

// Get last NFC ID
app.get('/api/serial/last-nfc', (req, res) => {
  res.json({
    success: true,
    nfcId: lastNfcId,
    timestamp: new Date()
  });
});

// WebSocket connection
io.on('connection', (socket) => {
  console.log('🔌 Client connected:', socket.id);
  console.log('👥 Total clients:', io.sockets.sockets.size);
  
  // Send current status to new client
  socket.emit('status', {
    connected: isConnected,
    port: serialPort ? serialPort.path : null,
    lastNfcId: lastNfcId
  });

  socket.on('disconnect', () => {
    console.log('🔌 Client disconnected:', socket.id);
    console.log('👥 Total clients:', io.sockets.sockets.size);
  });
});

const PORT = 3001;
server.listen(PORT, () => {
  console.log('');
  console.log('═══════════════════════════════════════════');
  console.log('🚀 NFC Bridge Server STARTED');
  console.log('═══════════════════════════════════════════');
  console.log(`📡 HTTP API: http://localhost:${PORT}`);
  console.log(`🔌 WebSocket: ws://localhost:${PORT}`);
  console.log(`📏 NFC ID Length: 10 characters`);
  console.log('═══════════════════════════════════════════');
  console.log('');
  console.log('Ready to accept connections...');
  console.log('');
});