const pool = require("../config/database");

class RiwayatDonasi {
  static async create(data) {
    const finalKeterangan = data.keterangan || null;
    console.log("RiwayatDonasi.create():");
    console.log("  Input keterangan:", JSON.stringify(data.keterangan));
    console.log("  Final keterangan:", JSON.stringify(finalKeterangan));
    console.log("  Data keys:", Object.keys(data));

    const [result] = await pool.query(
      "INSERT INTO riwayat_donasi (donasi_id, user_id, aksi, keterangan) VALUES (?, ?, ?, ?)",
      [data.donasi_id, data.user_id, data.aksi, finalKeterangan]
    );
    console.log("  Insert result ID:", result.insertId);
    return result.insertId;
  }

  static async getByDonasiId(donasi_id) {
    const [rows] = await pool.query(
      "SELECT rd.*, u.nama FROM riwayat_donasi rd LEFT JOIN users u ON rd.user_id = u.id WHERE rd.donasi_id = ? ORDER BY rd.created_at DESC",
      [donasi_id]
    );
    return rows;
  }

  static async getByUserId(user_id) {
    const [rows] = await pool.query(
      "SELECT * FROM riwayat_donasi WHERE user_id = ? ORDER BY created_at DESC",
      [user_id]
    );
    return rows;
  }
}

module.exports = RiwayatDonasi;
