// src/routes/student.routes.js
const express = require("express");
const router = express.Router();
const controller = require("../controllers/student.controller");

/**
 * @swagger
 * /api/students:
 *   get:
 *     summary: Get all students with filters
 *     tags:
 *       - Students
 *     parameters:
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
 *           default: 20
 *         description: Records per page
 *       - in: query
 *         name: college_name
 *         schema:
 *           type: string
 *         description: Filter by college name
 *       - in: query
 *         name: is_active
 *         schema:
 *           type: integer
 *           enum: [0, 1]
 *         description: Filter by active status
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Search by name, PIN, or ID_No
 *     responses:
 *       200:
 *         description: Students fetched successfully
 */
router.get("/", controller.getStudents);

/**
 * @swagger
 * /api/students/colleges:
 *   get:
 *     summary: Get list of all colleges with student counts
 *     tags:
 *       - Students
 *     responses:
 *       200:
 *         description: Colleges fetched successfully
 */
router.get("/colleges", controller.getColleges);

/**
 * @swagger
 * /api/students/by-nfc/{nfc_id}:
 *   get:
 *     summary: Get student by NFC ID
 *     tags:
 *       - Students
 *     parameters:
 *       - in: path
 *         name: nfc_id
 *         required: true
 *         schema:
 *           type: string
 *           example: A1B2C3D4E5F6G7H8
 *         description: 10-character alphanumeric NFC ID
 *     responses:
 *       200:
 *         description: Student fetched successfully
 *       400:
 *         description: Invalid NFC ID format
 *       404:
 *         description: Student not found
 */
router.get("/by-nfc/:nfc_id", controller.getStudentByNfcId);

/**
 * @swagger
 * /api/students/{id}:
 *   get:
 *     summary: Get single student by ID_No (Primary Key)
 *     tags:
 *       - Students
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Student ID_No (e.g., ID001, STU2024001)
 *     responses:
 *       200:
 *         description: Student fetched successfully
 *       404:
 *         description: Student not found
 */
router.get("/:id", controller.getStudentById);

/**
 * @swagger
 * /api/students:
 *   post:
 *     summary: Create new student
 *     tags:
 *       - Students
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - ID_No
 *               - student_name
 *               - pin_no
 *               - nfc_id
 *               - college_name
 *               - student_mobile
 *               - parent_mobile
 *             properties:
 *               ID_No:
 *                 type: string
 *                 example: ID001
 *                 description: Unique student ID (Primary Key)
 *               student_name:
 *                 type: string
 *                 example: Rahul Kumar
 *               pin_no:
 *                 type: string
 *                 example: 21A91A0501
 *               nfc_id:
 *                 type: string
 *                 example: A1B2C3D4R5
 *                 description: 10-character alphanumeric NFC ID
 *               college_name:
 *                 type: string
 *                 example: ABC Engineering College
 *               student_mobile:
 *                 type: string
 *                 example: "9876543210"
 *                 description: 10-digit mobile number (required)
 *               parent_mobile:
 *                 type: string
 *                 example: "9876543211"
 *                 description: 10-digit mobile number (required)
 *               fees_paid:
 *                 type: number
 *                 example: 50000.00
 *               is_active:
 *                 type: integer
 *                 example: 1
 *     responses:
 *       201:
 *         description: Student created successfully
 *       400:
 *         description: Invalid request or validation error
 *       409:
 *         description: Student already exists (duplicate ID_No, PIN, or NFC)
 */
router.post("/", controller.createStudent);

/**
 * @swagger
 * /api/students/{id}:
 *   patch:
 *     summary: Update student details
 *     tags:
 *       - Students
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Student ID_No
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               student_name:
 *                 type: string
 *               student_mobile:
 *                 type: string
 *                 description: 10-digit mobile number
 *               parent_mobile:
 *                 type: string
 *                 description: 10-digit mobile number
 *               fees_paid:
 *                 type: number
 *               is_active:
 *                 type: integer
 *               college_name:
 *                 type: string
 *     responses:
 *       200:
 *         description: Student updated successfully
 *       400:
 *         description: Invalid request
 *       404:
 *         description: Student not found
 */
router.patch("/:id", controller.updateStudent);

/**
 * @swagger
 * /api/students/{id}/deactivate:
 *   patch:
 *     summary: Deactivate student (soft delete)
 *     tags:
 *       - Students
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Student ID_No
 *     responses:
 *       200:
 *         description: Student deactivated successfully
 *       404:
 *         description: Student not found
 */
router.patch("/:id/deactivate", controller.deactivateStudent);

/**
 * @swagger
 * /api/students/{id}/activate:
 *   patch:
 *     summary: Activate student
 *     tags:
 *       - Students
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Student ID_No
 *     responses:
 *       200:
 *         description: Student activated successfully
 *       404:
 *         description: Student not found
 */
router.patch("/:id/activate", controller.activateStudent);

module.exports = router;