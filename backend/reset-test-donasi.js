const pool = require("./config/database");

async function resetTestData() {
  try {
    console.log("=== Resetting test donations ===");

    // Reset donasi ID 11 - back to menunggu
    const [r1] = await pool.query(
      "UPDATE donasi SET penerima_id = NULL, status = ?, petugas_id = NULL WHERE id = ?",
      ["menunggu", 11]
    );
    console.log("✓ Reset donasi ID 11 to 'menunggu'");

    // Reset donasi ID 12 - keep diverifikasi but clear penerima_id
    const [r2] = await pool.query(
      "UPDATE donasi SET penerima_id = NULL WHERE id = ?",
      [12]
    );
    console.log("✓ Reset penerima_id for donasi ID 12");

    // Check result
    const [check] = await pool.query(
      "SELECT id, donatur_id, status, penerima_id, petugas_id FROM donasi WHERE id IN (11, 12)"
    );
    console.log("\nCurrent state:");
    console.log(JSON.stringify(check, null, 2));

    process.exit(0);
  } catch (error) {
    console.error("Error:", error.message);
    process.exit(1);
  }
}

resetTestData();
