const pool = require("../config/database");

class Donasi {
  static async create(data) {
    const [result] = await pool.query(
      "INSERT INTO donasi (donatur_id, jenis_donasi, nama_barang, jumlah, deskripsi, foto_donasi, status) VALUES (?, ?, ?, ?, ?, ?, ?)",
      [
        data.donatur_id,
        data.jenis_donasi,
        data.nama_barang,
        data.jumlah,
        data.deskripsi || null,
        data.foto_donasi || null,
        "menunggu",
      ]
    );
    return result.insertId;
  }

  static async findById(id) {
    const [rows] = await pool.query(
      "SELECT d.*, u.nama as donatur_nama, u.email as donatur_email FROM donasi d LEFT JOIN users u ON d.donatur_id = u.id WHERE d.id = ?",
      [id]
    );
    return rows[0] || null;
  }

  static async getAll(filters = {}) {
    let query =
      "SELECT d.*, u.nama as donatur_nama, u.email as donatur_email, u.no_hp as donatur_hp FROM donasi d LEFT JOIN users u ON d.donatur_id = u.id WHERE 1=1";
    const params = [];

    if (filters.status) {
      query += " AND d.status = ?";
      params.push(filters.status);
    }
    if (filters.jenis_donasi) {
      query += " AND d.jenis_donasi = ?";
      params.push(filters.jenis_donasi);
    }
    if (filters.donatur_id) {
      query += " AND d.donatur_id = ?";
      params.push(filters.donatur_id);
    }

    query += " ORDER BY d.created_at DESC";
    const [rows] = await pool.query(query, params);
    return rows;
  }

  static async update(id, data) {
    const updates = [];
    const values = [];

    if (data.nama_barang) {
      updates.push("nama_barang = ?");
      values.push(data.nama_barang);
    }
    if (data.jumlah) {
      updates.push("jumlah = ?");
      values.push(data.jumlah);
    }
    if (data.deskripsi) {
      updates.push("deskripsi = ?");
      values.push(data.deskripsi);
    }
    if (data.status) {
      updates.push("status = ?");
      values.push(data.status);
    }
    if (data.petugas_id) {
      updates.push("petugas_id = ?");
      values.push(data.petugas_id);
    }
    if (data.penerima_id) {
      updates.push("penerima_id = ?");
      values.push(data.penerima_id);
    }
    if (data.foto_donasi) {
      updates.push("foto_donasi = ?");
      values.push(data.foto_donasi);
    }

    if (updates.length === 0) return false;

    values.push(id);
    const query = `UPDATE donasi SET ${updates.join(", ")} WHERE id = ?`;
    const [result] = await pool.query(query, values);
    return result.affectedRows > 0;
  }

  static async getByStatus(status) {
    const [rows] = await pool.query(
      "SELECT * FROM donasi WHERE status = ? ORDER BY created_at DESC",
      [status]
    );
    return rows;
  }

  static async delete(id) {
    const [result] = await pool.query("DELETE FROM donasi WHERE id = ?", [id]);
    return result.affectedRows > 0;
  }
}

module.exports = Donasi;
