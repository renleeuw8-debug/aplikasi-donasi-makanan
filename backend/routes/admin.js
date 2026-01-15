const express = require("express");
const router = express.Router();
const axios = require("axios");

// Middleware untuk check session
const checkAuth = (req, res, next) => {
  if (req.session && req.session.admin_id) {
    next();
  } else {
    res.redirect("/admin");
  }
};

// Login Page (GET)
router.get("/", (req, res) => {
  if (req.session && req.session.admin_id) {
    // Sudah login, redirect ke dashboard
    return res.redirect("/admin/dashboard");
  }
  res.render("admin/login", { error: "" });
});

// Login Handler (POST)
router.post("/", async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.render("admin/login", {
        error: "Email dan password harus diisi",
      });
    }

    // Call backend API untuk login
    const response = await axios.post("http://localhost:3000/api/auth/login", {
      email,
      password,
    });

    const { user, token } = response.data;

    // Check role - hanya admin & petugas yang bisa akses admin panel
    if (user.role !== "admin" && user.role !== "petugas") {
      return res.render("admin/login", {
        error: `Anda tidak memiliki akses ke admin panel (Role: ${user.role})`,
      });
    }

    // Set session
    req.session.admin_id = user.id;
    req.session.admin_name = user.nama;
    req.session.admin_email = user.email;
    req.session.admin_role = user.role;
    req.session.api_token = token;

    // Redirect ke dashboard
    res.redirect("/admin/dashboard");
  } catch (error) {
    console.error("Login error:", error.message);
    let errorMsg = "Terjadi kesalahan saat login";

    if (error.response?.status === 401) {
      errorMsg = "Email atau password salah";
    } else if (error.message.includes("ECONNREFUSED")) {
      errorMsg = "Tidak bisa terhubung ke server backend";
    }

    res.render("admin/login", { error: errorMsg });
  }
});

// Dashboard Page
router.get("/dashboard", checkAuth, async (req, res) => {
  try {
    const apiToken = req.session.api_token;

    // Get donasi stats
    const donasiRes = await axios.get("http://localhost:3000/api/donasi", {
      headers: { Authorization: `Bearer ${apiToken}` },
    });

    // Get kebutuhan stats
    const kebutuhanRes = await axios.get(
      "http://localhost:3000/api/kebutuhan",
      {
        headers: { Authorization: `Bearer ${apiToken}` },
      }
    );

    const donasiStats = {
      total: 0,
      menunggu: 0,
      diverifikasi: 0,
      diterima: 0,
      selesai: 0,
    };

    const kebutuhanStats = {
      total: 0,
      aktif: 0,
      terpenuhi: 0,
    };

    if (donasiRes.data.success && donasiRes.data.data) {
      donasiRes.data.data.forEach((d) => {
        donasiStats.total++;
        const status = d.status || "menunggu";
        if (donasiStats.hasOwnProperty(status)) {
          donasiStats[status]++;
        }
      });
    }

    if (kebutuhanRes.data.success && kebutuhanRes.data.data) {
      kebutuhanRes.data.data.forEach((k) => {
        kebutuhanStats.total++;
        const status = k.status || "aktif";
        if (kebutuhanStats.hasOwnProperty(status)) {
          kebutuhanStats[status]++;
        }
      });
    }

    res.render("admin/dashboard", {
      admin_name: req.session.admin_name,
      admin_role: req.session.admin_role,
      donasiStats,
      kebutuhanStats,
    });
  } catch (error) {
    console.error("Dashboard error:", error.message);
    res.render("admin/dashboard", {
      admin_name: req.session.admin_name,
      admin_role: req.session.admin_role,
      donasiStats: {
        total: 0,
        menunggu: 0,
        diverifikasi: 0,
        diterima: 0,
        selesai: 0,
      },
      kebutuhanStats: { total: 0, aktif: 0, terpenuhi: 0 },
    });
  }
});

// Donasi Management Page
router.get("/donasi", checkAuth, async (req, res) => {
  try {
    const filter = req.query.filter || "";
    const apiToken = req.session.api_token;

    const donasiRes = await axios.get("http://localhost:3000/api/donasi", {
      headers: { Authorization: `Bearer ${apiToken}` },
    });

    let donasi_list = donasiRes.data.data || [];

    if (filter) {
      donasi_list = donasi_list.filter((d) => d.status === filter);
    }

    const status_count = {
      menunggu: 0,
      diverifikasi: 0,
      diterima: 0,
      selesai: 0,
    };
    donasi_list.forEach((d) => {
      const status = d.status || "menunggu";
      if (status_count.hasOwnProperty(status)) {
        status_count[status]++;
      }
    });

    res.render("admin/donasi", {
      admin_name: req.session.admin_name,
      admin_role: req.session.admin_role,
      donasi_list,
      status_count,
      current_filter: filter,
    });
  } catch (error) {
    console.error("Donasi error:", error.message);
    res.render("admin/donasi", {
      admin_name: req.session.admin_name,
      admin_role: req.session.admin_role,
      donasi_list: [],
      status_count: { menunggu: 0, diverifikasi: 0, diterima: 0, selesai: 0 },
      current_filter: "",
    });
  }
});

// Logout
router.get("/logout", (req, res) => {
  req.session.destroy((err) => {
    if (err) {
      return res.send("Error logging out");
    }
    res.redirect("/admin");
  });
});

module.exports = router;
