// src/routes/report.routes.js
const express = require("express");
const router = express.Router();
const controller = require("../controllers/report.controller");

/**
 * @swagger
 * /api/reports/overall-monthly:
 *   get:
 *     summary: Get overall monthly report for all students
 *     tags:
 *       - Reports
 *     parameters:
 *       - in: query
 *         name: year
 *         required: true
 *         schema:
 *           type: integer
 *         example: 2024
 *       - in: query
 *         name: month
 *         required: true
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 12
 *         example: 12
 *       - in: query
 *         name: college_name
 *         schema:
 *           type: string
 *         description: Filter by college name
 *     responses:
 *       200:
 *         description: Overall monthly report fetched successfully
 *       400:
 *         description: Missing required parameters
 */
router.get("/overall-monthly", controller.getOverallMonthlyReport);

/**
 * @swagger
 * /api/reports/monthly/{student_id_no}:
 *   get:
 *     summary: Get monthly attendance report for a student
 *     tags:
 *       - Reports
 *     parameters:
 *       - in: path
 *         name: student_id_no
 *         required: true
 *         schema:
 *           type: string
 *         description: Student ID_No
 *         example: REG001
 *       - in: query
 *         name: year
 *         required: true
 *         schema:
 *           type: integer
 *         description: Year (YYYY)
 *         example: 2024
 *       - in: query
 *         name: month
 *         required: true
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 12
 *         description: Month (1-12)
 *         example: 12
 *     responses:
 *       200:
 *         description: Monthly report generated successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: object
 *                 message:
 *                   type: string
 *       400:
 *         description: Bad request - year and month required
 *       404:
 *         description: Student not found
 */
router.get("/monthly/:student_id_no", controller.getMonthlyReport);


/**
 * @swagger
 * /api/reports/overall/{student_id_no}:
 *   get:
 *     summary: Get overall attendance summary for a student
 *     tags:
 *       - Reports
 *     parameters:
 *       - in: path
 *         name: student_id_no
 *         required: true
 *         schema:
 *           type: string
 *         description: Student ID_No
 *         example: REG001
 *     responses:
 *       200:
 *         description: Overall report generated successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: object
 *                   properties:
 *                     student:
 *                       type: object
 *                     overall_summary:
 *                       type: object
 *                       properties:
 *                         total_working_days:
 *                           type: integer
 *                         present_count:
 *                           type: integer
 *                         absent_count:
 *                           type: integer
 *                         attendance_percentage:
 *                           type: string
 *                     monthly_breakdown:
 *                       type: array
 *                 message:
 *                   type: string
 *       404:
 *         description: Student not found
 */
router.get("/overall/:student_id_no", controller.getOverallReport);

module.exports = router;