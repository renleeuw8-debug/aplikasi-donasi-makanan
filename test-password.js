const mysql = require("mysql2/promise");

(async () => {
  try {
    const conn = await mysql.createConnection({
      host: "localhost",
      user: "root",
      database: "donasi_makanan",
    });

    const [rows] = await conn.query("SELECT email, password_hash FROM users");

    console.log("📋 Password Hashes di Database:");
    console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    rows.forEach((r, i) => {
      console.log(`${i + 1}. ${r.email}`);
      console.log(`   Hash: ${r.password_hash.substring(0, 60)}...`);
    });

    conn.end();
  } catch (err) {
    console.error("Error:", err.message);
  }
})();
