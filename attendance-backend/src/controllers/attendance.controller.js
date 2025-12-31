// src/controllers/attendance.controller.js
const service = require("../services/attendance.service");

/**
 * Mark attendance using NFC
 */
exports.markAttendance = async (req, res) => {
  try {
    const { nfc_id, device_id } = req.body;

    if (!nfc_id) {
      return res.status(400).json({ 
        success: false,
        message: "Missing NFC ID" 
      });
    }

    // Validate NFC ID format (10 characters)
    if (nfc_id.length !== 10) {
      return res.status(400).json({ 
        success: false,
        message: "Invalid NFC ID format. Must be 10 characters." 
      });
    }

    const result = await service.markAttendance(nfc_id, device_id);
    
    res.status(200).json({
      success: true,
      data: result,
      message: result.message
    });

  } catch (err) {
    console.error("Attendance Error:", err);
    
    // Handle specific errors
    if (err.message.includes("Invalid or inactive")) {
      return res.status(404).json({ 
        success: false,
        message: "Student not found or inactive" 
      });
    }
    
    if (err.message.includes("already marked")) {
      return res.status(409).json({ 
        success: false,
        message: err.message 
      });
    }

    if (err.message.includes("Sunday") || err.message.includes("Holiday")) {
      return res.status(400).json({ 
        success: false,
        message: err.message 
      });
    }

    // Generic error
    res.status(500).json({ 
      success: false,
      message: "Failed to mark attendance",
      error: err.message 
    });
  }
};

/**
 * Get today's attendance
 */
exports.getTodayAttendance = async (req, res) => {
  try {
    const filters = {
      college_name: req.query.college_name,
      status: req.query.status
    };
    
    const result = await service.getTodayAttendance(filters);
    
    res.status(200).json({
      success: true,
      data: result,
      message: "Today's attendance fetched successfully"
    });
  } catch (err) {
    console.error("Get Today Attendance Error:", err);
    res.status(500).json({
      success: false,
      message: "Failed to fetch today's attendance",
      error: err.message
    });
  }
};

/**
 * Get student attendance history
 */
exports.getStudentAttendance = async (req, res) => {
  try {
    const studentIdNo = req.params.student_id_no;
    const filters = {
      start_date: req.query.start_date,
      end_date: req.query.end_date,
      month: req.query.month,
      year: req.query.year,
      page: req.query.page,
      limit: req.query.limit
    };
    
    const result = await service.getStudentAttendance(studentIdNo, filters);
    
    res.status(200).json({
      success: true,
      data: result,
      message: "Student attendance fetched successfully"
    });
  } catch (err) {
    console.error("Get Student Attendance Error:", err);
    
    if (err.message === "Student not found") {
      return res.status(404).json({
        success: false,
        message: err.message
      });
    }
    
    res.status(500).json({
      success: false,
      message: "Failed to fetch student attendance",
      error: err.message
    });
  }
};

/**
 * Get attendance by date range
 */
exports.getAttendanceByDateRange = async (req, res) => {
  try {
    const { start_date, end_date } = req.query;
    
    if (!start_date || !end_date) {
      return res.status(400).json({
        success: false,
        message: "start_date and end_date are required"
      });
    }
    
    const filters = {
      college_name: req.query.college_name,
      student_id_no: req.query.student_id_no
    };
    
    const result = await service.getAttendanceByDateRange(start_date, end_date, filters);
    
    res.status(200).json({
      success: true,
      data: result,
      message: "Attendance fetched successfully"
    });
  } catch (err) {
    console.error("Get Attendance By Date Range Error:", err);
    res.status(500).json({
      success: false,
      message: "Failed to fetch attendance",
      error: err.message
    });
  }
};

/**
 * Update attendance record
 */
exports.updateAttendance = async (req, res) => {
  try {
    const attendanceId = req.params.id;
    const updateData = req.body;
    
    const result = await service.updateAttendance(attendanceId, updateData);
    
    res.status(200).json({
      success: true,
      data: { attendance: result },
      message: "Attendance updated successfully"
    });
  } catch (err) {
    console.error("Update Attendance Error:", err);
    
    if (err.message === "Attendance record not found") {
      return res.status(404).json({
        success: false,
        message: err.message
      });
    }
    
    if (err.message === "No valid fields to update" || err.message.includes("Invalid status")) {
      return res.status(400).json({
        success: false,
        message: err.message
      });
    }
    
    res.status(500).json({
      success: false,
      message: "Failed to update attendance",
      error: err.message
    });
  }
};

/**
 * Auto-mark absent for unmarked students (should be called after 10 AM)
 */
exports.autoMarkAbsent = async (req, res) => {
  try {
    const result = await service.autoMarkAbsent();
    
    res.status(200).json({
      success: true,
      data: result,
      message: result.message
    });
  } catch (err) {
    console.error("Auto Mark Absent Error:", err);
    res.status(500).json({
      success: false,
      message: "Failed to auto-mark absent",
      error: err.message
    });
  }
};