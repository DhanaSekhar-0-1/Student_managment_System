// src/controllers/student.controller.js
const service = require("../services/student.service");

/**
 * Get all students with filters
 */
exports.getStudents = async (req, res) => {
  try {
    const filters = {
      page: req.query.page,
      limit: req.query.limit,
      college_name: req.query.college_name,
      is_active: req.query.is_active,
      search: req.query.search
    };

    const result = await service.getStudents(filters);

    res.status(200).json({
      success: true,
      data: {
        students: result.students,
        pagination: result.pagination
      },
      message: "Students fetched successfully"
    });
  } catch (err) {
    console.error("Get Students Error:", err);
    res.status(500).json({
      success: false,
      message: "Failed to fetch students",
      error: err.message
    });
  }
};

/**
 * Get single student by ID_No
 */
exports.getStudentById = async (req, res) => {
  try {
    const idNo = req.params.id;
    const student = await service.getStudentById(idNo);

    res.status(200).json({
      success: true,
      data: { student },
      message: "Student fetched successfully"
    });
  } catch (err) {
    console.error("Get Student Error:", err);
    
    if (err.message === "Student not found") {
      return res.status(404).json({
        success: false,
        message: err.message
      });
    }

    res.status(500).json({
      success: false,
      message: "Failed to fetch student",
      error: err.message
    });
  }
};

/**
 * Get student by NFC ID
 */
exports.getStudentByNfcId = async (req, res) => {
  try {
    const nfcId = req.params.nfc_id;
    
    // Validate NFC ID format
    if (nfcId.length !== 10) {
      return res.status(400).json({
        success: false,
        message: "Invalid NFC ID format. Must be 10 characters."
      });
    }

    const student = await service.getStudentByNfcId(nfcId);

    res.status(200).json({
      success: true,
      data: { student },
      message: "Student fetched successfully"
    });
  } catch (err) {
    console.error("Get Student by NFC Error:", err);
    
    if (err.message.includes("not found")) {
      return res.status(404).json({
        success: false,
        message: err.message
      });
    }

    res.status(500).json({
      success: false,
      message: "Failed to fetch student",
      error: err.message
    });
  }
};

/**
 * Get all colleges
 */
exports.getColleges = async (req, res) => {
  try {
    const colleges = await service.getColleges();

    res.status(200).json({
      success: true,
      data: { colleges },
      message: "Colleges fetched successfully"
    });
  } catch (err) {
    console.error("Get Colleges Error:", err);
    res.status(500).json({
      success: false,
      message: "Failed to fetch colleges",
      error: err.message
    });
  }
};

/**
 * Create new student
 */
exports.createStudent = async (req, res) => {
  try {
    const studentData = req.body;

    // Validation - NOW INCLUDING ID_No and mobile fields as REQUIRED
    if (!studentData.ID_No || !studentData.student_name || !studentData.pin_no || 
        !studentData.nfc_id || !studentData.college_name || 
        !studentData.student_mobile || !studentData.parent_mobile) {
      return res.status(400).json({
        success: false,
        message: "Missing required fields: ID_No, student_name, pin_no, nfc_id, college_name, student_mobile, parent_mobile"
      });
    }

    // Validate NFC ID format
    if (studentData.nfc_id.length !== 10) {
      return res.status(400).json({
        success: false,
        message: "Invalid NFC ID format. Must be exactly 10 characters."
      });
    }

    // Validate NFC ID is alphanumeric
    if (!/^[A-Za-z0-9]{10}$/.test(studentData.nfc_id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid NFC ID format. Must be alphanumeric (A-Z, a-z, 0-9) only."
      });
    }

    // Validate mobile numbers (must be 10 digits)
    if (!/^[0-9]{10}$/.test(studentData.student_mobile)) {
      return res.status(400).json({
        success: false,
        message: "Invalid student mobile number. Must be exactly 10 digits."
      });
    }

    if (!/^[0-9]{10}$/.test(studentData.parent_mobile)) {
      return res.status(400).json({
        success: false,
        message: "Invalid parent mobile number. Must be exactly 10 digits."
      });
    }

    const student = await service.createStudent(studentData);

    res.status(201).json({
      success: true,
      data: { student },
      message: "Student created successfully"
    });
  } catch (err) {
    console.error("Create Student Error:", err);
    
    if (err.message.includes("already exists") || err.message.includes("already registered")) {
      return res.status(409).json({
        success: false,
        message: err.message
      });
    }

    if (err.message.includes("Invalid NFC ID")) {
      return res.status(400).json({
        success: false,
        message: err.message
      });
    }

    res.status(500).json({
      success: false,
      message: "Failed to create student",
      error: err.message
    });
  }
};

/**
 * Update student
 */
exports.updateStudent = async (req, res) => {
  try {
    const idNo = req.params.id;
    const updateData = req.body;

    // Validate mobile numbers if provided (10 digits exactly)
    if (updateData.student_mobile && !/^[0-9]{10}$/.test(updateData.student_mobile)) {
      return res.status(400).json({
        success: false,
        message: "Invalid student mobile number. Must be exactly 10 digits."
      });
    }

    if (updateData.parent_mobile && !/^[0-9]{10}$/.test(updateData.parent_mobile)) {
      return res.status(400).json({
        success: false,
        message: "Invalid parent mobile number. Must be exactly 10 digits."
      });
    }

    const student = await service.updateStudent(idNo, updateData);

    res.status(200).json({
      success: true,
      data: { student },
      message: "Student updated successfully"
    });
  } catch (err) {
    console.error("Update Student Error:", err);
    
    if (err.message === "Student not found") {
      return res.status(404).json({
        success: false,
        message: err.message
      });
    }

    if (err.message === "No valid fields to update") {
      return res.status(400).json({
        success: false,
        message: err.message
      });
    }

    res.status(500).json({
      success: false,
      message: "Failed to update student",
      error: err.message
    });
  }
};

/**
 * Deactivate student
 */
exports.deactivateStudent = async (req, res) => {
  try {
    const idNo = req.params.id;
    const student = await service.deactivateStudent(idNo);

    res.status(200).json({
      success: true,
      data: { student },
      message: "Student deactivated successfully"
    });
  } catch (err) {
    console.error("Deactivate Student Error:", err);
    
    if (err.message === "Student not found") {
      return res.status(404).json({
        success: false,
        message: err.message
      });
    }

    res.status(500).json({
      success: false,
      message: "Failed to deactivate student",
      error: err.message
    });
  }
};

/**
 * Activate student
 */
exports.activateStudent = async (req, res) => {
  try {
    const idNo = req.params.id;
    const student = await service.activateStudent(idNo);

    res.status(200).json({
      success: true,
      data: { student },
      message: "Student activated successfully"
    });
  } catch (err) {
    console.error("Activate Student Error:", err);
    
    if (err.message === "Student not found") {
      return res.status(404).json({
        success: false,
        message: err.message
      });
    }

    res.status(500).json({
      success: false,
      message: "Failed to activate student",
      error: err.message
    });
  }
};