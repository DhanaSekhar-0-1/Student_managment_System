const db = require("../config/db");

exports.createRegstd = async (data) => {
  const {
    student_name,
    pin_no,
    ID_No,
    college_name,
    student_mobile,
    parent_mobile,
    fees_paid,
    is_active
  } = data;

  const sql = `
    INSERT INTO students
    (
      student_name,
      pin_no,
      ID_No,
      college_name,
      student_mobile,
      parent_mobile,
      fees_paid,
      is_active,
      nfc_id
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;

  const values = [
    student_name,
    pin_no,
    ID_No,
    college_name || null,
    student_mobile,
    parent_mobile,
    fees_paid ?? 0.00,
    is_active ?? 1,
    null  // ✅ Use NULL for no NFC card
  ];

  const [result] = await db.execute(sql, values);
  return result;
};

exports.assignNfcCard = async (ID_No, nfc_id) => {
  const trimmedNfcId = nfc_id ? nfc_id.trim() : null;

  if (!trimmedNfcId) {
    throw new Error("NFC ID is required");
  }

  if (trimmedNfcId.length !== 10) {
    throw new Error(`Invalid NFC ID. Must be exactly 10 characters. Received: "${trimmedNfcId}" (length: ${trimmedNfcId.length})`);
  }

  if (!/^[A-Za-z0-9]{10}$/.test(trimmedNfcId)) {
    throw new Error(`Invalid NFC ID format. Must be alphanumeric only. Received: "${trimmedNfcId}"`);
  }

  const [existing] = await db.query(
    "SELECT ID_No, student_name FROM students WHERE nfc_id = ? AND ID_No != ?",
    [trimmedNfcId, ID_No]
  );

  if (existing.length > 0) {
    throw new Error(`This NFC card is already assigned to ${existing[0].student_name} (${existing[0].ID_No})`);
  }

  const [student] = await db.query(
    "SELECT ID_No, student_name, nfc_id FROM students WHERE ID_No = ?",
    [ID_No]
  );

  if (student.length === 0) {
    throw new Error(`Student with ID_No "${ID_No}" not found`);
  }

  if (student[0].nfc_id !== null && student[0].nfc_id !== trimmedNfcId) {
    throw new Error(`Student already has NFC card "${student[0].nfc_id}". Remove old card before assigning new one.`);
  }

  const [result] = await db.query(
    "UPDATE students SET nfc_id = ? WHERE ID_No = ?",
    [trimmedNfcId, ID_No]
  );

  if (result.affectedRows === 0) {
    throw new Error("Failed to update student record");
  }

  return {
    success: true,
    message: "NFC card assigned successfully",
    student_id: ID_No,
    student_name: student[0].student_name,
    nfc_id: trimmedNfcId
  };
};

module.exports = exports;