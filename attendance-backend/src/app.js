require("dotenv").config();
const express = require("express");
const cors = require("cors");
const swaggerUi = require("swagger-ui-express");
const swaggerJsdoc = require("swagger-jsdoc");

const app = express();

// ============================================
// CORS Configuration - MUST BE FIRST
// ============================================
app.use(cors({
  origin: '*',
  credentials: false,
  methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
}));

// Handle preflight requests
app.options('*', cors());

// ============================================
// Middleware
// ============================================
app.use(express.json());

// ============================================
// Swagger Configuration
// ============================================
const swaggerOptions = {
  definition: {
    openapi: "3.0.0",
    info: {
      title: "Institute Attendance Management API",
      version: "1.0.0",
      description: "NFC-based attendance system with student management and analytics",
    },
    servers: [
      {
        url: "http://localhost:3000",
        description: "Development server",
      },
    ],
    tags: [
      {
        name: "Students",
        description: "Student management endpoints",
      },
      {
        name: "Attendance",
        description: "Attendance marking and retrieval",
      },
      {
        name: "Reports",
        description: "Student and college attendance reports",
      },
	  {
        name: "Student Registration",
        description: "Student Data Collection ",
      },
    ],
  },
  apis: ["./src/routes/*.js"],
};

const swaggerSpec = swaggerJsdoc(swaggerOptions);
app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// ============================================
// Import Routes
// ============================================
const attendanceRoutes = require("./routes/attendance.routes");
const studentRoutes = require("./routes/student.routes");
const reportRoutes = require("./routes/report.routes");
const regstdRoutes = require("./routes/regstd.routes");



// ============================================
// Register Routes
// ============================================
app.use("/api/attendance", attendanceRoutes);
app.use("/api/students", studentRoutes);
app.use("/api/reports", reportRoutes);
app.use("/api/regstd", regstdRoutes);

// ============================================
// Health Check
// ============================================
app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "Attendance API running",
    version: "1.0.0",
    swagger: "http://localhost:3000/api-docs",
    endpoints: {
      students: "/api/students",
      attendance: "/api/attendance",
      reports: "/api/reports",
    },
  });
});

// ============================================
// 404 Handler
// ============================================
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: "Route not found",
    path: req.path,
    method: req.method,
  });
});

// ============================================
// Error Handler
// ============================================
app.use((err, req, res, next) => {
  console.error("Server Error:", err);
  res.status(500).json({
    success: false,
    message: "Internal server error",
    error: process.env.NODE_ENV === "development" ? err.message : undefined,
  });
});

module.exports = app;