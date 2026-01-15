const pool = require("../config/database");

class KebutuhanPenerima {
  static async create(data) {
    const [result] = await pool.query(
      "INSERT INTO kebutuhan_penerima (penerima_id, jenis_kebutuhan, deskripsi, jumlah, foto_kebutuhan) VALUES (?, ?, ?, ?, ?)",
      [
        data.penerima_id,
        data.jenis_kebutuhan,
        data.deskripsi || null,
        data.jumlah || null,
        data.foto_kebutuhan || null,
      ]
    );
    return result.insertId;
  }

  static async findById(id) {
    const [rows] = await pool.query(
      "SELECT kb.*, u.nama as penerima_nama FROM kebutuhan_penerima kb LEFT JOIN users u ON kb.penerima_id = u.id WHERE kb.id = ?",
      [id]
    );
    return rows[0] || null;
  }

  static async getAll(filters = {}) {
    let query =
      "SELECT kb.*, u.nama as penerima_nama FROM kebutuhan_penerima kb LEFT JOIN users u ON kb.penerima_id = u.id WHERE 1=1";
    const params = [];

    if (filters.status) {
      query += " AND kb.status = ?";
      params.push(filters.status);
    }
    if (filters.penerima_id) {
      query += " AND kb.penerima_id = ?";
      params.push(filters.penerima_id);
    }

    query += " ORDER BY kb.created_at DESC";
    const [rows] = await pool.query(query, params);
    return rows;
  }

  static async update(id, data) {
    const updates = [];
    const values = [];

    if (data.deskripsi) {
      updates.push("deskripsi = ?");
      values.push(data.deskripsi);
    }
    if (data.jumlah) {
      updates.push("jumlah = ?");
      values.push(data.jumlah);
    }
    if (data.status) {
      updates.push("status = ?");
      values.push(data.status);
    }
    if (data.foto_kebutuhan) {
      updates.push("foto_kebutuhan = ?");
      values.push(data.foto_kebutuhan);
    }

    if (updates.length === 0) return false;

    values.push(id);
    const query = `UPDATE kebutuhan_penerima SET ${updates.join(
      ", "
    )} WHERE id = ?`;
    const [result] = await pool.query(query, values);
    return result.affectedRows > 0;
  }

  static async delete(id) {
    const [result] = await pool.query(
      "DELETE FROM kebutuhan_penerima WHERE id = ?",
      [id]
    );
    return result.affectedRows > 0;
  }
}

module.exports = KebutuhanPenerima;
