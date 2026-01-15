const fs = require("fs");
const path = require("path");

/**
 * Middleware untuk check maintenance mode
 * Izinkan akses hanya jika maintenance mode OFF atau user adalah admin
 */
const maintenanceMiddleware = (req, res, next) => {
  try {
    // Baca settings dari file
    const settingsFile = path.join(__dirname, "../public/data/settings.json");
    let settings = {};

    if (fs.existsSync(settingsFile)) {
      const data = fs.readFileSync(settingsFile, "utf8");
      settings = JSON.parse(data);
    }

    // Check apakah maintenance mode aktif
    if (settings.maintenance_mode === true) {
      // Jika user adalah admin, izinkan
      if (req.user && req.user.role === "admin") {
        return next();
      }

      // Non-admin tidak bisa akses
      return res.status(503).json({
        success: false,
        message:
          settings.maintenance_msg ||
          "Sistem sedang dalam pemeliharaan. Mohon coba kembali nanti.",
        code: "MAINTENANCE_MODE",
      });
    }

    // Maintenance mode tidak aktif, lanjutkan
    next();
  } catch (error) {
    console.error("Maintenance middleware error:", error);
    next(); // Jangan block jika ada error, lanjut saja
  }
};

module.exports = maintenanceMiddleware;
