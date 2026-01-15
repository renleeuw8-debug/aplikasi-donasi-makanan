const pool = require("./config/database");

async function checkKebutuhanData() {
  try {
    console.log("🔍 Checking kebutuhan_penerima data...\n");

    // Get all kebutuhan with status breakdown
    const [rows] = await pool.query(`
      SELECT 
        id,
        penerima_id,
        jenis_kebutuhan,
        deskripsi,
        status,
        created_at
      FROM kebutuhan_penerima
      ORDER BY created_at DESC
    `);

    if (rows.length === 0) {
      console.log("📭 No kebutuhan found in database");
      process.exit(0);
    }

    console.log(`📊 Total kebutuhan: ${rows.length}\n`);

    // Count by status
    const aktif = rows.filter((r) => r.status === "aktif").length;
    const terpenuhi = rows.filter((r) => r.status === "terpenuhi").length;

    console.log(`Status Breakdown:`);
    console.log(`  ✅ Aktif: ${aktif}`);
    console.log(`  ✓ Terpenuhi: ${terpenuhi}\n`);

    console.log("📋 All Kebutuhan:");
    console.table(rows);

    if (terpenuhi === 0) {
      console.log("\n💡 No kebutuhan marked as 'terpenuhi' yet.");
      console.log("   To see data in the 'Terpenuhi' tab:");
      console.log("   1. Go to a kebutuhan detail page");
      console.log("   2. Click Edit");
      console.log("   3. Change status to 'Terpenuhi'");
      console.log("   4. Save");
    }

    process.exit(0);
  } catch (error) {
    console.error("❌ Error:", error.message);
    process.exit(1);
  }
}

checkKebutuhanData();
