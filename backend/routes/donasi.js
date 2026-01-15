const express = require("express");
const DonasiController = require("../controllers/DonasiController");
const { authMiddleware, requireRole } = require("../middleware/auth");
const multer = require("multer");
const path = require("path");

// Configure multer untuk file upload
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/donasi");
  },
  filename: (req, file, cb) => {
    cb(
      null,
      "bukti-" +
        Date.now() +
        "-" +
        Math.round(Math.random() * 1e9) +
        path.extname(file.originalname)
    );
  },
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB max
  fileFilter: (req, file, cb) => {
    const allowedMimes = ["image/jpeg", "image/png", "image/jpg"];
    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error("Only JPEG and PNG files are allowed"));
    }
  },
});

const router = express.Router();

// Semua route donasi memerlukan autentikasi
router.use(authMiddleware);

// Create donasi
router.post("/", DonasiController.createDonasi);

// Get all donasi (dengan filter otomatis untuk donatur)
router.get("/", DonasiController.getAllDonasi);

// Get donasi saya yang menunggu verifikasi (khusus donatur)
router.get("/my/menunggu", DonasiController.getDonasiSayaMenunggu);

// Get donasi saya yang sudah diverifikasi (khusus donatur)
router.get("/my/diverifikasi", DonasiController.getDonasiSayaDiverifikasi);

// Get donasi menunggu verifikasi (khusus petugas/admin) - HARUS SEBELUM /:id
router.get("/verify/menunggu", DonasiController.getDonasiMenungguVerifikasi);

// Get donasi sudah diverifikasi (riwayat) - HARUS SEBELUM /:id
router.get("/verify/diverifikasi", DonasiController.getDonasiSudahDiverifikasi);

// Get donasi by id
router.get("/:id", DonasiController.getDonasi);

// ==================== FITUR KONEKSI DONATUR-PENERIMA (Via KEBUTUHAN) ====================

// Donatur melihat SEMUA KEBUTUHAN PENERIMA yang masih aktif
router.get("/needs/active", DonasiController.getActiveNeeds);

// Donatur melihat kebutuhan penerima tertentu
router.get("/needs/recipient/:penerima_id", DonasiController.getRecipientNeeds);

// Donatur donasikan langsung ke KEBUTUHAN tertentu (penerima_id auto-filled)
router.post("/needs/donate", DonasiController.donateToNeed);

// Donatur melihat daftar penerima yang membutuhkan
router.get("/direct/recipients", DonasiController.getRecipientsList);

// Penerima melihat donasi yang masuk untuk mereka (tanpa verifikasi)
router.get("/direct/incoming", DonasiController.getIncomingDonations);

// Penerima melihat donasi yang sudah diverifikasi dan siap diterima
router.get("/penerima/available", DonasiController.getAvailableDonations);

// Donatur mendonasikan langsung ke penerima (bypass verifikasi)
router.post("/direct/donate", DonasiController.donateDirectly);

// Penerima menerima/menolak donasi langsung (dengan file upload untuk bukti terima)
router.post(
  "/:id/accept-direct",
  upload.single("foto_bukti_terima"),
  DonasiController.acceptDirectDonation
);
router.post("/:id/reject-direct", DonasiController.rejectDirectDonation);

// Get koneksi donatur-penerima (chat/history)
router.get("/direct/:penerima_id", DonasiController.getDirectDonationHistory);

// ==================== END FITUR KONEKSI ====================

// Update donasi status (for Flutter UI compatibility)
router.put("/:id/status", DonasiController.updateStatus);

// Update donasi
router.put("/:id", DonasiController.updateDonasi);

// Verify donasi (hanya petugas dan admin)
router.post(
  "/:id/verify",
  requireRole("petugas", "admin"),
  DonasiController.verifyDonasi
);

// Receive donasi (semua user)
router.post("/:id/receive", DonasiController.receiveDonasi);

// Complete donasi (hanya petugas dan admin)
router.post(
  "/:id/complete",
  requireRole("petugas", "admin"),
  DonasiController.completeDonasi
);

// Cancel donasi
router.post("/:id/cancel", DonasiController.cancelDonasi);

// Delete donasi
router.delete("/:id", DonasiController.deleteDonasi);

module.exports = router;
