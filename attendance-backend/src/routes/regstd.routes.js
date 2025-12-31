const express = require("express");
const router = express.Router();
const regstdController = require("../controllers/regstd.controller");

/**
 * @swagger
 * /api/regstd:
 *   post:
 *     summary: Register a new student (without NFC initially)
 *     tags: [Student Registration]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - student_name
 *               - pin_no
 *               - ID_No
 *               - student_mobile
 *               - parent_mobile
 *             properties:
 *               student_name:
 *                 type: string
 *                 example: Rahul Kumar
 *               pin_no:
 *                 type: string
 *                 example: 21A91A0501
 *               ID_No:
 *                 type: string
 *                 example: STU2024001
 *               college_name:
 *                 type: string
 *                 example: ABC Engineering College
 *               student_mobile:
 *                 type: string
 *                 example: "9876543210"
 *               parent_mobile:
 *                 type: string
 *                 example: "9876543211"
 *               fees_paid:
 *                 type: number
 *                 example: 50000.00
 *               is_active:
 *                 type: integer
 *                 example: 1
 *     responses:
 *       201:
 *         description: Registration successful. NFC assignment needed.
 *       400:
 *         description: Validation error
 *       409:
 *         description: Duplicate entry (ID_No or PIN already exists)
 *       500:
 *         description: Server error
 */
router.post("/", regstdController.createRegstd);

/**
 * @swagger
 * /api/regstd/{ID_No}/assign-nfc:
 *   post:
 *     summary: Assign NFC card to a registered student
 *     tags: [Student Registration]
 *     parameters:
 *       - in: path
 *         name: ID_No
 *         required: true
 *         schema:
 *           type: string
 *         description: Student ID Number
 *         example: STU2024001
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
 *                 example: A1B2C3D4E5
 *                 description: 10-character alphanumeric NFC card ID
 *     responses:
 *       200:
 *         description: NFC card assigned successfully
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
 *                     student_id:
 *                       type: string
 *                     nfc_id:
 *                       type: string
 *                 message:
 *                   type: string
 *       400:
 *         description: Invalid NFC ID format
 *       404:
 *         description: Student not found
 *       409:
 *         description: NFC card already assigned to another student
 *       500:
 *         description: Server error
 */
router.post("/:ID_No/assign-nfc", regstdController.assignNfcCard);

module.exports = router;