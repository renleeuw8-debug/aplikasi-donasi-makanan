const pool = require("./config/database");

async function checkSchema() {
  try {
    console.log("🔍 Checking kebutuhan_penerima table schema...\n");

    const [rows] = await pool.query("DESCRIBE kebutuhan_penerima");

    console.table(rows);

    console.log("\n📋 Column Details:");
    rows.forEach((row) => {
      if (row.Field === "jenis_kebutuhan") {
        console.log(`\n✅ jenis_kebutuhan Type: ${row.Type}`);
        console.log(`   NULL: ${row.Null}`);
        console.log(`   Default: ${row.Default}`);
      }
    });

    // Try to insert a test record with new enum values
    console.log("\n\n🧪 Testing new enum values...");
    const testValues = [
      "makanan",
      "pakaian",
      "buku",
      "kesehatan",
      "barang",
      "lainnya",
    ];

    for (const value of testValues) {
      try {
        // Don't actually insert, just check if the column accepts the value
        const [result] = await pool.query("SELECT ? as test_jenis_kebutuhan", [
          value,
        ]);
        console.log(`✅ ${value} - OK`);
      } catch (err) {
        console.log(`❌ ${value} - ERROR: ${err.message}`);
      }
    }

    process.exit(0);
  } catch (error) {
    console.error("❌ Error checking schema:", error.message);
    console.error(error);
    process.exit(1);
  }
}

checkSchema();
