// src/controllers/report.controller.js
const service = require("../services/report.service");

/**
 * Get monthly report for a student
 */
exports.getMonthlyReport = async (req, res) => {
  try {
    const studentIdNo = req.params.student_id_no;
    const { year, month } = req.query;
    
    if (!year || !month) {
      return res.status(400).json({
        success: false,
        message: "year and month are required query parameters"
      });
    }
    
    const result = await service.getMonthlyReport(studentIdNo, year, month);
    
    res.status(200).json({
      success: true,
      data: result,
      message: "Monthly report generated successfully"
    });
  } catch (err) {
    console.error("Get Monthly Report Error:", err);
    
    if (err.message === "Student not found") {
      return res.status(404).json({
        success: false,
        message: err.message
      });
    }
    
    res.status(500).json({
      success: false,
      message: "Failed to generate monthly report",
      error: err.message
    });
  }
};

/**
 * Get overall report for a student
 */
exports.getOverallReport = async (req, res) => {
  try {
    const studentIdNo = req.params.student_id_no;
    
    const result = await service.getOverallReport(studentIdNo);
    
    res.status(200).json({
      success: true,
      data: result,
      message: "Overall report generated successfully"
    });
  } catch (err) {
    console.error("Get Overall Report Error:", err);
    
    if (err.message === "Student not found") {
      return res.status(404).json({
        success: false,
        message: err.message
      });
    }
    
    res.status(500).json({
      success: false,
      message: "Failed to generate overall report",
      error: err.message
    });
  }
};

/**
 * Get overall monthly report for all students
 * Supports optional college_name filter
 */
exports.getOverallMonthlyReport = async (req, res) => {
  try {
    const { year, month } = req.query;
    
    if (!year || !month) {
      return res.status(400).json({
        success: false,
        message: "Year and month are required query parameters"
      });
    }

    const filters = {
      college_name: req.query.college_name
    };

    const report = await service.getOverallMonthlyReport(
      parseInt(year),
      parseInt(month),
      filters
    );

    res.status(200).json({
      success: true,
      data: report,
      message: "Overall monthly report fetched successfully"
    });
  } catch (err) {
    console.error("Get Overall Monthly Report Error:", err);
    
    if (err.message.includes("required") || err.message.includes("Invalid")) {
      return res.status(400).json({
        success: false,
        message: err.message
      });
    }

    res.status(500).json({
      success: false,
      message: "Failed to fetch overall monthly report",
      error: err.message
    });
  }
};