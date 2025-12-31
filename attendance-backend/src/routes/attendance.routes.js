const express = require("express");
const router = express.Router();
const controller = require("../controllers/attendance.controller");

/**
 * @swagger
 * /api/attendance/mark:
 *   post:
 *     summary: Mark attendance using NFC
 *     tags:
 *       - Attendance
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - nfc_id
 *             properties:
 *               nfc_id:
 *                 type: string
 *                 example: A1B2C3D4E5F6G7H8
 *               device_id:
 *                 type: string
 *                 example: ESP32_MAIN_GATE
 *     responses:
 *       200:
 *         description: Attendance marked successfully
 *       400:
 *         description: Invalid request
 *       404:
 *         description: Student not found
 *       409:
 *         description: Attendance already marked today
 */
router.post("/mark", controller.markAttendance);

/**
 * @swagger
 * /api/attendance/today:
 *   get:
 *     summary: Get today's attendance records
 *     tags:
 *       - Attendance
 *     parameters:
 *       - in: query
 *         name: college_name
 *         schema:
 *           type: string
 *         description: Filter by college name
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [PRESENT, ABSENT]
 *         description: Filter by status
 *     responses:
 *       200:
 *         description: Today's attendance fetched successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                 message:
 *                   type: string
 */
router.get("/today", controller.getTodayAttendance);

/**
 * @swagger
 * /api/attendance/student/{student_id_no}:
 *   get:
 *     summary: Get attendance history for a student
 *     tags:
 *       - Attendance
 *     parameters:
 *       - in: path
 *         name: student_id_no
 *         required: true
 *         schema:
 *           type: string
 *         description: Student ID Number
 *         example: REG001
 *       - in: query
 *         name: start_date
 *         schema:
 *           type: string
 *           format: date
 *         description: Start date (YYYY-MM-DD)
 *       - in: query
 *         name: end_date
 *         schema:
 *           type: string
 *           format: date
 *         description: End date (YYYY-MM-DD)
 *       - in: query
 *         name: month
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 12
 *         description: Month (1-12)
 *       - in: query
 *         name: year
 *         schema:
 *           type: integer
 *         description: Year (YYYY)
 *         example: 2024
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page number
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 30
 *         description: Records per page
 *     responses:
 *       200:
 *         description: Student attendance fetched successfully
 *       404:
 *         description: Student not found
 */
router.get("/student/:student_id_no", controller.getStudentAttendance);

/**
 * @swagger
 * /api/attendance/range:
 *   get:
 *     summary: Get attendance by date range
 *     tags:
 *       - Attendance
 *     parameters:
 *       - in: query
 *         name: start_date
 *         required: true
 *         schema:
 *           type: string
 *           format: date
 *         description: Start date (YYYY-MM-DD)
 *         example: 2024-12-01
 *       - in: query
 *         name: end_date
 *         required: true
 *         schema:
 *           type: string
 *           format: date
 *         description: End date (YYYY-MM-DD)
 *         example: 2024-12-31
 *       - in: query
 *         name: college_name
 *         schema:
 *           type: string
 *         description: Filter by college name
 *       - in: query
 *         name: student_id_no
 *         schema:
 *           type: string
 *         description: Filter by student ID
 *     responses:
 *       200:
 *         description: Attendance fetched successfully
 *       400:
 *         description: Missing required parameters
 */
router.get("/range", controller.getAttendanceByDateRange);

/**
 * @swagger
 * /api/attendance/{id}:
 *   patch:
 *     summary: Update attendance record
 *     tags:
 *       - Attendance
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Attendance ID
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [PRESENT, ABSENT]
 *                 description: New status
 *               attendance_time:
 *                 type: string
 *                 description: New time (HH:MM:SS)
 *                 example: 09:30:00
 *               remarks:
 *                 type: string
 *                 description: Update remarks
 *     responses:
 *       200:
 *         description: Attendance updated successfully
 *       400:
 *         description: Invalid data
 *       404:
 *         description: Attendance record not found
 */
 
router.patch("/:id", controller.updateAttendance);

/**
 * @swagger
 * /api/attendance/auto-absent:
 *   post:
 *     summary: Auto-mark absent for students who didn't mark attendance
 *     description: Marks all unmarked students as ABSENT after 10 AM cutoff
 *     tags:
 *       - Attendance
 *     responses:
 *       200:
 *         description: Auto-absent marking completed
 *       400:
 *         description: Before cutoff time or holiday
 */
router.post("/auto-absent", controller.autoMarkAbsent);

module.exports = router;
