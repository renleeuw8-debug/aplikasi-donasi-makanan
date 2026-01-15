#!/usr/bin/env node

/**
 * Database Connection Test & Setup Guide
 * Jalankan: node check-db.js
 */

const mysql = require("mysql2/promise");
require("dotenv").config();

async function checkDatabase() {
  console.log("\n🔍 Checking Database Connection...\n");

  const dbConfig = {
    host: process.env.DB_HOST || "localhost",
    user: process.env.DB_USER || "root",
    password: process.env.DB_PASSWORD || "",
    database: process.env.DB_NAME || "donasi_makanan",
    port: parseInt(process.env.DB_PORT) || 3306,
  };

  console.log("📋 Current Configuration:");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log(`  Host:     ${dbConfig.host}`);
  console.log(`  Port:     ${dbConfig.port}`);
  console.log(`  User:     ${dbConfig.user}`);
  console.log(`  Password: ${dbConfig.password ? "✓ Set" : "✗ Empty"}`);
  console.log(`  Database: ${dbConfig.database}`);
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

  try {
    // Test connection
    const connection = await mysql.createConnection(dbConfig);
    console.log("✅ Database Connection: SUCCESS\n");

    // Test query
    const [rows] = await connection.query("SELECT 1");
    console.log("✅ Query Test: SUCCESS\n");

    // Check if database exists
    const [databases] = await connection.query(
      "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = ?",
      [dbConfig.database]
    );

    if (databases.length > 0) {
      console.log(`✅ Database '${dbConfig.database}': EXISTS\n`);

      // Check tables
      const [tables] = await connection.query(
        "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ?",
        [dbConfig.database]
      );

      console.log("📊 Tables in database:");
      console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      if (tables.length > 0) {
        tables.forEach((table) => {
          console.log(`  ✓ ${table.TABLE_NAME}`);
        });
      } else {
        console.log("  ⚠️  No tables found!");
        console.log("  Run: mysql -u root -p < donasi_makanan.sql");
      }
      console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

      // Check default accounts
      console.log("👤 Checking Default Accounts...");
      const [users] = await connection.query(
        "SELECT id, nama, email, role FROM users LIMIT 10"
      );
      if (users.length > 0) {
        console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        users.forEach((user) => {
          console.log(
            `  ID: ${user.id} | Name: ${user.nama} | Email: ${user.email} | Role: ${user.role}`
          );
        });
        console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
      }
    } else {
      console.log(`❌ Database '${dbConfig.database}': NOT FOUND\n`);
      console.log("📝 Create Database:");
      console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      console.log("  mysql -u root -p < donasi_makanan.sql");
      console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
    }

    await connection.end();

    console.log("✨ Database check completed successfully!");
    console.log("\n🚀 Ready to run: npm start or npm run dev\n");

    process.exit(0);
  } catch (error) {
    console.error("❌ Connection Error:\n");
    console.error("  Code:", error.code);
    console.error("  Message:", error.message);
    console.error("\n");

    if (error.code === "ER_ACCESS_DENIED_ERROR") {
      console.log("🔧 TROUBLESHOOTING: Access Denied\n");
      console.log("1️⃣  Check MySQL is running:");
      console.log("   Windows: Check Services or use: mysqld");
      console.log("   Mac: brew services start mysql");
      console.log("   Linux: sudo systemctl start mysql\n");

      console.log("2️⃣  Check credentials in .env:");
      console.log("   DB_HOST=localhost");
      console.log("   DB_USER=root");
      console.log("   DB_PASSWORD=(leave empty if no password)");
      console.log("   DB_NAME=donasi_makanan\n");

      console.log("3️⃣  Reset MySQL root password:");
      console.log("   Windows: mysqld --skip-grant-tables");
      console.log("   Then login without password and run FLUSH PRIVILEGES\n");

      console.log("4️⃣  Test with MySQL command:");
      console.log("   mysql -u root -h localhost");
      console.log("   (should connect without password if empty)\n");
    } else if (error.code === "PROTOCOL_CONNECTION_LOST") {
      console.log("🔧 TROUBLESHOOTING: Connection Lost\n");
      console.log("1️⃣  MySQL server not running");
      console.log("2️⃣  Wrong host/port in .env");
      console.log("3️⃣  Firewall blocking connection\n");
    } else if (error.code === "ER_BAD_DB_ERROR") {
      console.log("🔧 TROUBLESHOOTING: Database Not Found\n");
      console.log("Run this command to create database:");
      console.log("   mysql -u root -p < donasi_makanan.sql\n");
    }

    process.exit(1);
  }
}

checkDatabase();
