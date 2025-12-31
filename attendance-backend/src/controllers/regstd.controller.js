const regstdService = require("../services/regstd.service");

exports.createRegstd = async (req, res) => {
  try {
    const {
      student_name,
      pin_no,
      ID_No,
      college_name,
      student_mobile,
      parent_mobile,
      fees_paid,
      is_active
    } = req.body;

    // Strict validation
    if (!student_name || !pin_no || !ID_No || !student_mobile || !parent_mobile) {
      return res.status(400).json({
        message: "Missing required fields"
      });
    }

    const result = await regstdService.createRegstd({
      student_name,
      pin_no,
      ID_No,
      college_name,
      student_mobile,
      parent_mobile,
      fees_paid,
      is_active
    });

    res.status(201).json({
      message: "Registration successful. Please assign NFC card to complete setup.",
      S_No: result.insertId,
      ID_No: ID_No,
      note: "Student registered with placeholder NFC ID. Use /assign-nfc endpoint to assign actual card."
    });

  } catch (error) {
    console.error(error);
    
    // Handle duplicate entry errors
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({
        message: "Duplicate entry. Student with this ID_No or PIN already exists.",
        error: error.message
      });
    }
    
    res.status(500).json({
      message: "Internal server error",
      error: error.message
    });
  }
};

/**
 * ✅ NEW ENDPOINT: Assign NFC card to registered student
 * This should be called after registration when student presents NFC card
 */
exports.assignNfcCard = async (req, res) => {
  try {
    const { ID_No } = req.params;
    const { nfc_id } = req.body;

    if (!nfc_id) {
      return res.status(400).json({
        success: false,
        message: "NFC ID is required"
      });
    }

    const result = await regstdService.assignNfcCard(ID_No, nfc_id);

    res.status(200).json({
      success: true,
      data: result,
      message: "NFC card assigned successfully"
    });

  } catch (error) {
    console.error("Assign NFC Error:", error);
    
    if (error.message.includes("already assigned")) {
      return res.status(409).json({
        success: false,
        message: error.message
      });
    }

    if (error.message.includes("not found")) {
      return res.status(404).json({
        success: false,
        message: error.message
      });
    }

    if (error.message.includes("Invalid NFC ID")) {
      return res.status(400).json({
        success: false,
        message: error.message
      });
    }

    res.status(500).json({
      success: false,
      message: "Failed to assign NFC card",
      error: error.message
    });
  }
};

module.exports = exports;