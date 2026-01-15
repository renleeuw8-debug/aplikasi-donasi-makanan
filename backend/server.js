const express = require("express");
const cors = require("cors");
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const session = require("express-session");
require("dotenv").config();

console.log("📦 Loading database...");
const pool = require("./config/database");

console.log("📦 Loading routes...");
// Import routes
const authRoutes = require("./routes/auth");
const donasiRoutes = require("./routes/donasi");
const lokasiRoutes = require("./routes/lokasi");
const kebutuhanRoutes = require("./routes/kebutuhan");
const notifikasiRoutes = require("./routes/notifikasi");
const adminRoutes = require("./routes/admin");

const app = express();

// Ensure upload directories exist
const uploadsDir = path.join(__dirname, "uploads");
const donasiDir = path.join(uploadsDir, "donasi");
const kebutuhanDir = path.join(uploadsDir, "kebutuhan");
const profilDir = path.join(uploadsDir, "profil");

if (!fs.existsSync(donasiDir)) {
  fs.mkdirSync(donasiDir, { recursive: true });
  console.log("✅ Created uploads/donasi directory");
}

if (!fs.existsSync(kebutuhanDir)) {
  fs.mkdirSync(kebutuhanDir, { recursive: true });
  console.log("✅ Created uploads/kebutuhan directory");
}

if (!fs.existsSync(profilDir)) {
  fs.mkdirSync(profilDir, { recursive: true });
  console.log("✅ Created uploads/profil directory");
}

// Setup multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    let uploadDir;
    if (file.fieldname === "foto_kebutuhan") {
      uploadDir = path.join(__dirname, "uploads", "kebutuhan");
    } else {
      uploadDir = path.join(__dirname, "uploads", "donasi");
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    const prefix = file.fieldname === "foto_kebutuhan" ? "kebutuhan" : "donasi";
    cb(null, prefix + "-" + uniqueSuffix + path.extname(file.originalname));
  },
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB limit
  // Hapus file filter yang ketat - terima semua tipe file
});

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Setup EJS view engine
app.set("view engine", "ejs");
app.set("views", path.join(__dirname, "views"));

// Setup session management
app.use(
  session({
    secret: process.env.JWT_SECRET || "your_secret_key",
    resave: false,
    saveUninitialized: true,
    cookie: { secure: false, maxAge: 24 * 60 * 60 * 1000 }, // 24 hours
  })
);

// Serve static files untuk admin panel
app.use(express.static(path.join(__dirname, "public")));

// Serve static files untuk uploads
app.use("/uploads", express.static("uploads"));

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/donasi", upload.single("foto_donasi"), donasiRoutes);
app.use("/api/lokasi", lokasiRoutes);
app.use("/api/kebutuhan", upload.single("foto_kebutuhan"), kebutuhanRoutes);
app.use("/api/notifikasi", notifikasiRoutes);

// Admin routes
app.use("/admin", adminRoutes);

// Health check
app.get("/api/health", (req, res) => {
  res.json({ status: "OK", message: "Server berjalan dengan baik" });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error("Error:", err);
  res.status(500).json({
    success: false,
    message: "Terjadi kesalahan pada server",
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: "Route tidak ditemukan",
  });
});

// Start server
const PORT = process.env.PORT || 3000;
const HOST = "0.0.0.0"; // Listen on all network interfaces

const server = app.listen(PORT, HOST, () => {
  const os = require("os");
  const interfaces = os.networkInterfaces();
  let ipAddresses = [];

  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === "IPv4" && !iface.internal) {
        ipAddresses.push(iface.address);
      }
    }
  }

  console.log(`\n✅ Server berjalan di http://localhost:${PORT}`);
  if (ipAddresses.length > 0) {
    console.log(`📱 Akses dari device lain: http://${ipAddresses[0]}:${PORT}`);
  }
  console.log(`📦 Database: ${process.env.DB_NAME}\n`);
});

server.on("error", (err) => {
  if (err.code === "EADDRINUSE") {
    console.error(`❌ Port ${PORT} sudah digunakan!`);
  } else {
    console.error("❌ Server error:", err);
  }
  process.exit(1);
});
