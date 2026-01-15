const mysql = require("mysql2/promise");

async function test() {
  try {
    const pool = mysql.createPool({
      host: "localhost",
      user: "root",
      password: "",
      database: "donasi_makanan",
    });

    console.log("=== Checking donasi status in database ===\n");

    const conn = await pool.getConnection();

    const [donasi] = await conn.execute(
      "SELECT id, nama_barang, jenis_donasi, status, donatur_id, created_at FROM donasi ORDER BY created_at DESC LIMIT 5"
    );

    console.log("Donasi terbaru:");
    console.log(JSON.stringify(donasi, null, 2));

    const [menunggu] = await conn.execute(
      'SELECT COUNT(*) as total FROM donasi WHERE status = "menunggu"'
    );
    console.log('\nTotal donasi dengan status "menunggu":', menunggu[0].total);

    const [diverifikasi] = await conn.execute(
      'SELECT COUNT(*) as total FROM donasi WHERE status = "diverifikasi"'
    );
    console.log(
      'Total donasi dengan status "diverifikasi":',
      diverifikasi[0].total
    );

    conn.release();
    process.exit(0);
  } catch (error) {
    console.error("Error:", error.message);
    process.exit(1);
  }
}

test();
