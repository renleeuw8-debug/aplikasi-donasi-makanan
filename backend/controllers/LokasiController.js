const LokasiDonasi = require("../models/LokasiDonasi");
const Donasi = require("../models/Donasi");

class LokasiController {
  static async getMapData(req, res) {
    try {
      const mapData = await LokasiDonasi.getMapData();

      return res.status(200).json({
        success: true,
        data: mapData,
      });
    } catch (error) {
      console.error("Get map data error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  static async createLokasi(req, res) {
    try {
      const { latitude, longitude, alamat } = req.body;

      if (!latitude || !longitude) {
        return res.status(400).json({
          success: false,
          message: "Latitude dan longitude harus diisi",
        });
      }

      console.log("📍 Creating lokasi:", { latitude, longitude, alamat });

      // Create lokasi entry (donasi_id will be NULL for now, can be linked later)
      const lokasiId = await LokasiDonasi.create({
        donasi_id: null,
        latitude,
        longitude,
        alamat: alamat || null,
      });

      console.log("✅ Lokasi created with ID:", lokasiId);

      const lokasi = await LokasiDonasi.findByDonasiId(null);

      return res.status(201).json({
        success: true,
        message: "Lokasi berhasil ditambahkan",
        data: { id: lokasiId, latitude, longitude, alamat },
      });
    } catch (error) {
      console.error("❌ Create lokasi error:", error);
      console.error("Error stack:", error.stack);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  static async updateLokasi(req, res) {
    try {
      const { donasi_id } = req.params;
      const { latitude, longitude, alamat } = req.body;

      if (!latitude || !longitude) {
        return res.status(400).json({
          success: false,
          message: "Latitude dan longitude harus diisi",
        });
      }

      const donasi = await Donasi.findById(donasi_id);

      if (!donasi) {
        return res.status(404).json({
          success: false,
          message: "Donasi tidak ditemukan",
        });
      }

      // Hanya donatur atau admin yang bisa update lokasi
      if (req.user.role !== "admin" && donasi.donatur_id !== req.user.id) {
        return res.status(403).json({
          success: false,
          message: "Anda tidak memiliki akses untuk mengupdate lokasi ini",
        });
      }

      const updated = await LokasiDonasi.update(donasi_id, {
        latitude,
        longitude,
        alamat: alamat || null,
      });

      if (!updated) {
        return res.status(400).json({
          success: false,
          message: "Gagal mengupdate lokasi",
        });
      }

      const lokasi = await LokasiDonasi.findByDonasiId(donasi_id);

      return res.status(200).json({
        success: true,
        message: "Lokasi berhasil diupdate",
        data: lokasi,
      });
    } catch (error) {
      console.error("Update lokasi error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  static async getLokasi(req, res) {
    try {
      const { donasi_id } = req.params;

      const lokasi = await LokasiDonasi.findByDonasiId(donasi_id);

      if (!lokasi) {
        return res.status(404).json({
          success: false,
          message: "Lokasi tidak ditemukan",
        });
      }

      return res.status(200).json({
        success: true,
        data: lokasi,
      });
    } catch (error) {
      console.error("Get lokasi error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }
}

module.exports = LokasiController;
