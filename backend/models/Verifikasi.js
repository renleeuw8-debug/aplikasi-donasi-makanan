const pool = require("../config/database");

class Verifikasi {
  static async create(data) {
    const [result] = await pool.query(
      "INSERT INTO verifikasi (donasi_id, petugas_id, catatan, status_verifikasi) VALUES (?, ?, ?, ?)",
      [
        data.donasi_id,
        data.petugas_id,
        data.catatan || null,
        data.status_verifikasi || "disetujui",
      ]
    );
    return result.insertId;
  }

  static async findByDonasiId(donasi_id) {
    const [rows] = await pool.query(
      "SELECT * FROM verifikasi WHERE donasi_id = ? ORDER BY created_at DESC",
      [donasi_id]
    );
    return rows[0] || null;
  }

  static async getAll(filters = {}) {
    let query = "SELECT * FROM verifikasi WHERE 1=1";
    const params = [];

    if (filters.petugas_id) {
      query += " AND petugas_id = ?";
      params.push(filters.petugas_id);
    }

    if (filters.status_verifikasi) {
      query += " AND status_verifikasi = ?";
      params.push(filters.status_verifikasi);
    }

    query += " ORDER BY created_at DESC";

    const [rows] = await pool.query(query, params);
    return rows;
  }
}

module.exports = Verifikasi;
