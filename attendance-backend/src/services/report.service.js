// src/services/report.service.js
const db = require("../config/db");

/**
 * Get monthly attendance report for a student
 */
exports.getMonthlyReport = async (studentIdNo, year, month) => {
  // Verify student exists
  const [students] = await db.query(
    "SELECT ID_No, student_name, pin_no, college_name, student_mobile FROM students WHERE ID_No = ?",
    [studentIdNo]
  );
  
  if (students.length === 0) {
    throw new Error("Student not found");
  }
  
  const student = students[0];
  
  // Get month name
  const monthNames = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];
  const monthName = monthNames[month - 1];
  
  // Calculate total days in month
  const daysInMonth = new Date(year, month, 0).getDate();
  
  // Get attendance records for the month
  const [records] = await db.query(
    `SELECT 
      attendance_date,
      attendance_time,
      status
    FROM attendance
    WHERE student_id_no = ? 
      AND YEAR(attendance_date) = ? 
      AND MONTH(attendance_date) = ?
    ORDER BY attendance_date ASC`,
    [studentIdNo, year, month]
  );
  
  // Calculate summary
  const present = records.filter(r => r.status === 'PRESENT').length;
  const absent = records.filter(r => r.status === 'ABSENT').length;
  
  // Build daily records (only for Mon-Sat)
  const dailyRecords = [];
  const dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
  let workingDays = 0;
  
  for (let day = 1; day <= daysInMonth; day++) {
    const date = new Date(year, month - 1, day);
    const dateStr = date.toISOString().split('T')[0];
    const dayOfWeek = date.getDay();
    const dayName = dayNames[dayOfWeek];
    
    // Skip Sundays
    if (dayOfWeek === 0) {
      dailyRecords.push({
        date: dateStr,
        day: dayName,
        status: 'SUNDAY',
        time: null
      });
      continue;
    }
    
    workingDays++;
    
    const record = records.find(r => r.attendance_date === dateStr);
    
    // If no record and it's a past date, mark as ABSENT
    // If future date, mark as N/A
    const today = new Date();
    const isToday = date.toDateString() === today.toDateString();
    const isFuture = date > today;
    
    let status = 'ABSENT';
    if (record) {
      status = record.status;
    } else if (isFuture) {
      status = 'N/A';
    }
    
    dailyRecords.push({
      date: dateStr,
      day: dayName,
      status: status,
      time: record ? record.attendance_time : null
    });
  }
  
  return {
    student,
    report: {
      year: parseInt(year),
      month: parseInt(month),
      month_name: monthName,
      total_working_days: workingDays,
      present_count: present,
      absent_count: absent,
      attendance_percentage: workingDays > 0 
        ? ((present / workingDays) * 100).toFixed(2)
        : 0,
      absent_percentage: workingDays > 0 
        ? ((absent / workingDays) * 100).toFixed(2)
        : 0
    },
    daily_records: dailyRecords
  };
};

/**
 * Get overall attendance summary for a student
 */
exports.getOverallReport = async (studentIdNo) => {
  // Verify student exists
  const [students] = await db.query(
    "SELECT ID_No, student_name, pin_no, college_name FROM students WHERE ID_No = ?",
    [studentIdNo]
  );
  
  if (students.length === 0) {
    throw new Error("Student not found");
  }
  
  const student = students[0];
  
  // Get overall summary
  const [summary] = await db.query(
    `SELECT 
      COUNT(*) as total_working_days,
      SUM(CASE WHEN status = 'PRESENT' THEN 1 ELSE 0 END) as present_count,
      SUM(CASE WHEN status = 'ABSENT' THEN 1 ELSE 0 END) as absent_count,
      MIN(attendance_date) as first_attendance_date,
      MAX(attendance_date) as last_attendance_date
    FROM attendance
    WHERE student_id_no = ?`,
    [studentIdNo]
  );
  
  const total = summary[0].total_working_days;
  const present = summary[0].present_count;
  
  // Get monthly breakdown
  const [monthlyBreakdown] = await db.query(
    `SELECT 
      YEAR(attendance_date) as year,
      MONTH(attendance_date) as month,
      COUNT(*) as total,
      SUM(CASE WHEN status = 'PRESENT' THEN 1 ELSE 0 END) as present,
      SUM(CASE WHEN status = 'ABSENT' THEN 1 ELSE 0 END) as absent
    FROM attendance
    WHERE student_id_no = ?
    GROUP BY YEAR(attendance_date), MONTH(attendance_date)
    ORDER BY year DESC, month DESC`,
    [studentIdNo]
  );
  
  const monthNames = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];
  
  const formattedBreakdown = monthlyBreakdown.map(row => ({
    year: row.year,
    month: row.month,
    month_name: monthNames[row.month - 1],
    present: row.present,
    absent: row.absent,
    percentage: row.total > 0 
      ? ((row.present / row.total) * 100).toFixed(2)
      : 0
  }));
  
  return {
    student,
    overall_summary: {
      total_working_days: total,
      present_count: present,
      absent_count: summary[0].absent_count,
      attendance_percentage: total > 0 
        ? ((present / total) * 100).toFixed(2)
        : 0,
      first_attendance_date: summary[0].first_attendance_date,
      last_attendance_date: summary[0].last_attendance_date,
      days_enrolled: summary[0].first_attendance_date && summary[0].last_attendance_date
        ? Math.ceil(
            (new Date(summary[0].last_attendance_date) - new Date(summary[0].first_attendance_date)) 
            / (1000 * 60 * 60 * 24)
          ) + 1
        : 0
    },
    monthly_breakdown: formattedBreakdown
  };
};

/**
 * Get overall monthly report for all students
 * Supports optional college_name filter
 */
exports.getOverallMonthlyReport = async (year, month, filters = {}) => {
  const { college_name } = filters;
  
  // Validate inputs
  if (!year || !month) {
    throw new Error("Year and month are required");
  }

  if (month < 1 || month > 12) {
    throw new Error("Invalid month. Must be between 1-12");
  }

  const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  const monthName = monthNames[month - 1];

  // Get date range for the month
  const startDate = `${year}-${month.toString().padStart(2, '0')}-01`;
  const lastDay = new Date(year, month, 0).getDate();
  const endDate = `${year}-${month.toString().padStart(2, '0')}-${lastDay}`;

  // Build WHERE clause for college filter
  let whereClause = "s.is_active = 1";
  let params = [];
  
  if (college_name) {
    whereClause += " AND s.college_name = ?";
    params.push(college_name);
  }

  // Get all active students with their attendance summary for the month
  const query = `
    SELECT 
      s.ID_No as student_id,
      s.student_name,
      s.pin_no,
      s.college_name,
      COUNT(DISTINCT CASE 
        WHEN a.attendance_date BETWEEN ? AND ? 
        AND DAYOFWEEK(a.attendance_date) != 1
        THEN a.attendance_date 
      END) as total_working_days,
      SUM(CASE 
        WHEN a.status = 'PRESENT' 
        AND a.attendance_date BETWEEN ? AND ?
        THEN 1 ELSE 0 
      END) as present_count,
      SUM(CASE 
        WHEN a.status = 'ABSENT' 
        AND a.attendance_date BETWEEN ? AND ?
        THEN 1 ELSE 0 
      END) as absent_count,
      ROUND(
        (SUM(CASE WHEN a.status = 'PRESENT' AND a.attendance_date BETWEEN ? AND ? THEN 1 ELSE 0 END) * 100.0) / 
        NULLIF(COUNT(DISTINCT CASE 
          WHEN a.attendance_date BETWEEN ? AND ? 
          AND DAYOFWEEK(a.attendance_date) != 1
          THEN a.attendance_date 
        END), 0),
      2) as attendance_percentage
    FROM students s
    LEFT JOIN attendance a ON s.ID_No = a.student_id_no
    WHERE ${whereClause}
    GROUP BY s.ID_No, s.student_name, s.pin_no, s.college_name
    ORDER BY s.college_name, s.student_name
  `;

  const queryParams = [
    startDate, endDate,  // total_working_days
    startDate, endDate,  // present_count
    startDate, endDate,  // absent_count
    startDate, endDate,  // attendance_percentage numerator
    startDate, endDate,  // attendance_percentage denominator
    ...params
  ];

  const [students] = await db.query(query, queryParams);

  // Calculate overall summary
  const summary = {
    total_students: students.length,
    total_working_days: 0,
    total_present: 0,
    total_absent: 0,
    overall_percentage: 0,
    students_above_75: 0,
    students_below_75: 0,
  };

  students.forEach(student => {
    const workingDays = parseInt(student.total_working_days) || 0;
    const present = parseInt(student.present_count) || 0;
    const absent = parseInt(student.absent_count) || 0;
    const percentage = parseFloat(student.attendance_percentage) || 0;

    summary.total_working_days = Math.max(summary.total_working_days, workingDays);
    summary.total_present += present;
    summary.total_absent += absent;

    if (percentage >= 75) {
      summary.students_above_75++;
    } else if (workingDays > 0) {
      summary.students_below_75++;
    }
  });

  const totalRecords = summary.total_present + summary.total_absent;
  summary.overall_percentage = totalRecords > 0
    ? parseFloat(((summary.total_present / totalRecords) * 100).toFixed(2))
    : 0;
  
  // Format student data
  const formattedStudents = students.map(student => ({
    student_id: student.student_id,
    student_name: student.student_name,
    pin_no: student.pin_no,
    college_name: student.college_name,
    total_working_days: student.total_working_days || 0,
    present: student.present_count || 0,
    absent: student.absent_count || 0,
    attendance_percentage: student.attendance_percentage || 0,
    status: (student.attendance_percentage || 0) >= 75 ? 'GOOD' : 
            (student.total_working_days || 0) === 0 ? 'NO_DATA' : 'NEEDS_IMPROVEMENT'
  }));

  return {
    year,
    month,
    month_name: monthName,
    date_range: {
      start_date: startDate,
      end_date: endDate
    },
    summary,
    students: formattedStudents
  };
};

module.exports = exports;