const mysql = require("mysql2/promise");
const bcrypt = require("bcryptjs");

const users = [
  {
    email: "petugas@gmail.com",
    password: "petugas123",
    nama: "Petugas",
    role: "petugas",
  },
  {
    email: "admin@gmail.com",
    password: "Rhifaldy26",
    nama: "Admin",
    role: "admin",
  },
];

(async () => {
  try {
    const conn = await mysql.createConnection({
      host: "localhost",
      user: "root",
      database: "donasi_makanan",
    });

    console.log("🔐 Resetting Passwords\n");

    for (const user of users) {
      // Hash password
      const hashedPassword = await bcrypt.hash(user.password, 10);

      // Update di database
      await conn.query("UPDATE users SET password_hash = ? WHERE email = ?", [
        hashedPassword,
        user.email,
      ]);

      console.log(`✅ ${user.email}`);
      console.log(`   Password: ${user.password}`);
      console.log(`   Role: ${user.role}\n`);
    }

    console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    console.log("✨ All passwords have been reset!");
    console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

    conn.end();
  } catch (err) {
    console.error("❌ Error:", err.message);
    process.exit(1);
  }
})();
