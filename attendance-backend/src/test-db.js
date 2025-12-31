const pool = require("./config/db");

(async () => {
  try {
    const [rows] = await pool.query("SELECT 1");
    console.log("DB test OK:", rows);
    process.exit(0);
  } catch (err) {
    console.error("DB test failed:", err);
    process.exit(1);
  }
})();
