const pool = require("./config/database");

async function resetAndCheck() {
  try {
    console.log("=== Resetting Donations 11 & 12 ===");

    await pool.query(
      "UPDATE donasi SET penerima_id = NULL, status = ?, petugas_id = 1 WHERE id IN (11, 12)",
      ["diverifikasi"]
    );
    console.log(
      "✓ Reset donasi 11 dan 12 - status diverifikasi, penerima_id NULL, petugas_id = 1"
    );

    const [check] = await pool.query(
      "SELECT id, donatur_id, status, penerima_id, petugas_id, nama_barang FROM donasi WHERE id IN (10,11,12) ORDER BY id"
    );
    console.log("\nCurrent Database State:");
    console.log(JSON.stringify(check, null, 2));

    process.exit(0);
  } catch (error) {
    console.error("Error:", error.message);
    process.exit(1);
  }
}

resetAndCheck();
