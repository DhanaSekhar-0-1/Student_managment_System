// src/services/attendance.service.js
const db = require("../config/db");

/**
 * Mark attendance with new simplified logic
 */
exports.markAttendance = async (nfcId, deviceId = null) => {
  const now = new Date();
  const date = now.toISOString().split("T")[0];
  const time = now.toTimeString().split(" ")[0];
  
  const finalDeviceId = deviceId || process.env.DEFAULT_DEVICE_ID || "ESP32_MAIN_GATE";
  
  // 1. Find student
  const [students] = await db.query(
    `SELECT ID_No, student_name, pin_no, college_name 
     FROM students 
     WHERE nfc_id = ? AND is_active = 1`,
    [nfcId]
  );

  if (students.length === 0) {
    throw new Error("Invalid or inactive student");
  }

  const student = students[0];

  // 2. Check if attendance already marked today
  const [existingAttendance] = await db.query(
    `SELECT attendance_id, status FROM attendance 
     WHERE student_id_no = ? AND attendance_date = ?`,
    [student.ID_No, date]
  );

  if (existingAttendance.length > 0) {
    throw new Error("Attendance already marked for today");
  }

  // 3. Check if it's Sunday
  const dayOfWeek = now.getDay();
  if (dayOfWeek === 0) {
    throw new Error("Today is Sunday (Holiday). Attendance not allowed.");
  }

  // 4. Determine status based on cutoff (10:00 AM)
  const cutoff = process.env.CUTOFF_TIME || "10:00:00";
  const status = time <= cutoff ? "PRESENT" : "ABSENT";

  // 5. Insert attendance record - FIXED: Added nfc_id column
  const [result] = await db.query(
    `INSERT INTO attendance
     (student_id_no, nfc_id, attendance_date, attendance_time, status, device_id, remarks)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [
      student.ID_No,
      nfcId,  // ✅ ADDED: Store the NFC ID that was used for marking
      date, 
      time, 
      status, 
      finalDeviceId,
      status === 'ABSENT' ? 'Marked after 10:00 AM cutoff' : null
    ]
  );

  return {
    attendance_id: result.insertId,
    student_id_no: student.ID_No,
    student_name: student.student_name,
    pin_no: student.pin_no,
    college_name: student.college_name,
    attendance_date: date,
    attendance_time: time,
    status: status,
    device_id: finalDeviceId,
    cutoff_time: cutoff,
    day_of_week: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][dayOfWeek],
    message: status === 'PRESENT' 
      ? `Attendance marked as PRESENT` 
      : `Marked as ABSENT (after ${cutoff} cutoff)`
  };
};

/**
 * Auto-mark absent for students who didn't mark attendance
 * This should be called after 10:00 AM cutoff
 */
exports.autoMarkAbsent = async () => {
  const now = new Date();
  const date = now.toISOString().split("T")[0];
  const time = now.toTimeString().split(" ")[0];
  const cutoff = process.env.CUTOFF_TIME || "10:00:00";
  
  // Only run after cutoff time
  if (time <= cutoff) {
    return {
      message: "Auto-absent marking only runs after cutoff time",
      cutoff_time: cutoff,
      current_time: time
    };
  }

  // Check if it's Sunday
  const dayOfWeek = now.getDay();
  if (dayOfWeek === 0) {
    return {
      message: "Sunday - No auto-absent marking",
      is_holiday: true
    };
  }

  // Check if it's a holiday (no one marked before cutoff)
  const [firstAttendance] = await db.query(
    `SELECT COUNT(*) as count FROM attendance 
     WHERE attendance_date = ? AND attendance_time <= ?`,
    [date, cutoff]
  );

  if (firstAttendance[0].count === 0) {
    return {
      message: "Holiday detected - No one marked attendance before cutoff",
      is_holiday: true,
      reason: "No attendance before 10:00 AM"
    };
  }

  // Get all active students who haven't marked attendance today
  const [unmarkedStudents] = await db.query(
    `SELECT s.ID_No, s.student_name, s.college_name, s.nfc_id
     FROM students s
     WHERE s.is_active = 1
     AND s.ID_No NOT IN (
       SELECT student_id_no 
       FROM attendance 
       WHERE attendance_date = ?
     )`,
    [date]
  );

  if (unmarkedStudents.length === 0) {
    return {
      message: "All students have marked attendance",
      unmarked_count: 0
    };
  }

  // Mark all unmarked students as ABSENT - FIXED: Added nfc_id column
  const insertValues = unmarkedStudents.map(student => [
    student.ID_No,
    student.nfc_id || null,  // ✅ ADDED: Use student's nfc_id or placeholder
    date,
    cutoff, // Use cutoff time for absent marking
    'ABSENT',
    'SYSTEM_AUTO',
    'Auto-marked ABSENT (did not mark attendance before cutoff)'
  ]);

  await db.query(
    `INSERT INTO attendance 
     (student_id_no, nfc_id, attendance_date, attendance_time, status, device_id, remarks)
     VALUES ?`,
    [insertValues]
  );

  return {
    message: "Auto-absent marking completed",
    marked_absent_count: unmarkedStudents.length,
    students: unmarkedStudents.map(s => ({
      student_id: s.ID_No,
      student_name: s.student_name,
      college_name: s.college_name
    }))
  };
};

/**
 * Get today's attendance with all students included
 */
exports.getTodayAttendance = async (filters = {}) => {
  const { college_name, status } = filters;
  
  const now = new Date();
  const today = now.toISOString().split("T")[0];
  const currentTime = now.toTimeString().split(" ")[0];
  const cutoff = process.env.CUTOFF_TIME || "10:00:00";
  const dayOfWeek = now.getDay();
  const dayName = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][dayOfWeek];
  
  // Check if Sunday
  const isSunday = dayOfWeek === 0;
  
  // Check if it's a holiday (no attendance before cutoff)
  const [firstAttendance] = await db.query(
    `SELECT COUNT(*) as count FROM attendance 
     WHERE attendance_date = ? AND attendance_time <= ?`,
    [today, cutoff]
  );
  
  const isHoliday = isSunday || (firstAttendance[0].count === 0 && currentTime > cutoff);
  
  // Build WHERE clause for filtering
  let whereConditions = ["a.attendance_date = ?"];
  let params = [today];
  
  if (college_name) {
    whereConditions.push("s.college_name = ?");
    params.push(college_name);
  }
  
  if (status) {
    whereConditions.push("a.status = ?");
    params.push(status);
  }
  
  const whereClause = whereConditions.join(" AND ");
  
  // Get marked attendance summary
  const [markedSummary] = await db.query(
    `SELECT 
      COUNT(*) as total_marked,
      SUM(CASE WHEN a.status = 'PRESENT' THEN 1 ELSE 0 END) as present,
      SUM(CASE WHEN a.status = 'ABSENT' THEN 1 ELSE 0 END) as absent
    FROM attendance a
    INNER JOIN students s ON a.student_id_no = s.ID_No
    WHERE ${whereClause}`,
    params
  );

  // Get total active students
  let totalStudentsQuery = "SELECT COUNT(*) as total FROM students WHERE is_active = 1";
  let totalParams = [];
  
  if (college_name) {
    totalStudentsQuery += " AND college_name = ?";
    totalParams.push(college_name);
  }
  
  const [totalStudents] = await db.query(totalStudentsQuery, totalParams);
  
  const totalActive = totalStudents[0].total;
  const totalMarked = markedSummary[0].total_marked;
  const notMarked = totalActive - totalMarked;
  
  // Get detailed records
  const [records] = await db.query(
    `SELECT 
      a.attendance_id,
      a.student_id_no,
      s.student_name,
      s.pin_no,
      s.college_name,
      a.attendance_date,
      a.attendance_time,
      a.status,
      COALESCE(a.device_id, 'ESP32_MAIN_GATE') as device_id,
      a.remarks,
      a.created_at
    FROM attendance a
    INNER JOIN students s ON a.student_id_no = s.ID_No
    WHERE ${whereClause}
    ORDER BY a.attendance_time ASC`,
    params
  );

  // Get unmarked students (only if after cutoff and not holiday)
  let unmarkedStudents = [];
  if (currentTime > cutoff && !isHoliday) {
    let unmarkedQuery = `
      SELECT s.ID_No, s.student_name, s.pin_no, s.college_name
      FROM students s
      WHERE s.is_active = 1
      AND s.ID_No NOT IN (
        SELECT student_id_no FROM attendance WHERE attendance_date = ?
      )`;
    
    let unmarkedParams = [today];
    
    if (college_name) {
      unmarkedQuery += " AND s.college_name = ?";
      unmarkedParams.push(college_name);
    }
    
    const [unmarked] = await db.query(unmarkedQuery, unmarkedParams);
    unmarkedStudents = unmarked;
  }
  
  return {
    date: today,
    day_of_week: dayName,
    current_time: currentTime,
    cutoff_time: cutoff,
    is_after_cutoff: currentTime > cutoff,
    is_holiday: isHoliday,
    holiday_reason: isSunday ? "Sunday" : (isHoliday ? "No attendance before 10:00 AM" : null),
    summary: {
      total_students: totalActive,
      total_marked: totalMarked,
      not_marked: notMarked,
      present: markedSummary[0].present,
      absent: markedSummary[0].absent,
      attendance_percentage: totalMarked > 0 
        ? ((markedSummary[0].present / totalMarked) * 100).toFixed(2)
        : 0,
      overall_percentage: totalActive > 0
        ? ((markedSummary[0].present / totalActive) * 100).toFixed(2)
        : 0
    },
    records,
    unmarked_students: unmarkedStudents.map(s => ({
      student_id_no: s.ID_No,
      student_name: s.student_name,
      pin_no: s.pin_no,
      college_name: s.college_name,
      status: 'NOT_MARKED'
    }))
  };
};

/**
 * Get student attendance history
 */
exports.getStudentAttendance = async (studentIdNo, filters = {}) => {
  const { start_date, end_date, month, year, page = 1, limit = 30 } = filters;
  
  // Verify student exists
  const [students] = await db.query(
    "SELECT ID_No, student_name, pin_no, college_name FROM students WHERE ID_No = ?",
    [studentIdNo]
  );
  
  if (students.length === 0) {
    throw new Error("Student not found");
  }
  
  const student = students[0];
  
  // Build date filter
  let dateConditions = [];
  let params = [studentIdNo];
  
  if (start_date && end_date) {
    dateConditions.push("attendance_date BETWEEN ? AND ?");
    params.push(start_date, end_date);
  } else if (month && year) {
    dateConditions.push("YEAR(attendance_date) = ? AND MONTH(attendance_date) = ?");
    params.push(year, month);
  } else if (year) {
    dateConditions.push("YEAR(attendance_date) = ?");
    params.push(year);
  }
  
  const dateClause = dateConditions.length > 0 
    ? `AND ${dateConditions.join(" AND ")}`
    : "";
  
  // Get summary (only count working days - days with any attendance)
  const [summary] = await db.query(
    `SELECT 
      COUNT(*) as total_days,
      SUM(CASE WHEN status = 'PRESENT' THEN 1 ELSE 0 END) as present,
      SUM(CASE WHEN status = 'ABSENT' THEN 1 ELSE 0 END) as absent
    FROM attendance
    WHERE student_id_no = ? ${dateClause}`,
    params
  );
  
  const total = summary[0].total_days;
  const present = summary[0].present;
  const absent = summary[0].absent;
  
  // Get records with pagination
  const offset = (page - 1) * limit;
  const [records] = await db.query(
    `SELECT 
      attendance_id,
      attendance_date,
      attendance_time,
      status,
      COALESCE(device_id, 'ESP32_MAIN_GATE') as device_id,
      remarks,
      created_at
    FROM attendance
    WHERE student_id_no = ? ${dateClause}
    ORDER BY attendance_date DESC, attendance_time DESC
    LIMIT ? OFFSET ?`,
    [...params, parseInt(limit), parseInt(offset)]
  );
  
  return {
    student,
    summary: {
      total_working_days: total,
      present: present,
      absent: absent,
      attendance_percentage: total > 0 ? ((present / total) * 100).toFixed(2) : 0
    },
    records,
    pagination: {
      currentPage: parseInt(page),
      totalPages: Math.ceil(total / limit),
      totalRecords: total,
      limit: parseInt(limit)
    }
  };
};

/**
 * Get attendance by date range
 */
exports.getAttendanceByDateRange = async (startDate, endDate, filters = {}) => {
  const { college_name, student_id_no } = filters;
  
  let whereConditions = ["a.attendance_date BETWEEN ? AND ?"];
  let params = [startDate, endDate];
  
  if (college_name) {
    whereConditions.push("s.college_name = ?");
    params.push(college_name);
  }
  
  if (student_id_no) {
    whereConditions.push("a.student_id_no = ?");
    params.push(student_id_no);
  }
  
  const whereClause = whereConditions.join(" AND ");
  
  const [records] = await db.query(
    `SELECT 
      a.attendance_id,
      a.student_id_no,
      s.student_name,
      s.pin_no,
      s.college_name,
      a.attendance_date,
      a.attendance_time,
      a.status,
      COALESCE(a.device_id, 'ESP32_MAIN_GATE') as device_id,
      a.remarks
    FROM attendance a
    INNER JOIN students s ON a.student_id_no = s.ID_No
    WHERE ${whereClause}
    ORDER BY a.attendance_date DESC, a.attendance_time DESC`,
    params
  );
  
  // Calculate summary
  const summary = {
    total: records.length,
    present: records.filter(r => r.status === 'PRESENT').length,
    absent: records.filter(r => r.status === 'ABSENT').length,
  };
  
  summary.attendance_percentage = summary.total > 0
    ? ((summary.present / summary.total) * 100).toFixed(2)
    : 0;
  
  return {
    start_date: startDate,
    end_date: endDate,
    summary,
    records
  };
};

/**
 * Update attendance record
 */
exports.updateAttendance = async (attendanceId, updateData) => {
  const { status, attendance_time, remarks } = updateData;
  
  // Check if attendance exists
  const [existing] = await db.query(
    "SELECT attendance_id FROM attendance WHERE attendance_id = ?",
    [attendanceId]
  );
  
  if (existing.length === 0) {
    throw new Error("Attendance record not found");
  }
  
  const updates = [];
  const values = [];
  
  if (status) {
    if (!['PRESENT', 'ABSENT'].includes(status)) {
      throw new Error("Invalid status. Must be PRESENT or ABSENT");
    }
    updates.push("status = ?");
    values.push(status);
  }
  
  if (attendance_time) {
    updates.push("attendance_time = ?");
    values.push(attendance_time);
  }
  
  if (remarks !== undefined) {
    updates.push("remarks = ?");
    values.push(remarks);
  }
  
  if (updates.length === 0) {
    throw new Error("No valid fields to update");
  }
  
  values.push(attendanceId);
  
  await db.query(
    `UPDATE attendance SET ${updates.join(", ")} WHERE attendance_id = ?`,
    values
  );
  
  // Return updated record
  const [updated] = await db.query(
    `SELECT 
      a.attendance_id,
      a.student_id_no,
      s.student_name,
      a.attendance_date,
      a.attendance_time,
      a.status,
      COALESCE(a.device_id, 'ESP32_MAIN_GATE') as device_id,
      a.remarks
    FROM attendance a
    INNER JOIN students s ON a.student_id_no = s.ID_No
    WHERE a.attendance_id = ?`,
    [attendanceId]
  );
  
  return updated[0];
};

module.exports = exports;