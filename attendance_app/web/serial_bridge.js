// web/serial_bridge.js
class SerialBridge {
  constructor() {
    this.port = null;
    this.reader = null;
    this.writer = null;
    this.onDataCallback = null;
    
    // ✅ Auto-clear NFC_ID after 5 seconds
    this.lastNfcId = null;
    this.clearTimer = null;
    this.CLEAR_DELAY = 5000; // 5 seconds
  }

  // Check if Web Serial API is supported
  isSupported() {
    return 'serial' in navigator;
  }

  // Request port from user
  async requestPort() {
    try {
      this.port = await navigator.serial.requestPort();
      return true;
    } catch (error) {
      console.error('Error requesting port:', error);
      return false;
    }
  }

  // Get available ports (previously authorized)
  async getPorts() {
    try {
      const ports = await navigator.serial.getPorts();
      return ports;
    } catch (error) {
      console.error('Error getting ports:', error);
      return [];
    }
  }

  // Connect to port
  async connect(baudRate = 9600) {
    try {
      if (!this.port) {
        throw new Error('No port selected');
      }

      await this.port.open({ baudRate: baudRate });

      // Setup reader
      const decoder = new TextDecoderStream();
      this.port.readable.pipeTo(decoder.writable);
      this.reader = decoder.readable.getReader();

      // Start reading
      this.startReading();

      return true;
    } catch (error) {
      console.error('Error connecting:', error);
      return false;
    }
  }

  // Start reading data
  async startReading() {
    try {
      while (true) {
        const { value, done } = await this.reader.read();
        if (done) {
          break;
        }
        
        // Call Dart callback with data
        if (this.onDataCallback && value) {
          const lines = value.split('\n');
          lines.forEach(line => {
            const trimmed = line.trim();
            if (trimmed) {
              // ✅ Check if this is a new NFC_ID
              if (trimmed.length === 10 && /^[A-Za-z0-9]+$/.test(trimmed)) {
                // New NFC_ID detected
                
                // ✅ Cancel previous timer if exists
                if (this.clearTimer) {
                  clearTimeout(this.clearTimer);
                  console.log('⏱️ Previous clear timer cancelled');
                }
                
                // ✅ Only send if different from last ID
                if (trimmed !== this.lastNfcId) {
                  console.log('🎯 New NFC_ID:', trimmed);
                  this.lastNfcId = trimmed;
                  this.onDataCallback(trimmed);
                  
                  // ✅ Start new clear timer (5 seconds)
                  this.clearTimer = setTimeout(() => {
                    this.clearNfcId();
                  }, this.CLEAR_DELAY);
                  console.log('⏱️ Clear timer started (5 seconds)');
                } else {
                  console.log('⏭️ Duplicate NFC_ID, skipped:', trimmed);
                }
              } else {
                // Not an NFC_ID, pass through normally
                this.onDataCallback(trimmed);
              }
            }
          });
        }
      }
    } catch (error) {
      console.error('Error reading:', error);
    }
  }

  // ✅ Clear NFC_ID and notify Flutter
  clearNfcId() {
    console.log('🔄 SerialBridge: Clearing NFC_ID after 5 seconds');
    
    const oldNfcId = this.lastNfcId;
    this.lastNfcId = null;
    this.clearTimer = null;
    
    console.log('🗑️ Cleared NFC_ID:', oldNfcId);
    console.log('✅ Ready for next card');
    
    // ✅ Notify Flutter to clear the field
    if (this.onDataCallback) {
      this.onDataCallback('NFC_CLEARED');
    }
  }

  // Disconnect from port
  async disconnect() {
    try {
      // ✅ Cancel clear timer if active
      if (this.clearTimer) {
        clearTimeout(this.clearTimer);
        this.clearTimer = null;
        console.log('⏱️ Clear timer cancelled on disconnect');
      }
      
      if (this.reader) {
        await this.reader.cancel();
        this.reader = null;
      }
      
      if (this.port) {
        await this.port.close();
        this.port = null;
      }
      
      // ✅ Reset NFC_ID
      this.lastNfcId = null;
      
      return true;
    } catch (error) {
      console.error('Error disconnecting:', error);
      return false;
    }
  }

  // Set data callback for Flutter
  setDataCallback(callback) {
    this.onDataCallback = callback;
  }
}

// Make it globally available
window.serialBridge = new SerialBridge();