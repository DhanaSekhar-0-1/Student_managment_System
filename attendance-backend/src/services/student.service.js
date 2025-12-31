// src/services/student.service.js
const db = require("../config/db");

/**
 * Get all students with filters and pagination
 */
exports.getStudents = async (filters = {}) => {
  const {
    page = 1,
    limit = 20,
    college_name,
    is_active,
    search
  } = filters;

  const offset = (page - 1) * limit;

  let whereConditions = [];
  let params = [];

  if (college_name) {
    whereConditions.push("college_name = ?");
    params.push(college_name);
  }

  if (is_active !== undefined) {
    whereConditions.push("is_active = ?");
    params.push(is_active);
  }

  if (search) {
    whereConditions.push("(student_name LIKE ? OR pin_no LIKE ? OR ID_No LIKE ?)");
    params.push(`%${search}%`, `%${search}%`, `%${search}%`);
  }

  const whereClause = whereConditions.length
    ? `WHERE ${whereConditions.join(" AND ")}`
    : "";

  const [countResult] = await db.query(
    `SELECT COUNT(*) as total FROM students ${whereClause}`,
    params
  );

  const totalRecords = countResult[0].total;

  const [students] = await db.query(
    `SELECT 
      S_No, student_name, pin_no, nfc_id, ID_No,
      college_name, student_mobile, parent_mobile,
      fees_paid, is_active, created_at
     FROM students
     ${whereClause}
     ORDER BY created_at DESC
     LIMIT ? OFFSET ?`,
    [...params, parseInt(limit), parseInt(offset)]
  );

  return {
    students,
    pagination: {
      currentPage: parseInt(page),
      totalPages: Math.ceil(totalRecords / limit),
      totalRecords,
      limit: parseInt(limit),
      hasNextPage: page * limit < totalRecords,
      hasPrevPage: page > 1
    }
  };
};

/**
 * Get student by ID_No
 */
exports.getStudentById = async (idNo) => {
  const [students] = await db.query(
    `SELECT 
      S_No, student_name, pin_no, nfc_id, ID_No,
      college_name, student_mobile, parent_mobile,
      fees_paid, is_active, created_at
     FROM students
     WHERE ID_No = ?`,
    [idNo]
  );

  if (students.length === 0) {
    throw new Error("Student not found");
  }

  return students[0];
};

/**
 * Get student by NFC ID
 */
exports.getStudentByNfcId = async (nfcId) => {
  if (nfcId && nfcId.length !== 10) {
    throw new Error("NFC ID must be 10 characters");
  }

  const [students] = await db.query(
    `SELECT 
      S_No, student_name, pin_no, nfc_id, ID_No,
      college_name, student_mobile, parent_mobile,
      fees_paid, is_active, created_at
     FROM students
     WHERE nfc_id = ?`,
    [nfcId]
  );

  if (students.length === 0) {
    throw new Error("Student not found with this NFC ID");
  }

  return students[0];
};

/**
 * Get colleges summary
 */
exports.getColleges = async () => {
  const [colleges] = await db.query(
    `SELECT 
      college_name,
      COUNT(*) AS total_students,
      SUM(is_active = 1) AS active_students,
      SUM(is_active = 0) AS inactive_students
     FROM students
     WHERE college_name IS NOT NULL
     GROUP BY college_name
     ORDER BY college_name`
  );

  return colleges;
};

/**
 * Create new student
 */
exports.createStudent = async (studentData) => {
  const {
    ID_No,
    student_name,
    pin_no,
    nfc_id,
    college_name,
    student_mobile,
    parent_mobile,
    fees_paid = 0.00,
    is_active = 1
  } = studentData;

  if (!ID_No || !student_name || !pin_no || !nfc_id || !student_mobile || !parent_mobile) {
    throw new Error("Missing required fields");
  }

  // ✅ NFC ID validation (UPDATED)
  if (nfc_id.length !== 10) {
    throw new Error("NFC ID must be 10 characters");
  }

  const [[idExists]] = await db.query(
    "SELECT ID_No FROM students WHERE ID_No = ?",
    [ID_No]
  );
  if (idExists) {
    throw new Error("Student with this ID number already exists");
  }

  const [[pinExists]] = await db.query(
    "SELECT ID_No FROM students WHERE pin_no = ?",
    [pin_no]
  );
  if (pinExists) {
    throw new Error("Student with this PIN number already exists");
  }

  const [[nfcExists]] = await db.query(
    "SELECT ID_No FROM students WHERE nfc_id = ?",
    [nfc_id]
  );
  if (nfcExists) {
    throw new Error("This NFC card is already registered");
  }

  try {
    await db.query(
      `INSERT INTO students
      (ID_No, student_name, pin_no, nfc_id, college_name,
       student_mobile, parent_mobile, fees_paid, is_active)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        ID_No,
        student_name,
        pin_no,
        nfc_id,
        college_name,
        student_mobile,
        parent_mobile,
        fees_paid,
        is_active
      ]
    );

    return await this.getStudentById(ID_No);
  } catch (error) {
    if (error.sqlMessage && error.sqlMessage.includes("Invalid NFC ID")) {
      throw new Error("Invalid NFC ID: must be 10-character alphanumeric");
    }
    throw error;
  }
};

/**
 * Update student
 */
exports.updateStudent = async (idNo, updateData) => {
  const [[existing]] = await db.query(
    "SELECT ID_No FROM students WHERE ID_No = ?",
    [idNo]
  );

  if (!existing) {
    throw new Error("Student not found");
  }

  const allowedFields = [
    "student_name",
    "student_mobile",
    "parent_mobile",
    "fees_paid",
    "is_active",
    "college_name"
  ];

  const updates = [];
  const values = [];

  for (const [key, value] of Object.entries(updateData)) {
    if (allowedFields.includes(key)) {
      updates.push(`${key} = ?`);
      values.push(value);
    }
  }

  if (!updates.length) {
    throw new Error("No valid fields to update");
  }

  values.push(idNo);

  await db.query(
    `UPDATE students SET ${updates.join(", ")} WHERE ID_No = ?`,
    values
  );

  return await this.getStudentById(idNo);
};

/**
 * Deactivate student
 */
exports.deactivateStudent = async (idNo) => {
  const [result] = await db.query(
    "UPDATE students SET is_active = 0 WHERE ID_No = ?",
    [idNo]
  );

  if (!result.affectedRows) {
    throw new Error("Student not found");
  }

  return this.getStudentById(idNo);
};

/**
 * Activate student
 */
exports.activateStudent = async (idNo) => {
  const [result] = await db.query(
    "UPDATE students SET is_active = 1 WHERE ID_No = ?",
    [idNo]
  );

  if (!result.affectedRows) {
    throw new Error("Student not found");
  }

  return this.getStudentById(idNo);
};
