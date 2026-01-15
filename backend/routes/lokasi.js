const express = require("express");
const LokasiController = require("../controllers/LokasiController");
const { authMiddleware } = require("../middleware/auth");

const router = express.Router();

// Semua route lokasi memerlukan autentikasi
router.use(authMiddleware);

// Create lokasi
router.post("/", LokasiController.createLokasi);

// Get map data (untuk menampilkan peta)
router.get("/map/data", LokasiController.getMapData);

// Get lokasi by donasi_id
router.get("/:donasi_id", LokasiController.getLokasi);

// Update lokasi
router.put("/:donasi_id", LokasiController.updateLokasi);

module.exports = router;
