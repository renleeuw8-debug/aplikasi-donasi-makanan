const mysql = require("mysql2/promise");

async function test() {
  try {
    const pool = mysql.createPool({
      host: "localhost",
      user: "root",
      password: "",
      database: "donasi_makanan",
    });

    const conn = await pool.getConnection();

    console.log("=== Donasi terbaru ===");
    const [donasi] = await conn.execute(
      "SELECT id, nama_barang, jenis_donasi, status, donatur_id FROM donasi ORDER BY created_at DESC LIMIT 3"
    );
    console.log(JSON.stringify(donasi, null, 2));

    console.log("\n=== Donasi dengan status menunggu ===");
    const [menunggu] = await conn.execute(
      'SELECT id, nama_barang, jenis_donasi, status, donatur_id FROM donasi WHERE status = "menunggu"'
    );
    console.log(JSON.stringify(menunggu, null, 2));

    conn.release();
    process.exit(0);
  } catch (error) {
    console.error("Error:", error.message);
    process.exit(1);
  }
}

test();
