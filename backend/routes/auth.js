const express = require("express");
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const AuthController = require("../controllers/AuthController");
const { authMiddleware } = require("../middleware/auth");

// Setup multer untuk profile photo
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, "..", "uploads", "profil");
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(null, "profil-" + uniqueSuffix + path.extname(file.originalname));
  },
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB limit
});

const router = express.Router();

// Public routes
router.post("/login", AuthController.login);
router.post("/register", AuthController.register);
router.get("/statistics", AuthController.getStatistics);

// Protected routes
router.get("/profile", authMiddleware, AuthController.getProfile);
router.put("/profile", authMiddleware, AuthController.updateProfile);
router.put("/location", authMiddleware, AuthController.updateLocation);
router.post(
  "/upload-profile-photo",
  authMiddleware,
  upload.single("foto_profil"),
  AuthController.uploadProfilePhoto
);

module.exports = router;
