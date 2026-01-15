const pool = require("./config/database");

async function debug() {
  try {
    // 1. Cek users
    console.log("=== USERS ===");
    const [users] = await pool.query(
      "SELECT id, nama, email, role FROM users WHERE role IN ('donatur', 'penerima', 'petugas') ORDER BY id"
    );
    console.log(users);

    // 2. Cek donasi terbaru
    console.log("\n=== DONASI TERBARU ===");
    const [donasi] = await pool.query(
      "SELECT id, donatur_id, penerima_id, petugas_id, status, nama_barang FROM donasi ORDER BY id DESC LIMIT 5"
    );
    console.log(donasi);

    // 3. Cek donasi ID 12 detail
    console.log("\n=== DONASI ID 12 DETAIL ===");
    const [detail] = await pool.query("SELECT * FROM donasi WHERE id = 12");
    console.log(detail[0]);

    process.exit(0);
  } catch (error) {
    console.error("Error:", error);
    process.exit(1);
  }
}

debug();
