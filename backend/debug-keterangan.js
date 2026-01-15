const mysql = require("mysql2/promise");

async function debugQuery() {
  const connection = await mysql.createConnection({
    host: "localhost",
    user: "root",
    password: "",
    database: "donasi_makanan",
  });

  try {
    console.log("=== CEK DETAIL ROW 8 (RIWAYAT DONASI DIVERIFIKASI) ===\n");
    const [row8] = await connection.execute(
      `SELECT * FROM riwayat_donasi WHERE id = 8`
    );
    console.log("Raw data:", JSON.stringify(row8[0], null, 2));
    console.log("Keterangan type:", typeof row8[0].keterangan);
    console.log("Keterangan value:", row8[0].keterangan);

    console.log("\n=== CEK VERIFIKASI ID 2 (SAME TIMESTAMP) ===\n");
    const [ver2] = await connection.execute(
      `SELECT * FROM verifikasi WHERE id = 2`
    );
    console.log("Raw data:", JSON.stringify(ver2[0], null, 2));
    console.log("Catatan type:", typeof ver2[0].catatan);
    console.log("Catatan value:", ver2[0].catatan);

    console.log("\n=== TIMELINE UNTUK DONASI ID 5 ===\n");
    const [timeline] = await connection.execute(
      `SELECT 
        'riwayat' as source,
        id, 
        donasi_id, 
        user_id, 
        aksi, 
        keterangan, 
        created_at 
       FROM riwayat_donasi 
       WHERE donasi_id = 5
       UNION ALL
       SELECT 
        'verifikasi' as source,
        id, 
        donasi_id, 
        petugas_id as user_id, 
        'verifikasi' as aksi, 
        catatan as keterangan, 
        created_at 
       FROM verifikasi 
       WHERE donasi_id = 5
       ORDER BY created_at`
    );

    timeline.forEach((row) => {
      console.log(
        `[${row.source.toUpperCase()}] ID:${row.id} | Aksi:${row.aksi} | User:${
          row.user_id
        }`
      );
      console.log(`  Keterangan: "${row.keterangan}"`);
      console.log(`  Time: ${row.created_at}\n`);
    });
  } catch (error) {
    console.error("Error:", error.message);
  } finally {
    await connection.end();
  }
}

debugQuery();
