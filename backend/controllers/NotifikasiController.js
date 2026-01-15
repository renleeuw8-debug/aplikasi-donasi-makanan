const Notifikasi = require("../models/Notifikasi");

class NotifikasiController {
  static async getNotifikasi(req, res) {
    try {
      const { limit } = req.query;

      const notifikasi = await Notifikasi.getByUserId(
        req.user.id,
        limit ? parseInt(limit) : 20
      );

      return res.status(200).json({
        success: true,
        data: notifikasi,
      });
    } catch (error) {
      console.error("Get notifikasi error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  static async getUnreadCount(req, res) {
    try {
      const count = await Notifikasi.getUnreadCount(req.user.id);

      return res.status(200).json({
        success: true,
        data: {
          unread_count: count,
        },
      });
    } catch (error) {
      console.error("Get unread count error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  static async markAsRead(req, res) {
    try {
      const { id } = req.params;

      const updated = await Notifikasi.markAsRead(id);

      if (!updated) {
        return res.status(400).json({
          success: false,
          message: "Gagal menandai notifikasi sebagai telah dibaca",
        });
      }

      return res.status(200).json({
        success: true,
        message: "Notifikasi berhasil ditandai sebagai telah dibaca",
      });
    } catch (error) {
      console.error("Mark as read error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  static async deleteNotifikasi(req, res) {
    try {
      const { id } = req.params;

      const deleted = await Notifikasi.delete(id);

      if (!deleted) {
        return res.status(400).json({
          success: false,
          message: "Gagal menghapus notifikasi",
        });
      }

      return res.status(200).json({
        success: true,
        message: "Notifikasi berhasil dihapus",
      });
    } catch (error) {
      console.error("Delete notifikasi error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }
}

module.exports = NotifikasiController;
