const pool = require("../config/database");

class Notifikasi {
  static async create(data) {
    const [result] = await pool.query(
      "INSERT INTO notifikasi (user_id, judul, pesan, tipe) VALUES (?, ?, ?, ?)",
      [data.user_id, data.judul, data.pesan, data.tipe || "sistem"]
    );
    return result.insertId;
  }

  static async getByUserId(user_id, limit = 20) {
    const [rows] = await pool.query(
      "SELECT * FROM notifikasi WHERE user_id = ? ORDER BY created_at DESC LIMIT ?",
      [user_id, limit]
    );
    return rows;
  }

  static async markAsRead(id) {
    const [result] = await pool.query(
      "UPDATE notifikasi SET is_read = 1 WHERE id = ?",
      [id]
    );
    return result.affectedRows > 0;
  }

  static async getUnreadCount(user_id) {
    const [rows] = await pool.query(
      "SELECT COUNT(*) as count FROM notifikasi WHERE user_id = ? AND is_read = 0",
      [user_id]
    );
    return rows[0].count;
  }

  static async delete(id) {
    const [result] = await pool.query("DELETE FROM notifikasi WHERE id = ?", [
      id,
    ]);
    return result.affectedRows > 0;
  }
}

module.exports = Notifikasi;
