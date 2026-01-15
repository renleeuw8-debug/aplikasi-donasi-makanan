const pool = require("./config/database");

async function updateSchema() {
  try {
    console.log("🔄 Updating kebutuhan_penerima table schema...\n");

    // First, check current schema
    console.log("📋 Current schema:");
    const [descBefore] = await pool.query("DESCRIBE kebutuhan_penerima");
    descBefore.forEach((row) => {
      if (row.Field === "jenis_kebutuhan") {
        console.log(`  jenis_kebutuhan: ${row.Type}`);
      }
    });

    // Run the ALTER TABLE command
    console.log("\n⚙️  Running ALTER TABLE...");
    await pool.query(`
      ALTER TABLE kebutuhan_penerima 
      MODIFY COLUMN jenis_kebutuhan enum('makanan','pakaian','buku','kesehatan','barang','lainnya') NOT NULL
    `);
    console.log("✅ ALTER TABLE completed");

    // Verify the change
    console.log("\n📋 Updated schema:");
    const [descAfter] = await pool.query("DESCRIBE kebutuhan_penerima");
    descAfter.forEach((row) => {
      if (row.Field === "jenis_kebutuhan") {
        console.log(`  jenis_kebutuhan: ${row.Type}`);
      }
    });

    console.log("\n✅ Schema update successful!");
    console.log("\nThe following jenis_kebutuhan values are now supported:");
    console.log("  • makanan");
    console.log("  • pakaian");
    console.log("  • buku");
    console.log("  • kesehatan");
    console.log("  • barang");
    console.log("  • lainnya");

    process.exit(0);
  } catch (error) {
    console.error("❌ Error updating schema:", error.message);
    if (error.code === "ER_DUP_FIELDNAME") {
      console.log(
        "\n💡 The schema might already be updated. Run check-kebutuhan-schema.js to verify."
      );
    }
    process.exit(1);
  }
}

updateSchema();
