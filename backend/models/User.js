const pool = require("../config/database");
const bcrypt = require("bcryptjs");

class User {
  static async findById(id) {
    const [rows] = await pool.query("SELECT * FROM users WHERE id = ?", [id]);
    return rows[0] || null;
  }

  static async findByEmail(email) {
    const [rows] = await pool.query("SELECT * FROM users WHERE email = ?", [
      email,
    ]);
    return rows[0] || null;
  }

  static async create(data) {
    const hashedPassword = await bcrypt.hash(data.password, 10);
    const [result] = await pool.query(
      "INSERT INTO users (nama, email, password_hash, no_hp, role, alamat, latitude, longitude, nama_panti_asuhan) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
      [
        data.nama,
        data.email,
        hashedPassword,
        data.no_hp || null,
        data.role,
        data.alamat || null,
        data.latitude || null,
        data.longitude || null,
        data.nama_panti_asuhan || null,
      ]
    );
    return result.insertId;
  }

  static async update(id, data) {
    const updates = [];
    const values = [];

    if (data.nama) {
      updates.push("nama = ?");
      values.push(data.nama);
    }
    if (data.no_hp) {
      updates.push("no_hp = ?");
      values.push(data.no_hp);
    }
    if (data.alamat) {
      updates.push("alamat = ?");
      values.push(data.alamat);
    }
    if (data.latitude !== undefined) {
      updates.push("latitude = ?");
      values.push(data.latitude || null);
    }
    if (data.longitude !== undefined) {
      updates.push("longitude = ?");
      values.push(data.longitude || null);
    }
    if (data.nama_panti_asuhan !== undefined) {
      updates.push("nama_panti_asuhan = ?");
      values.push(data.nama_panti_asuhan || null);
    }
    if (data.status) {
      updates.push("status = ?");
      values.push(data.status);
    }

    if (updates.length === 0) return null;

    values.push(id);
    const query = `UPDATE users SET ${updates.join(", ")} WHERE id = ?`;
    const [result] = await pool.query(query, values);
    return result.affectedRows > 0;
  }

  static async getAll(role = null) {
    let query =
      "SELECT id, nama, email, no_hp, role, status, alamat, created_at FROM users";
    const params = [];

    if (role) {
      query += " WHERE role = ?";
      params.push(role);
    }

    const [rows] = await pool.query(query, params);
    return rows;
  }

  static async verifyPassword(plainPassword, hashedPassword) {
    // Try bcrypt first (for new passwords)
    try {
      const isBcrypt = await bcrypt.compare(plainPassword, hashedPassword);
      if (isBcrypt) return true;
    } catch (e) {
      // Not bcrypt, try SHA256
    }

    // Fallback to SHA256 (for legacy passwords)
    const crypto = require("crypto");
    const sha256Hash = crypto
      .createHash("sha256")
      .update(plainPassword)
      .digest("hex");
    return sha256Hash === hashedPassword;
  }

  static async getStatistics() {
    try {
      // Get total users by role
      const [roleResult] = await pool.query(
        "SELECT role, COUNT(*) as count FROM users WHERE status = 'aktif' GROUP BY role"
      );

      const stats = {
        total_donatur: 0,
        total_penerima: 0,
        total_petugas: 0,
        total_admin: 0,
      };

      // Map role counts
      roleResult.forEach((row) => {
        if (row.role === "donatur") stats.total_donatur = row.count;
        else if (row.role === "penerima") stats.total_penerima = row.count;
        else if (row.role === "petugas") stats.total_petugas = row.count;
        else if (row.role === "admin") stats.total_admin = row.count;
      });

      return stats;
    } catch (error) {
      console.error("Error getting user statistics:", error);
      throw error;
    }
  }
}

module.exports = User;
