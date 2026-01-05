require("dotenv").config();
const app = require("./app");

const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0'; // Listen on all network interfaces

app.listen(PORT, HOST, () => {
  console.log(`✅ Server running on port ${PORT}`);
  console.log(`📍 Local: http://localhost:${PORT}`);
  console.log(`🌐 Network: http://192.168.1.11:${PORT}`);
  console.log(`📚 API Docs: http://192.168.1.11:${PORT}/api-docs`);
});