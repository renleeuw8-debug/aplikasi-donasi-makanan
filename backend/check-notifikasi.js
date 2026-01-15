const pool = require("./config/database");

(async () => {
  try {
    const [notif] = await pool.query("SELECT * FROM notifikasi LIMIT 10");

    console.log("\n=== NOTIFIKASI TABLE ===\n");
    if (notif.length > 0) {
      console.log("Columns:", Object.keys(notif[0]));
      console.log("\nSample notifikasi:");
      notif.forEach((n) => {
        console.log(`- ID ${n.id}: "${n.judul}" | is_read: ${n.is_read}`);
      });

      // Count unread
      const unread = notif.filter((n) => n.is_read === 0).length;
      console.log(`\nTotal unread: ${unread}/${notif.length}`);
    }
    process.exit(0);
  } catch (e) {
    console.error("Error:", e.message);
    process.exit(1);
  }
})();
