const KebutuhanPenerima = require("../models/KebutuhanPenerima");
const path = require("path");

class KebutuhanController {
  static async createKebutuhan(req, res) {
    try {
      const { jenis_kebutuhan, deskripsi, jumlah } = req.body;

      console.log("📝 Creating kebutuhan...");
      console.log("Body:", { jenis_kebutuhan, deskripsi, jumlah });
      console.log(
        "File:",
        req.file
          ? {
              fieldname: req.file.fieldname,
              filename: req.file.filename,
              path: req.file.path,
            }
          : "No file"
      );

      if (!jenis_kebutuhan) {
        return res.status(400).json({
          success: false,
          message: "Jenis kebutuhan harus diisi",
        });
      }

      // Hanya penerima yang bisa buat kebutuhan
      if (req.user.role !== "penerima" && req.user.role !== "admin") {
        return res.status(403).json({
          success: false,
          message: "Hanya penerima yang bisa membuat kebutuhan",
        });
      }

      // Get foto path dari multer jika file di-upload
      let fotoKebutuhan = null;
      if (req.file) {
        // Normalize path to use forward slashes (for database storage)
        fotoKebutuhan = req.file.path.replace(/\\/g, "/");
        console.log("✅ File uploaded:", fotoKebutuhan);
      }

      console.log("Creating kebutuhan with user ID:", req.user.id);

      const kebutuhanId = await KebutuhanPenerima.create({
        penerima_id: req.user.id,
        jenis_kebutuhan,
        deskripsi: deskripsi || null,
        jumlah: jumlah || null,
        foto_kebutuhan: fotoKebutuhan,
      });

      console.log("✅ Kebutuhan created with ID:", kebutuhanId);

      const kebutuhan = await KebutuhanPenerima.findById(kebutuhanId);

      return res.status(201).json({
        success: true,
        message: "Kebutuhan berhasil dibuat",
        data: kebutuhan,
      });
    } catch (error) {
      console.error("❌ Create kebutuhan error:", error);
      console.error("Error code:", error.code);
      console.error("Error message:", error.message);
      console.error("Error stack:", error.stack);

      // Provide specific error for enum constraint violation
      let errorMessage = "Terjadi kesalahan pada server";
      if (error.code === "ER_TRUNCATED_WRONG_VALUE_FOR_FIELD") {
        errorMessage =
          "Jenis kebutuhan tidak valid. Silakan update database schema terlebih dahulu.";
      } else if (error.code === "ER_BAD_FIELD_ERROR") {
        errorMessage = "Field tidak ditemukan. Silakan update database schema.";
      }

      return res.status(500).json({
        success: false,
        message: errorMessage,
        error: error.message,
        code: error.code,
      });
    }
  }

  static async getKebutuhan(req, res) {
    try {
      const { id } = req.params;

      const kebutuhan = await KebutuhanPenerima.findById(id);

      if (!kebutuhan) {
        return res.status(404).json({
          success: false,
          message: "Kebutuhan tidak ditemukan",
        });
      }

      return res.status(200).json({
        success: true,
        data: kebutuhan,
      });
    } catch (error) {
      console.error("Get kebutuhan error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  static async getAllKebutuhan(req, res) {
    try {
      const { status, penerima_id } = req.query;

      const filters = {};
      if (status) filters.status = status;

      // Jika user adalah penerima, hanya tampilkan kebutuhan miliknya
      if (req.user.role === "penerima") {
        filters.penerima_id = req.user.id;
      } else if (penerima_id) {
        filters.penerima_id = penerima_id;
      }
      // Admin dapat melihat semua kebutuhan (tanpa filter penerima_id)

      const kebutuhanList = await KebutuhanPenerima.getAll(filters);

      return res.status(200).json({
        success: true,
        data: {
          data: kebutuhanList,
        },
      });
    } catch (error) {
      console.error("Get all kebutuhan error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  static async updateKebutuhan(req, res) {
    try {
      const { id } = req.params;
      const { deskripsi, jumlah, status } = req.body;

      const kebutuhan = await KebutuhanPenerima.findById(id);

      if (!kebutuhan) {
        return res.status(404).json({
          success: false,
          message: "Kebutuhan tidak ditemukan",
        });
      }

      // Hanya penerima atau admin yang bisa update
      if (req.user.role !== "admin" && kebutuhan.penerima_id !== req.user.id) {
        return res.status(403).json({
          success: false,
          message: "Anda tidak memiliki akses untuk mengupdate kebutuhan ini",
        });
      }

      // Get foto path dari multer jika file di-upload
      let fotoKebutuhan = undefined;
      if (req.file) {
        // Normalize path to use forward slashes (for database storage)
        fotoKebutuhan = req.file.path.replace(/\\/g, "/");
        console.log("File updated:", fotoKebutuhan);
      }

      const updated = await KebutuhanPenerima.update(id, {
        deskripsi,
        jumlah,
        status,
        foto_kebutuhan: fotoKebutuhan,
      });

      if (!updated) {
        return res.status(400).json({
          success: false,
          message: "Gagal mengupdate kebutuhan",
        });
      }

      const updatedKebutuhan = await KebutuhanPenerima.findById(id);

      return res.status(200).json({
        success: true,
        message: "Kebutuhan berhasil diupdate",
        data: updatedKebutuhan,
      });
    } catch (error) {
      console.error("Update kebutuhan error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  static async deleteKebutuhan(req, res) {
    try {
      const { id } = req.params;

      const kebutuhan = await KebutuhanPenerima.findById(id);

      if (!kebutuhan) {
        return res.status(404).json({
          success: false,
          message: "Kebutuhan tidak ditemukan",
        });
      }

      // Hanya penerima dan admin yang bisa delete
      if (req.user.role !== "admin" && kebutuhan.penerima_id !== req.user.id) {
        return res.status(403).json({
          success: false,
          message: "Anda tidak memiliki akses untuk menghapus kebutuhan ini",
        });
      }

      const deleted = await KebutuhanPenerima.delete(id);

      if (!deleted) {
        return res.status(400).json({
          success: false,
          message: "Gagal menghapus kebutuhan",
        });
      }

      return res.status(200).json({
        success: true,
        message: "Kebutuhan berhasil dihapus",
      });
    } catch (error) {
      console.error("Delete kebutuhan error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }
}

module.exports = KebutuhanController;
