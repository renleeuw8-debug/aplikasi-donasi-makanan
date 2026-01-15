const mysql = require("mysql2/promise");
require("dotenv").config();

// Ensure all env variables have defaults
const dbConfig = {
  host: process.env.DB_HOST || "localhost",
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD || "",
  database: process.env.DB_NAME || "donasi_makanan",
  port: parseInt(process.env.DB_PORT) || 3306,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelayMs: 0,
};

console.log("🔧 Database Config:");
console.log(`   Host: ${dbConfig.host}`);
console.log(`   Port: ${dbConfig.port}`);
console.log(`   User: ${dbConfig.user}`);
console.log(`   Database: ${dbConfig.database}`);
console.log("");

const pool = mysql.createPool(dbConfig);

// Test connection
pool
  .getConnection()
  .then((connection) => {
    console.log("✅ Database connected successfully");
    connection.release();
  })
  .catch((err) => {
    console.error("❌ Database connection failed:");
    console.error("   Error Code:", err.code);
    console.error("   Error Message:", err.message);
    console.error("");
    console.error("💡 Troubleshooting:");
    console.error("   1. Pastikan MySQL server running");
    console.error("   2. Cek credentials di .env file");
    console.error("   3. Pastikan database 'donasi_makanan' sudah dibuat");
    console.error("   4. Jalankan: mysql -u root -p < donasi_makanan.sql");
  });

module.exports = pool;
