const express = require("express");
const KebutuhanController = require("../controllers/KebutuhanController");
const { authMiddleware } = require("../middleware/auth");

const router = express.Router();

// Semua route kebutuhan memerlukan autentikasi
router.use(authMiddleware);

// Create kebutuhan
router.post("/", KebutuhanController.createKebutuhan);

// Get all kebutuhan
router.get("/", KebutuhanController.getAllKebutuhan);

// Get kebutuhan by id
router.get("/:id", KebutuhanController.getKebutuhan);

// Update kebutuhan
router.put("/:id", KebutuhanController.updateKebutuhan);

// Delete kebutuhan
router.delete("/:id", KebutuhanController.deleteKebutuhan);

module.exports = router;
