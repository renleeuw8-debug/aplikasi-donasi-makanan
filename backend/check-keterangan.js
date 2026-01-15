const mysql = require("mysql2/promise");

async function checkDatabase() {
  const connection = await mysql.createConnection({
    host: "localhost",
    user: "root",
    password: "",
    database: "donasi_makanan",
  });

  try {
    console.log("=== RIWAYAT DONASI (Last 10 rows) ===\n");
    const [riwayat] = await connection.execute(
      `SELECT r.id, r.donasi_id, r.user_id, r.aksi, r.keterangan, r.created_at,
              u.nama as user_nama, d.nama_barang
       FROM riwayat_donasi r
       LEFT JOIN users u ON r.user_id = u.id
       LEFT JOIN donasi d ON r.donasi_id = d.id
       ORDER BY r.id DESC LIMIT 10`
    );

    riwayat.forEach((row) => {
      console.log(`ID: ${row.id}`);
      console.log(`  Donasi: ${row.nama_barang} (ID: ${row.donasi_id})`);
      console.log(`  User: ${row.user_nama} (ID: ${row.user_id})`);
      console.log(`  Aksi: ${row.aksi}`);
      console.log(
        `  Keterangan: ${row.keterangan === null ? "NULL" : row.keterangan}`
      );
      console.log(`  Created: ${row.created_at}`);
      console.log("");
    });

    console.log("\n=== VERIFIKASI TABLE (Last 5 rows) ===\n");
    const [verifikasi] = await connection.execute(
      `SELECT v.id, v.donasi_id, v.petugas_id, v.catatan, v.status_verifikasi, v.created_at,
              d.nama_barang
       FROM verifikasi v
       LEFT JOIN donasi d ON v.donasi_id = d.id
       ORDER BY v.id DESC LIMIT 5`
    );

    verifikasi.forEach((row) => {
      console.log(`ID: ${row.id}`);
      console.log(`  Donasi: ${row.nama_barang} (ID: ${row.donasi_id})`);
      console.log(`  Petugas ID: ${row.petugas_id}`);
      console.log(`  Catatan: ${row.catatan === null ? "NULL" : row.catatan}`);
      console.log(`  Status: ${row.status_verifikasi}`);
      console.log(`  Created: ${row.created_at}`);
      console.log("");
    });

    console.log(
      "\n=== CROSS CHECK: Donasi yang diverifikasi (status=diverifikasi) ===\n"
    );
    const [diverifikasi] = await connection.execute(
      `SELECT d.id, d.nama_barang, d.status, d.donatur_id, d.petugas_id,
              COUNT(DISTINCT r.id) as total_riwayat,
              COUNT(DISTINCT v.id) as total_verifikasi
       FROM donasi d
       LEFT JOIN riwayat_donasi r ON d.id = r.donasi_id AND r.aksi = 'diverifikasi'
       LEFT JOIN verifikasi v ON d.id = v.donasi_id
       WHERE d.status = 'diverifikasi'
       GROUP BY d.id`
    );

    diverifikasi.forEach((row) => {
      console.log(`Donasi ID ${row.id}: ${row.nama_barang}`);
      console.log(
        `  Donatur ID: ${row.donatur_id}, Petugas ID: ${row.petugas_id}`
      );
      console.log(`  Riwayat records: ${row.total_riwayat}`);
      console.log(`  Verifikasi records: ${row.total_verifikasi}`);
    });
  } catch (error) {
    console.error("Error:", error.message);
  } finally {
    await connection.end();
  }
}

checkDatabase();
