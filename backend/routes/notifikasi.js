const express = require("express");
const NotifikasiController = require("../controllers/NotifikasiController");
const { authMiddleware } = require("../middleware/auth");

const router = express.Router();

// Semua route notifikasi memerlukan autentikasi
router.use(authMiddleware);

// Get notifikasi
router.get("/", NotifikasiController.getNotifikasi);

// Get unread count
router.get("/unread/count", NotifikasiController.getUnreadCount);

// Mark as read
router.put("/:id/read", NotifikasiController.markAsRead);

// Delete notifikasi
router.delete("/:id", NotifikasiController.deleteNotifikasi);

module.exports = router;
