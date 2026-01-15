const pool = require("./config/database");

(async () => {
  try {
    // Cek donasi yang sudah diterima (status = 'diterima')
    const [diterima] = await pool.query(`
      SELECT 
        d.id,
        d.nama_barang,
        d.donatur_id,
        d.penerima_id,
        d.status,
        d.created_at,
        d.updated_at,
        u_penerima.nama as penerima_nama,
        u_donatur.nama as donatur_nama
      FROM donasi d
      LEFT JOIN users u_penerima ON d.penerima_id = u_penerima.id
      LEFT JOIN users u_donatur ON d.donatur_id = u_donatur.id
      WHERE d.status = 'diterima'
      ORDER BY d.updated_at DESC
    `);

    console.log('\n=== DONASI DENGAN STATUS "DITERIMA" ===\n');
    if (diterima.length === 0) {
      console.log('❌ Tidak ada donasi dengan status "diterima"');
    } else {
      diterima.forEach((d) => {
        console.log(`ID ${d.id}: "${d.nama_barang}"`);
        console.log(`  - Donatur: ${d.donatur_nama} (ID ${d.donatur_id})`);
        console.log(`  - Penerima: ${d.penerima_nama} (ID ${d.penerima_id})`);
        console.log(`  - Status: ${d.status}`);
        console.log(`  - Updated: ${d.updated_at}\n`);
      });
    }

    // Cek untuk Putri (ID 10) - donasi apa yang diterima?
    console.log("\n=== DONASI DITERIMA UNTUK PUTRI (ID 10) ===\n");
    const [putriDiterima] = await pool.query(`
      SELECT 
        d.id,
        d.nama_barang,
        d.donatur_id,
        d.penerima_id,
        d.status
      FROM donasi d
      WHERE d.penerima_id = 10 AND d.status = 'diterima'
      ORDER BY d.updated_at DESC
    `);

    if (putriDiterima.length === 0) {
      console.log("Putri belum ada donasi diterima");
    } else {
      console.log(`Putri punya ${putriDiterima.length} donasi diterima:`);
      putriDiterima.forEach((d) => {
        console.log(`  - ID ${d.id}: "${d.nama_barang}"`);
      });
    }

    // Cek untuk Junter (ID 7)
    console.log("\n=== DONASI DITERIMA UNTUK JUNTER (ID 7) ===\n");
    const [junterDiterima] = await pool.query(`
      SELECT 
        d.id,
        d.nama_barang,
        d.donatur_id,
        d.penerima_id,
        d.status
      FROM donasi d
      WHERE d.penerima_id = 7 AND d.status = 'diterima'
      ORDER BY d.updated_at DESC
    `);

    if (junterDiterima.length === 0) {
      console.log("Junter belum ada donasi diterima");
    } else {
      console.log(`Junter punya ${junterDiterima.length} donasi diterima:`);
      junterDiterima.forEach((d) => {
        console.log(`  - ID ${d.id}: "${d.nama_barang}"`);
      });
    }

    process.exit(0);
  } catch (e) {
    console.error("Error:", e.message);
    process.exit(1);
  }
})();
