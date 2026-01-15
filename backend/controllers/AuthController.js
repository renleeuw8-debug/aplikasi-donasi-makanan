require("dotenv").config();
const User = require("../models/User");
const jwt = require("jsonwebtoken");
const fs = require("fs");
const path = require("path");

// Debug: Log if JWT_SECRET is available
if (process.env.JWT_SECRET) {
  console.log("✅ JWT_SECRET loaded successfully");
} else {
  console.error("❌ JWT_SECRET is not available!");
}

// Function untuk check maintenance mode
function isMaintenanceActive() {
  try {
    const settingsFile = path.join(__dirname, "../public/data/settings.json");
    if (fs.existsSync(settingsFile)) {
      const data = fs.readFileSync(settingsFile, "utf8");
      const settings = JSON.parse(data);
      return settings.maintenance_mode === true;
    }
  } catch (error) {
    console.error("Error reading settings:", error);
  }
  return false;
}

function getMaintenanceMessage() {
  try {
    const settingsFile = path.join(__dirname, "../public/data/settings.json");
    if (fs.existsSync(settingsFile)) {
      const data = fs.readFileSync(settingsFile, "utf8");
      const settings = JSON.parse(data);
      return (
        settings.maintenance_msg ||
        "Sistem sedang dalam pemeliharaan. Mohon coba kembali nanti."
      );
    }
  } catch (error) {
    console.error("Error reading settings:", error);
  }
  return "Sistem sedang dalam pemeliharaan. Mohon coba kembali nanti.";
}

class AuthController {
  static async login(req, res) {
    try {
      // Check maintenance mode terlebih dahulu
      if (isMaintenanceActive()) {
        return res.status(503).json({
          success: false,
          message: getMaintenanceMessage(),
          code: "MAINTENANCE_MODE",
        });
      }

      const { email, password } = req.body;

      if (!email || !password) {
        return res.status(400).json({
          success: false,
          message: "Email dan password harus diisi",
        });
      }

      const user = await User.findByEmail(email);

      if (!user) {
        return res.status(401).json({
          success: false,
          message: "Email atau password tidak valid",
        });
      }

      const isValidPassword = await User.verifyPassword(
        password,
        user.password_hash
      );

      if (!isValidPassword) {
        return res.status(401).json({
          success: false,
          message: "Email atau password tidak valid",
        });
      }

      if (user.status === "nonaktif") {
        return res.status(403).json({
          success: false,
          message: "Akun Anda telah dinonaktifkan",
        });
      }

      if (!process.env.JWT_SECRET) {
        console.error("❌ JWT_SECRET tidak tersedia!");
        return res.status(500).json({
          success: false,
          message: "Konfigurasi server tidak lengkap",
        });
      }

      const token = jwt.sign(
        {
          id: user.id,
          nama: user.nama,
          email: user.email,
          role: user.role,
        },
        process.env.JWT_SECRET,
        { expiresIn: "7d" }
      );

      return res.status(200).json({
        success: true,
        message: "Login berhasil",
        token,
        user: {
          id: user.id,
          nama: user.nama,
          email: user.email,
          role: user.role,
          alamat: user.alamat,
          no_hp: user.no_hp,
        },
      });
    } catch (error) {
      console.error("Login error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  static async register(req, res) {
    try {
      const {
        nama,
        email,
        password,
        password_confirm,
        no_hp,
        alamat,
        role,
        latitude,
        longitude,
        kontak,
        kebutuhan,
        nama_panti_asuhan,
      } = req.body;

      // Validasi input
      if (!nama || !email || !password) {
        return res.status(400).json({
          success: false,
          message: "Nama, email, dan password harus diisi",
        });
      }

      // Accept both 'no_hp' and 'kontak' for phone number
      const phoneNumber = no_hp || kontak;
      if (!phoneNumber) {
        return res.status(400).json({
          success: false,
          message: "Nomor telpon harus diisi",
        });
      }

      if (password !== password_confirm) {
        return res.status(400).json({
          success: false,
          message: "Password dan konfirmasi password tidak sama",
        });
      }

      if (password.length < 6) {
        return res.status(400).json({
          success: false,
          message: "Password minimal 6 karakter",
        });
      }

      // Validasi nomor telpon (minimal 10 digit)
      if (!/^\d{10,}$/.test(phoneNumber.replace(/\D/g, ""))) {
        return res.status(400).json({
          success: false,
          message: "Nomor telpon harus minimal 10 digit",
        });
      }

      // Cek apakah email sudah terdaftar
      const existingUser = await User.findByEmail(email);
      if (existingUser) {
        return res.status(400).json({
          success: false,
          message: "Email sudah terdaftar",
        });
      }

      // Tentukan role (default: donatur)
      const userRole = role || "donatur";

      // Validasi lokasi untuk donatur dan penerima
      if (
        (userRole === "donatur" || userRole === "penerima") &&
        (!latitude || !longitude)
      ) {
        return res.status(400).json({
          success: false,
          message: "Latitude dan longitude harus diisi untuk pengguna",
        });
      }

      // Validasi nilai latitude dan longitude jika ada
      if ((latitude || longitude) && (!latitude || !longitude)) {
        return res.status(400).json({
          success: false,
          message: "Latitude dan longitude harus diisi bersama",
        });
      }

      if (latitude || longitude) {
        const lat = parseFloat(latitude);
        const lng = parseFloat(longitude);
        if (
          isNaN(lat) ||
          isNaN(lng) ||
          lat < -90 ||
          lat > 90 ||
          lng < -180 ||
          lng > 180
        ) {
          return res.status(400).json({
            success: false,
            message: "Latitude atau longitude tidak valid",
          });
        }
      }

      // Buat user baru
      const userId = await User.create({
        nama,
        email,
        password,
        no_hp: phoneNumber,
        alamat: alamat || null,
        role: userRole,
        latitude: latitude || null,
        longitude: longitude || null,
        nama_panti_asuhan: nama_panti_asuhan || null,
      });

      if (!userId) {
        return res.status(400).json({
          success: false,
          message: "Gagal membuat user baru",
        });
      }

      // Jika penerima, simpan kebutuhan
      if (userRole === "penerima" && kebutuhan && Array.isArray(kebutuhan)) {
        // TODO: Simpan kebutuhan ke tabel penerima_kebutuhan jika ada
        // Untuk sekarang, kebutuhan disimpan di field kebutuhan di users table
      }

      const newUser = await User.findById(userId);

      if (!newUser) {
        return res.status(400).json({
          success: false,
          message: "User tidak ditemukan setelah registrasi",
        });
      }

      if (!process.env.JWT_SECRET) {
        console.error("JWT_SECRET tidak tersedia!");
        return res.status(500).json({
          success: false,
          message: "Konfigurasi server tidak lengkap",
        });
      }

      const token = jwt.sign(
        {
          id: newUser.id,
          nama: newUser.nama,
          email: newUser.email,
          role: newUser.role,
        },
        process.env.JWT_SECRET,
        { expiresIn: "7d" }
      );

      return res.status(201).json({
        success: true,
        message: "Registrasi berhasil",
        token,
        user: {
          id: newUser.id,
          nama: newUser.nama,
          email: newUser.email,
          role: newUser.role,
          alamat: newUser.alamat,
          no_hp: newUser.no_hp,
          latitude: newUser.latitude,
          longitude: newUser.longitude,
        },
      });
    } catch (error) {
      console.error("Register error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  static async getProfile(req, res) {
    try {
      const user = await User.findById(req.user.id);

      if (!user) {
        return res.status(404).json({
          success: false,
          message: "User tidak ditemukan",
        });
      }

      return res.status(200).json({
        success: true,
        data: {
          id: user.id,
          nama: user.nama,
          email: user.email,
          role: user.role,
          alamat: user.alamat,
          no_hp: user.no_hp,
          status: user.status,
          foto_profil: user.foto_profil,
          created_at: user.created_at,
        },
      });
    } catch (error) {
      console.error("Get profile error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  static async updateProfile(req, res) {
    try {
      const { nama, no_hp, alamat } = req.body;

      const updated = await User.update(req.user.id, {
        nama,
        no_hp,
        alamat,
      });

      if (!updated) {
        return res.status(400).json({
          success: false,
          message: "Gagal mengupdate profil",
        });
      }

      const user = await User.findById(req.user.id);

      return res.status(200).json({
        success: true,
        message: "Profil berhasil diupdate",
        data: {
          id: user.id,
          nama: user.nama,
          email: user.email,
          role: user.role,
          alamat: user.alamat,
          no_hp: user.no_hp,
        },
      });
    } catch (error) {
      console.error("Update profile error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  static async updateLocation(req, res) {
    try {
      const { latitude, longitude, alamat } = req.body;
      const userId = req.user.id;

      if (!latitude || !longitude) {
        return res.status(400).json({
          success: false,
          message: "Latitude dan longitude harus diisi",
        });
      }

      // Validasi nilai latitude dan longitude
      const lat = parseFloat(latitude);
      const lng = parseFloat(longitude);

      if (
        isNaN(lat) ||
        isNaN(lng) ||
        lat < -90 ||
        lat > 90 ||
        lng < -180 ||
        lng > 180
      ) {
        return res.status(400).json({
          success: false,
          message: "Latitude atau longitude tidak valid",
        });
      }

      const success = await User.update(userId, {
        latitude: lat,
        longitude: lng,
        alamat: alamat || undefined,
      });

      if (!success) {
        return res.status(400).json({
          success: false,
          message: "Gagal mengupdate lokasi",
        });
      }

      const updatedUser = await User.findById(userId);

      return res.status(200).json({
        success: true,
        message: "Lokasi berhasil diupdate",
        user: {
          id: updatedUser.id,
          nama: updatedUser.nama,
          email: updatedUser.email,
          role: updatedUser.role,
          alamat: updatedUser.alamat,
          no_hp: updatedUser.no_hp,
          latitude: updatedUser.latitude,
          longitude: updatedUser.longitude,
        },
      });
    } catch (error) {
      console.error("Update location error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  static async getStatistics(req, res) {
    try {
      const stats = await User.getStatistics();
      return res.status(200).json({
        success: true,
        data: stats,
      });
    } catch (error) {
      console.error("Get statistics error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  static async uploadProfilePhoto(req, res) {
    try {
      const userId = req.user.id;
      console.log(`📤 Upload photo for user ID: ${userId}`);
      console.log(`📤 User from token: ${JSON.stringify(req.user)}`);

      if (!req.file) {
        console.log(`❌ No file uploaded`);
        return res.status(400).json({
          success: false,
          message: "Foto tidak dikirimkan",
        });
      }

      console.log(`✅ File uploaded: ${req.file.filename}`);

      const fotoPath = `/uploads/profil/${req.file.filename}`;

      // Update user foto_profil di database
      const updateQuery = "UPDATE users SET foto_profil = ? WHERE id = ?";
      const pool = require("../config/database");
      const conn = await pool.getConnection();

      console.log(`🔄 Executing: ${updateQuery} with [${fotoPath}, ${userId}]`);

      const result = await conn.execute(updateQuery, [fotoPath, userId]);
      console.log(`✅ Query result: ${JSON.stringify(result)}`);

      conn.release();

      return res.status(200).json({
        success: true,
        message: "Foto profil berhasil diupload",
        data: {
          foto_profil: fotoPath,
          filename: req.file.filename,
        },
      });
    } catch (error) {
      console.error("Upload profile photo error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }
}

module.exports = AuthController;
