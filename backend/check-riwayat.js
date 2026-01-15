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

    console.log("=== riwayat_donasi columns ===");
    const [cols] = await conn.execute("DESCRIBE riwayat_donasi");
    console.log(JSON.stringify(cols, null, 2));

    console.log("\n=== Last diverifikasi record ===");
    const [data] = await conn.execute(
      'SELECT * FROM riwayat_donasi WHERE aksi = "diverifikasi" ORDER BY created_at DESC LIMIT 1'
    );
    console.log(JSON.stringify(data, null, 2));

    conn.release();
    process.exit(0);
  } catch (error) {
    console.error("Error:", error.message);
    process.exit(1);
  }
}

test();
