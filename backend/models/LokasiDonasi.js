const pool = require("../config/database");

class LokasiDonasi {
  static async create(data) {
    const [result] = await pool.query(
      "INSERT INTO lokasi_donasi (donasi_id, latitude, longitude, alamat) VALUES (?, ?, ?, ?)",
      [data.donasi_id, data.latitude, data.longitude, data.alamat || null]
    );
    return result.insertId;
  }

  static async findByDonasiId(donasi_id) {
    const [rows] = await pool.query(
      "SELECT * FROM lokasi_donasi WHERE donasi_id = ?",
      [donasi_id]
    );
    return rows[0] || null;
  }

  static async update(donasi_id, data) {
    const [result] = await pool.query(
      "UPDATE lokasi_donasi SET latitude = ?, longitude = ?, alamat = ? WHERE donasi_id = ?",
      [data.latitude, data.longitude, data.alamat || null, donasi_id]
    );
    return result.affectedRows > 0;
  }

  static async getMapData() {
    const [rows] = await pool.query("SELECT * FROM v_donasi_peta");
    return rows;
  }

  static async delete(donasi_id) {
    const [result] = await pool.query(
      "DELETE FROM lokasi_donasi WHERE donasi_id = ?",
      [donasi_id]
    );
    return result.affectedRows > 0;
  }
}

module.exports = LokasiDonasi;
