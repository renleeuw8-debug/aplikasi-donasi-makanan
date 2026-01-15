const mysql = require("mysql2/promise");

async function check() {
  const conn = await mysql.createConnection({
    host: "localhost",
    user: "root",
    password: "",
    database: "donasi_makanan",
  });

  const [donasi] = await conn.execute(
    'SELECT id, nama_barang, status FROM donasi WHERE status IN ("menunggu", "diverifikasi") ORDER BY id DESC LIMIT 10'
  );

  console.log("=== DONASI DENGAN STATUS MENUNGGU / DIVERIFIKASI ===\n");
  donasi.forEach((d) => {
    console.log(`ID: ${d.id} | Nama: ${d.nama_barang} | Status: ${d.status}`);
  });

  await conn.end();
}

check();
