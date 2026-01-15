const mysql = require("mysql2/promise");

async function checkLatest() {
  const connection = await mysql.createConnection({
    host: "localhost",
    user: "root",
    password: "",
    database: "donasi_makanan",
  });

  try {
    console.log("=== CEK DONASI TERBARU (beras test) ===\n");
    const [donasi] = await connection.execute(
      'SELECT id, nama_barang, status FROM donasi WHERE nama_barang = "beras test" LIMIT 1'
    );

    if (donasi.length > 0) {
      const donasiId = donasi[0].id;
      console.log("✅ Donasi ID:", donasiId);
      console.log("   Nama:", donasi[0].nama_barang);
      console.log("   Status:", donasi[0].status);

      console.log("\n=== RIWAYAT UNTUK DONASI INI ===\n");
      const [riwayat] = await connection.execute(
        "SELECT * FROM riwayat_donasi WHERE donasi_id = ? ORDER BY id DESC",
        [donasiId]
      );

      riwayat.forEach((r) => {
        console.log(
          `ID: ${r.id} | Aksi: ${r.aksi} | Keterangan: ${
            r.keterangan === null ? "❌ NULL" : "✅ " + r.keterangan
          }`
        );
      });

      console.log("\n=== VERIFIKASI UNTUK DONASI INI ===\n");
      const [verifikasi] = await connection.execute(
        "SELECT * FROM verifikasi WHERE donasi_id = ?",
        [donasiId]
      );

      if (verifikasi.length > 0) {
        verifikasi.forEach((v) => {
          console.log(
            `ID: ${v.id} | Catatan: ${
              v.catatan === null ? "❌ NULL" : "✅ " + v.catatan
            } | Status: ${v.status_verifikasi}`
          );
        });
      } else {
        console.log("❌ Tidak ada record di verifikasi table");
      }
    } else {
      console.log('❌ Donasi "beras test" tidak ditemukan');
    }
  } catch (error) {
    console.error("Error:", error.message);
  } finally {
    await connection.end();
  }
}

checkLatest();
