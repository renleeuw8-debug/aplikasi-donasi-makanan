const Donasi = require("../models/Donasi");
const LokasiDonasi = require("../models/LokasiDonasi");
const RiwayatDonasi = require("../models/RiwayatDonasi");
const Notifikasi = require("../models/Notifikasi");
const Verifikasi = require("../models/Verifikasi");
const User = require("../models/User");

class DonasiController {
  static async createDonasi(req, res) {
    try {
      const { jenis_donasi, nama_barang, jumlah, deskripsi } = req.body;
      const { latitude, longitude, alamat } = req.body;

      // Get foto path dari multer jika file di-upload
      const fotoPath = req.file ? `/uploads/donasi/${req.file.filename}` : null;

      console.log("Request body:", { jenis_donasi, nama_barang, jumlah });
      console.log("Request file:", req.file);

      // Validasi input
      if (!jenis_donasi || !nama_barang || !jumlah) {
        console.log("Validasi gagal - Input:", {
          jenis_donasi,
          nama_barang,
          jumlah,
        });
        return res.status(400).json({
          success: false,
          message: "Jenis donasi, nama barang, dan jumlah harus diisi",
        });
      }

      if (!latitude || !longitude) {
        return res.status(400).json({
          success: false,
          message: "Lokasi (latitude dan longitude) harus diisi",
        });
      }

      // Normalize jenis_donasi - convert kategori names to enum values
      let normalizedJenisDonasi = jenis_donasi.toLowerCase();

      // Map kategori UI to database enum values
      if (
        normalizedJenisDonasi.includes("makanan") ||
        normalizedJenisDonasi.includes("buku")
      ) {
        normalizedJenisDonasi = "makanan";
      } else {
        normalizedJenisDonasi = "barang";
      }

      console.log(`Creating donasi with type: ${normalizedJenisDonasi}`);

      // Buat donasi
      const donasiId = await Donasi.create({
        donatur_id: req.user.id,
        jenis_donasi: normalizedJenisDonasi,
        nama_barang,
        jumlah: parseInt(jumlah),
        deskripsi: deskripsi || null,
        foto_donasi: fotoPath || null,
      });

      // Buat lokasi donasi
      await LokasiDonasi.create({
        donasi_id: donasiId,
        latitude: parseFloat(latitude),
        longitude: parseFloat(longitude),
        alamat: alamat || null,
      });

      // Buat riwayat donasi
      await RiwayatDonasi.create({
        donasi_id: donasiId,
        user_id: req.user.id,
        aksi: "dibuat",
      });

      // Buat notifikasi untuk semua petugas - ada donasi baru
      const petugas = await User.getAll("petugas");
      if (petugas && petugas.length > 0) {
        for (let p of petugas) {
          await Notifikasi.create({
            user_id: p.id,
            judul: "Donasi Baru Masuk",
            pesan: `Ada donasi baru "${nama_barang}" (${jumlah}) dari pengguna yang perlu diverifikasi`,
            tipe: "donasi",
          });
        }
      }

      const donasi = await Donasi.findById(donasiId);

      return res.status(201).json({
        success: true,
        message: "Donasi berhasil dibuat",
        data: donasi,
      });
    } catch (error) {
      console.error("Create donasi error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  static async getDonasi(req, res) {
    try {
      const { id } = req.params;

      const donasi = await Donasi.findById(id);

      if (!donasi) {
        return res.status(404).json({
          success: false,
          message: "Donasi tidak ditemukan",
        });
      }

      const lokasi = await LokasiDonasi.findByDonasiId(id);
      const riwayat = await RiwayatDonasi.getByDonasiId(id);

      return res.status(200).json({
        success: true,
        data: {
          ...donasi,
          lokasi,
          riwayat,
        },
      });
    } catch (error) {
      console.error("Get donasi error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  static async getAllDonasi(req, res) {
    try {
      const { status, jenis_donasi } = req.query;

      const filters = {};
      if (status) filters.status = status;
      if (jenis_donasi) filters.jenis_donasi = jenis_donasi;

      // Jika user adalah donatur, hanya tampilkan donasi miliknya
      if (req.user.role === "donatur") {
        filters.donatur_id = req.user.id;
      }

      // Jika user adalah penerima, gunakan query custom untuk donasi yang tersedia untuk mereka
      if (req.user.role === "penerima") {
        const pool = require("../config/database");
        const user_id = parseInt(req.user.id);

        // Ambil donasi diverifikasi atau diterima yang untuk user ini
        const [donasiList] = await pool.query(
          `
          SELECT 
            d.id,
            d.donatur_id,
            d.penerima_id,
            d.jenis_donasi,
            d.nama_barang,
            d.jumlah,
            d.deskripsi,
            d.status,
            d.foto_donasi,
            d.created_at,
            u.nama as donatur_nama,
            u.email as donatur_email,
            u.no_hp as donatur_hp,
            u.alamat as donatur_alamat,
            ld.latitude,
            ld.longitude,
            ld.alamat as lokasi_alamat
          FROM donasi d
          LEFT JOIN users u ON d.donatur_id = u.id
          LEFT JOIN lokasi_donasi ld ON d.id = ld.donasi_id
          WHERE (d.status = 'diverifikasi' AND (d.penerima_id IS NULL OR d.penerima_id = ?)) OR (d.status = 'diterima' AND d.penerima_id = ?)
          ORDER BY d.created_at DESC
        `,
          [user_id, user_id]
        );

        return res.status(200).json({
          success: true,
          data: donasiList,
        });
      }

      const donasiList = await Donasi.getAll(filters);

      // Tambahkan data lokasi untuk setiap donasi
      for (let donasi of donasiList) {
        donasi.lokasi = await LokasiDonasi.findByDonasiId(donasi.id);
      }

      return res.status(200).json({
        success: true,
        data: donasiList,
      });
    } catch (error) {
      console.error("Get all donasi error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  // Get donasi khusus untuk donatur - hanya yang menunggu verifikasi
  static async getDonasiSayaMenunggu(req, res) {
    try {
      const filters = {
        donatur_id: req.user.id,
        status: "menunggu",
      };

      const donasiList = await Donasi.getAll(filters);

      // Tambahkan data lokasi untuk setiap donasi
      for (let donasi of donasiList) {
        donasi.lokasi = await LokasiDonasi.findByDonasiId(donasi.id);
      }

      return res.status(200).json({
        success: true,
        message: "Donasi Anda yang menunggu verifikasi",
        data: donasiList,
      });
    } catch (error) {
      console.error("Get donasi menunggu error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  // Get donasi khusus untuk donatur - yang sudah diverifikasi ke atas
  static async getDonasiSayaDiverifikasi(req, res) {
    try {
      const filters = {
        donatur_id: req.user.id,
      };

      const donasiList = await Donasi.getAll(filters);

      // Filter hanya yang berstatus diverifikasi, diterima, atau selesai
      const verifiedDonasi = donasiList.filter(
        (d) =>
          d.status === "diverifikasi" ||
          d.status === "diterima" ||
          d.status === "selesai"
      );

      // Tambahkan data lokasi untuk setiap donasi
      for (let donasi of verifiedDonasi) {
        donasi.lokasi = await LokasiDonasi.findByDonasiId(donasi.id);
      }

      return res.status(200).json({
        success: true,
        message: "Donasi Anda yang sudah diverifikasi",
        data: verifiedDonasi,
      });
    } catch (error) {
      console.error("Get donasi diverifikasi error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  // Get donasi menunggu verifikasi untuk petugas
  static async getDonasiMenungguVerifikasi(req, res) {
    try {
      // Hanya petugas dan admin yang bisa akses
      if (req.user.role !== "petugas" && req.user.role !== "admin") {
        return res.status(403).json({
          success: false,
          message: "Anda tidak memiliki akses",
        });
      }

      const filters = {
        status: "menunggu",
      };

      const donasiList = await Donasi.getAll(filters);

      // Tambahkan data lokasi dan donatur info
      for (let donasi of donasiList) {
        donasi.lokasi = await LokasiDonasi.findByDonasiId(donasi.id);
        donasi.donatur = await User.findById(donasi.donatur_id);
      }

      return res.status(200).json({
        success: true,
        message: "Donasi yang menunggu verifikasi",
        data: donasiList,
      });
    } catch (error) {
      console.error("Get donasi menunggu verifikasi error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  // Get donasi yang sudah diverifikasi (riwayat)
  static async getDonasiSudahDiverifikasi(req, res) {
    try {
      // Hanya petugas dan admin yang bisa akses
      if (req.user.role !== "petugas" && req.user.role !== "admin") {
        return res.status(403).json({
          success: false,
          message: "Anda tidak memiliki akses",
        });
      }

      const filters = {
        status: "diverifikasi",
      };

      const donasiList = await Donasi.getAll(filters);

      // Tambahkan data lokasi, donatur info, dan petugas yang verify
      for (let donasi of donasiList) {
        donasi.lokasi = await LokasiDonasi.findByDonasiId(donasi.id);
        donasi.donatur = await User.findById(donasi.donatur_id);
        if (donasi.petugas_id) {
          donasi.petugas = await User.findById(donasi.petugas_id);
        }
      }

      return res.status(200).json({
        success: true,
        message: "Riwayat donasi yang sudah diverifikasi",
        data: donasiList,
      });
    } catch (error) {
      console.error("Get donasi sudah diverifikasi error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  static async updateDonasi(req, res) {
    try {
      const { id } = req.params;
      const { nama_barang, jumlah, deskripsi, foto_donasi } = req.body;

      const donasi = await Donasi.findById(id);

      if (!donasi) {
        return res.status(404).json({
          success: false,
          message: "Donasi tidak ditemukan",
        });
      }

      // Hanya donatur atau admin yang bisa update
      if (req.user.role !== "admin" && donasi.donatur_id !== req.user.id) {
        return res.status(403).json({
          success: false,
          message: "Anda tidak memiliki akses untuk mengupdate donasi ini",
        });
      }

      const updated = await Donasi.update(id, {
        nama_barang,
        jumlah,
        deskripsi,
        foto_donasi,
      });

      if (!updated) {
        return res.status(400).json({
          success: false,
          message: "Gagal mengupdate donasi",
        });
      }

      const updatedDonasi = await Donasi.findById(id);

      return res.status(200).json({
        success: true,
        message: "Donasi berhasil diupdate",
        data: updatedDonasi,
      });
    } catch (error) {
      console.error("Update donasi error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  static async verifyDonasi(req, res) {
    try {
      const { id } = req.params;
      const { penerima_id } = req.body;

      const donasi = await Donasi.findById(id);

      if (!donasi) {
        return res.status(404).json({
          success: false,
          message: "Donasi tidak ditemukan",
        });
      }

      if (donasi.status !== "menunggu") {
        return res.status(400).json({
          success: false,
          message: "Donasi hanya bisa diverifikasi jika statusnya menunggu",
        });
      }

      const updated = await Donasi.update(id, {
        status: "diverifikasi",
        petugas_id: req.user.id,
        penerima_id: penerima_id || null,
      });

      if (!updated) {
        return res.status(400).json({
          success: false,
          message: "Gagal memverifikasi donasi",
        });
      }

      await RiwayatDonasi.create({
        donasi_id: id,
        user_id: req.user.id,
        aksi: "diverifikasi",
      });

      // Simpan ke tabel verifikasi
      await Verifikasi.create({
        donasi_id: id,
        petugas_id: req.user.id,
        catatan: null,
        status_verifikasi: "disetujui",
      });

      // Buat notifikasi untuk donatur
      await Notifikasi.create({
        user_id: donasi.donatur_id,
        judul: "Donasi Diverifikasi",
        pesan: `Donasi Anda (${donasi.nama_barang}) telah diverifikasi oleh petugas`,
        tipe: "verifikasi",
      });

      const updatedDonasi = await Donasi.findById(id);

      return res.status(200).json({
        success: true,
        message: "Donasi berhasil diverifikasi",
        data: updatedDonasi,
      });
    } catch (error) {
      console.error("Verify donasi error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  // Update status donasi (endpoint untuk Flutter)
  static async updateStatus(req, res) {
    try {
      const { id } = req.params;
      const { status, penerima_id, catatan } = req.body;

      console.log("\n=== UPDATE STATUS REQUEST ===");
      console.log("ID:", id);
      console.log("Status:", status);
      console.log(
        "Penerima ID received:",
        penerima_id,
        "(type:",
        typeof penerima_id,
        ")"
      );
      console.log("Catatan received:", JSON.stringify(catatan));
      console.log("Full body:", JSON.stringify(req.body));

      const donasi = await Donasi.findById(id);

      if (!donasi) {
        return res.status(404).json({
          success: false,
          message: "Donasi tidak ditemukan",
        });
      }

      // Hanya petugas dan admin yang bisa ubah status
      if (req.user.role !== "petugas" && req.user.role !== "admin") {
        return res.status(403).json({
          success: false,
          message: "Anda tidak memiliki akses",
        });
      }

      // Validasi status valid
      const validStatus = [
        "menunggu",
        "diverifikasi",
        "diterima",
        "dibatalkan",
        "selesai",
      ];
      if (!validStatus.includes(status)) {
        return res.status(400).json({
          success: false,
          message: "Status tidak valid",
        });
      }

      // Convert penerima_id ke integer untuk keamanan tipe data
      const final_penerima_id = penerima_id
        ? parseInt(penerima_id)
        : donasi.penerima_id;
      console.log("Final penerima_id yang akan disimpan:", final_penerima_id);

      // Update donasi status
      const updated = await Donasi.update(id, {
        status: status,
        petugas_id:
          status === "diverifikasi" || status === "diterima"
            ? req.user.id
            : donasi.petugas_id,
        penerima_id: final_penerima_id,
      });

      if (!updated) {
        return res.status(400).json({
          success: false,
          message: "Gagal mengubah status donasi",
        });
      }

      // Buat riwayat
      let aksi = status;
      if (status === "diverifikasi") aksi = "diverifikasi";
      else if (status === "diterima") aksi = "diterima";
      else if (status === "selesai") aksi = "selesai";
      else if (status === "dibatalkan") aksi = "dibatalkan";

      await RiwayatDonasi.create({
        donasi_id: id,
        user_id: req.user.id,
        aksi: aksi,
        keterangan: catatan || null,
      });

      // Simpan ke tabel verifikasi jika status diverifikasi
      if (status === "diverifikasi") {
        await Verifikasi.create({
          donasi_id: id,
          petugas_id: req.user.id,
          catatan: catatan || null,
          status_verifikasi: "disetujui",
        });

        // Buat notifikasi untuk donatur
        await Notifikasi.create({
          user_id: donasi.donatur_id,
          judul: "Donasi Diverifikasi",
          pesan: `Donasi Anda (${donasi.nama_barang}) telah diverifikasi oleh petugas`,
          tipe: "verifikasi",
        });
      }

      const updatedDonasi = await Donasi.findById(id);

      return res.status(200).json({
        success: true,
        message: `Donasi status berhasil diubah menjadi ${status}`,
        data: updatedDonasi,
      });
    } catch (error) {
      console.error("Update status error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  static async receiveDonasi(req, res) {
    try {
      const { id } = req.params;

      const donasi = await Donasi.findById(id);

      if (!donasi) {
        return res.status(404).json({
          success: false,
          message: "Donasi tidak ditemukan",
        });
      }

      if (donasi.status !== "diverifikasi") {
        return res.status(400).json({
          success: false,
          message: "Donasi hanya bisa diterima jika statusnya diverifikasi",
        });
      }

      const user_id = parseInt(req.user.id);
      console.log(`[receiveDonasi] Donation ID: ${id}`);
      console.log(
        `[receiveDonasi] User ID: ${user_id}, Status: ${donasi.status}`
      );

      const updated = await Donasi.update(id, {
        status: "diterima",
        penerima_id: user_id,
      });

      if (!updated) {
        return res.status(400).json({
          success: false,
          message: "Gagal menerima donasi",
        });
      }

      await RiwayatDonasi.create({
        donasi_id: id,
        user_id: req.user.id,
        aksi: "diterima",
      });

      // Buat notifikasi untuk donatur
      await Notifikasi.create({
        user_id: donasi.donatur_id,
        judul: "Donasi Diterima",
        pesan: `Donasi Anda (${donasi.nama_barang}) telah diterima`,
        tipe: "donasi",
      });

      const updatedDonasi = await Donasi.findById(id);

      return res.status(200).json({
        success: true,
        message: "Donasi berhasil diterima",
        data: updatedDonasi,
      });
    } catch (error) {
      console.error("Receive donasi error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  static async completeDonasi(req, res) {
    try {
      const { id } = req.params;

      const donasi = await Donasi.findById(id);

      if (!donasi) {
        return res.status(404).json({
          success: false,
          message: "Donasi tidak ditemukan",
        });
      }

      const updated = await Donasi.update(id, {
        status: "selesai",
      });

      if (!updated) {
        return res.status(400).json({
          success: false,
          message: "Gagal menyelesaikan donasi",
        });
      }

      await RiwayatDonasi.create({
        donasi_id: id,
        user_id: req.user.id,
        aksi: "selesai",
      });

      const updatedDonasi = await Donasi.findById(id);

      return res.status(200).json({
        success: true,
        message: "Donasi berhasil diselesaikan",
        data: updatedDonasi,
      });
    } catch (error) {
      console.error("Complete donasi error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  static async cancelDonasi(req, res) {
    try {
      const { id } = req.params;
      const { keterangan } = req.body;

      const donasi = await Donasi.findById(id);

      if (!donasi) {
        return res.status(404).json({
          success: false,
          message: "Donasi tidak ditemukan",
        });
      }

      // Hanya donatur atau petugas yang bisa cancel
      if (
        req.user.role !== "admin" &&
        req.user.role !== "petugas" &&
        donasi.donatur_id !== req.user.id
      ) {
        return res.status(403).json({
          success: false,
          message: "Anda tidak memiliki akses untuk membatalkan donasi ini",
        });
      }

      const updated = await Donasi.update(id, {
        status: "dibatalkan",
      });

      if (!updated) {
        return res.status(400).json({
          success: false,
          message: "Gagal membatalkan donasi",
        });
      }

      await RiwayatDonasi.create({
        donasi_id: id,
        user_id: req.user.id,
        aksi: "dibatalkan",
        keterangan: keterangan || null,
      });

      const updatedDonasi = await Donasi.findById(id);

      return res.status(200).json({
        success: true,
        message: "Donasi berhasil dibatalkan",
        data: updatedDonasi,
      });
    } catch (error) {
      console.error("Cancel donasi error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  static async deleteDonasi(req, res) {
    try {
      const { id } = req.params;

      const donasi = await Donasi.findById(id);

      if (!donasi) {
        return res.status(404).json({
          success: false,
          message: "Donasi tidak ditemukan",
        });
      }

      // Hanya donatur dan admin yang bisa delete
      if (req.user.role !== "admin" && donasi.donatur_id !== req.user.id) {
        return res.status(403).json({
          success: false,
          message: "Anda tidak memiliki akses untuk menghapus donasi ini",
        });
      }

      // Hanya bisa delete jika status menunggu atau dibatalkan
      if (donasi.status !== "menunggu" && donasi.status !== "dibatalkan") {
        return res.status(400).json({
          success: false,
          message:
            "Donasi hanya bisa dihapus jika statusnya menunggu atau dibatalkan",
        });
      }

      await LokasiDonasi.delete(id);
      const deleted = await Donasi.delete(id);

      if (!deleted) {
        return res.status(400).json({
          success: false,
          message: "Gagal menghapus donasi",
        });
      }

      return res.status(200).json({
        success: true,
        message: "Donasi berhasil dihapus",
      });
    } catch (error) {
      console.error("Delete donasi error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  // ==================== FITUR KONEKSI DONATUR-PENERIMA ====================

  // Donatur melihat daftar penerima yang membutuhkan
  static async getRecipientsList(req, res) {
    try {
      // Petugas dan admin bisa akses untuk pilih penerima saat verifikasi
      if (req.user.role !== "petugas" && req.user.role !== "admin") {
        return res.status(403).json({
          success: false,
          message: "Hanya petugas yang dapat melihat daftar penerima",
        });
      }

      const pool = require("../config/database");
      const [recipients] = await pool.query(`
        SELECT 
          u.id,
          u.nama,
          u.email,
          u.no_hp,
          u.alamat,
          COUNT(kp.id) as total_kebutuhan,
          SUM(CASE WHEN kp.status = 'aktif' THEN 1 ELSE 0 END) as kebutuhan_aktif
        FROM users u
        LEFT JOIN kebutuhan_penerima kp ON u.id = kp.penerima_id
        WHERE u.role = 'penerima' AND u.status = 'aktif'
        GROUP BY u.id
        ORDER BY kebutuhan_aktif DESC
      `);

      return res.status(200).json({
        success: true,
        message: "Daftar penerima berhasil diambil",
        data: recipients,
      });
    } catch (error) {
      console.error("Get recipients error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  // Penerima melihat donasi yang masuk untuk mereka (langsung dari donatur)
  static async getIncomingDonations(req, res) {
    try {
      if (req.user.role !== "penerima") {
        return res.status(403).json({
          success: false,
          message: "Hanya penerima yang dapat melihat donasi masuk",
        });
      }

      const pool = require("../config/database");
      const user_id = parseInt(req.user.id);

      console.log(
        `[getIncomingDonations] User ID: ${user_id}, Role: ${req.user.role}`
      );

      const [donations] = await pool.query(
        `
        SELECT 
          d.id,
          d.donatur_id,
          d.penerima_id,
          d.jenis_donasi,
          d.nama_barang,
          d.jumlah,
          d.deskripsi,
          d.status,
          d.foto_donasi,
          d.created_at,
          u.nama as donatur_nama,
          u.email as donatur_email,
          u.no_hp as donatur_hp,
          u.alamat as donatur_alamat,
          ld.latitude,
          ld.longitude,
          ld.alamat as lokasi_alamat
        FROM donasi d
        LEFT JOIN users u ON d.donatur_id = u.id
        LEFT JOIN lokasi_donasi ld ON d.id = ld.donasi_id
        WHERE d.penerima_id = ? AND d.status = 'diverifikasi'
        ORDER BY d.created_at DESC
      `,
        [user_id]
      );

      console.log(`[getIncomingDonations] Found ${donations.length} donations`);
      donations.forEach((d) =>
        console.log(
          `  - Donation ID: ${d.id}, Status: ${d.status}, Penerima: ${d.penerima_id}`
        )
      );

      return res.status(200).json({
        success: true,
        message: "Donasi masuk berhasil diambil",
        data: donations,
      });
    } catch (error) {
      console.error("Get incoming donations error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  // Penerima melihat donasi yang sudah diverifikasi dan siap diterima
  static async getAvailableDonations(req, res) {
    try {
      if (req.user.role !== "penerima") {
        return res.status(403).json({
          success: false,
          message: "Hanya penerima yang dapat melihat donasi tersedia",
        });
      }

      const pool = require("../config/database");
      const user_id = parseInt(req.user.id);

      console.log(
        `[getAvailableDonations] User ID: ${user_id}, Role: ${req.user.role}`
      );

      // Donasi yang sudah diverifikasi tapi belum ada penerima atau sudah di-assign ke user ini
      const [donations] = await pool.query(
        `
        SELECT 
          d.id,
          d.donatur_id,
          d.penerima_id,
          d.jenis_donasi,
          d.nama_barang,
          d.jumlah,
          d.deskripsi,
          d.status,
          d.foto_donasi,
          d.created_at,
          u.nama as donatur_nama,
          u.email as donatur_email,
          u.no_hp as donatur_hp,
          u.alamat as donatur_alamat,
          ld.latitude,
          ld.longitude,
          ld.alamat as lokasi_alamat
        FROM donasi d
        LEFT JOIN users u ON d.donatur_id = u.id
        LEFT JOIN lokasi_donasi ld ON d.id = ld.donasi_id
        WHERE d.status = 'diverifikasi' AND (d.penerima_id IS NULL OR d.penerima_id = ?)
        ORDER BY d.created_at DESC
      `,
        [user_id]
      );

      console.log(
        `[getAvailableDonations] Found ${donations.length} available donations`
      );
      donations.forEach((d) =>
        console.log(
          `  - Donation ID: ${d.id}, Status: ${d.status}, Penerima: ${d.penerima_id}, Donatur: ${d.donatur_id}`
        )
      );

      return res.status(200).json({
        success: true,
        message: "Donasi yang tersedia berhasil diambil",
        data: donations,
      });
    } catch (error) {
      console.error("Get available donations error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  // Donatur mendonasikan langsung ke penerima (BYPASS verifikasi)
  static async donateDirectly(req, res) {
    try {
      const { penerima_id, jenis_donasi, nama_barang, jumlah, deskripsi } =
        req.body;
      const { latitude, longitude, alamat } = req.body;

      // Validasi input
      if (!penerima_id || !jenis_donasi || !nama_barang || !jumlah) {
        return res.status(400).json({
          success: false,
          message:
            "Penerima, jenis donasi, nama barang, dan jumlah harus diisi",
        });
      }

      if (!latitude || !longitude) {
        return res.status(400).json({
          success: false,
          message: "Lokasi (latitude dan longitude) harus diisi",
        });
      }

      // Cek penerima ada atau tidak
      const penerima = await User.findById(penerima_id);
      if (!penerima || penerima.role !== "penerima") {
        return res.status(404).json({
          success: false,
          message: "Penerima tidak ditemukan",
        });
      }

      // Get foto path dari multer jika file di-upload
      const fotoPath = req.file ? `/uploads/donasi/${req.file.filename}` : null;

      // Normalize jenis_donasi
      let normalizedJenisDonasi = jenis_donasi.toLowerCase();
      if (
        normalizedJenisDonasi.includes("makanan") ||
        normalizedJenisDonasi.includes("buku")
      ) {
        normalizedJenisDonasi = "makanan";
      } else {
        normalizedJenisDonasi = "barang";
      }

      // Buat donasi LANGSUNG DIVERIFIKASI (skip waiting verification)
      const donasiId = await Donasi.create({
        donatur_id: req.user.id,
        jenis_donasi: normalizedJenisDonasi,
        nama_barang,
        jumlah: parseInt(jumlah),
        deskripsi: deskripsi || null,
        foto_donasi: fotoPath || null,
      });

      // Set penerima_id langsung
      await Donasi.update(donasiId, {
        penerima_id: penerima_id,
        status: "diverifikasi", // Langsung diverifikasi karena direct
      });

      // Buat lokasi donasi
      await LokasiDonasi.create({
        donasi_id: donasiId,
        latitude: parseFloat(latitude),
        longitude: parseFloat(longitude),
        alamat: alamat || null,
      });

      // Buat riwayat donasi
      await RiwayatDonasi.create({
        donasi_id: donasiId,
        user_id: req.user.id,
        aksi: "dibuat",
        keterangan: "Donasi langsung ke penerima (verified)",
      });

      // Notifikasi ke penerima - ada donasi masuk
      await Notifikasi.create({
        user_id: penerima_id,
        judul: "Donasi Masuk",
        pesan: `Anda menerima donasi "${nama_barang}" (${jumlah}) dari ${
          req.user.nama || "Donatur"
        }`,
        tipe: "donasi",
      });

      // Notifikasi ke SEMUA PETUGAS - ada donasi langsung masuk
      const petugas = await User.getAll("petugas");
      if (petugas && petugas.length > 0) {
        for (let p of petugas) {
          await Notifikasi.create({
            user_id: p.id,
            judul: "Donasi Langsung Masuk",
            pesan: `Donasi "${nama_barang}" (${jumlah}) dari ${
              req.user.nama || "Donatur"
            } ke ${penerima.nama} - Status: Diverifikasi`,
            tipe: "donasi",
          });
        }
      }

      const donasi = await Donasi.findById(donasiId);

      return res.status(201).json({
        success: true,
        message: "Donasi langsung berhasil dikirim ke penerima",
        data: donasi,
      });
    } catch (error) {
      console.error("Donate directly error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  // Penerima menerima donasi langsung
  static async acceptDirectDonation(req, res) {
    try {
      const { id } = req.params;
      const { keterangan } = req.body;

      // Handle file upload (foto bukti terima)
      const fotoBuktiPath = req.file
        ? `/uploads/donasi/${req.file.filename}`
        : null;

      const donasi = await Donasi.findById(id);

      if (!donasi) {
        return res.status(404).json({
          success: false,
          message: "Donasi tidak ditemukan",
        });
      }

      // Cek apakah penerima sesuai - allow jika belum ada penerima atau jika sama
      // Convert ke number untuk menghindari type mismatch (string vs int)
      const raw_penerima_id = donasi.penerima_id;
      const penerima_id = raw_penerima_id ? parseInt(raw_penerima_id) : null;
      const user_id = parseInt(req.user.id);

      console.log(`[acceptDirectDonation] Donation ID: ${id}`);
      console.log(
        `[acceptDirectDonation] Raw Penerima ID di DB: ${raw_penerima_id} (type: ${typeof raw_penerima_id})`
      );
      console.log(
        `[acceptDirectDonation] Parsed Penerima ID: ${penerima_id} (type: ${typeof penerima_id})`
      );
      console.log(
        `[acceptDirectDonation] User ID: ${user_id} (type: ${typeof user_id})`
      );
      console.log(`[acceptDirectDonation] Status: ${donasi.status}`);
      console.log(
        `[acceptDirectDonation] File uploaded: ${fotoBuktiPath || "None"}`
      );

      // Cek status donasi DULU - harus diverifikasi atau lebih tinggi
      if (donasi.status !== "diverifikasi") {
        return res.status(400).json({
          success: false,
          message:
            "Donasi hanya bisa diterima jika statusnya telah diverifikasi oleh petugas",
        });
      }

      // Jika sudah ada penerima_id dan tidak cocok dengan user saat ini, tolak
      if (penerima_id !== null && penerima_id !== user_id) {
        console.log(
          `[acceptDirectDonation] Access denied! Expected ${penerima_id}, got ${user_id}`
        );
        return res.status(403).json({
          success: false,
          message: "Anda tidak memiliki akses untuk donasi ini",
        });
      }

      // Update status menjadi diterima, set penerima_id, dan simpan foto bukti
      const updateData = {
        status: "diterima",
        penerima_id: user_id,
      };

      // Jika ada file foto, simpan path-nya
      if (fotoBuktiPath) {
        updateData.foto_bukti_terima = fotoBuktiPath;
      }

      const updated = await Donasi.update(id, updateData);

      if (!updated) {
        return res.status(400).json({
          success: false,
          message: "Gagal menerima donasi",
        });
      }

      // Buat riwayat
      await RiwayatDonasi.create({
        donasi_id: id,
        user_id: req.user.id,
        aksi: "diterima",
        keterangan: keterangan || "Penerima menerima donasi langsung",
      });

      // Notifikasi ke donatur
      await Notifikasi.create({
        user_id: donasi.donatur_id,
        judul: "Donasi Diterima",
        pesan: `Donasi "${donasi.nama_barang}" Anda telah diterima oleh ${
          req.user.nama || "Penerima"
        }`,
        tipe: "donasi",
      });

      const updatedDonasi = await Donasi.findById(id);

      return res.status(200).json({
        success: true,
        message: "Donasi berhasil diterima",
        data: updatedDonasi,
      });
    } catch (error) {
      console.error("Accept direct donation error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  // Penerima menolak donasi langsung
  static async rejectDirectDonation(req, res) {
    try {
      const { id } = req.params;
      const { keterangan } = req.body;

      const donasi = await Donasi.findById(id);

      if (!donasi) {
        return res.status(404).json({
          success: false,
          message: "Donasi tidak ditemukan",
        });
      }

      // Cek apakah penerima sesuai - allow jika belum ada penerima atau jika sama
      // Convert ke number untuk menghindari type mismatch (string vs int)
      const raw_penerima_id = donasi.penerima_id;
      const penerima_id = raw_penerima_id ? parseInt(raw_penerima_id) : null;
      const user_id = parseInt(req.user.id);

      console.log(`[rejectDirectDonation] Donation ID: ${id}`);
      console.log(
        `[rejectDirectDonation] Raw Penerima ID di DB: ${raw_penerima_id} (type: ${typeof raw_penerima_id})`
      );
      console.log(
        `[rejectDirectDonation] Parsed Penerima ID: ${penerima_id} (type: ${typeof penerima_id})`
      );
      console.log(
        `[rejectDirectDonation] User ID: ${user_id} (type: ${typeof user_id})`
      );
      console.log(`[rejectDirectDonation] Status: ${donasi.status}`);

      // Jika sudah ada penerima_id dan tidak cocok dengan user saat ini, tolak
      if (penerima_id !== null && penerima_id !== user_id) {
        console.log(
          `[rejectDirectDonation] Access denied! Expected ${penerima_id}, got ${user_id}`
        );
        return res.status(403).json({
          success: false,
          message: "Anda tidak memiliki akses untuk donasi ini",
        });
      }

      // Cek status donasi harus diverifikasi atau lebih tinggi
      if (donasi.status !== "diverifikasi") {
        return res.status(400).json({
          success: false,
          message:
            "Donasi hanya bisa ditolak jika statusnya telah diverifikasi oleh petugas",
        });
      }

      // Update status menjadi dibatalkan dan set penerima_id jika belum ada
      const updated = await Donasi.update(id, {
        status: "dibatalkan",
        penerima_id: user_id,
      });

      if (!updated) {
        return res.status(400).json({
          success: false,
          message: "Gagal menolak donasi",
        });
      }

      // Buat riwayat
      await RiwayatDonasi.create({
        donasi_id: id,
        user_id: req.user.id,
        aksi: "dibatalkan",
        keterangan: keterangan || "Penerima menolak donasi langsung",
      });

      // Notifikasi ke donatur
      await Notifikasi.create({
        user_id: donasi.donatur_id,
        judul: "Donasi Ditolak",
        pesan: `Donasi "${donasi.nama_barang}" Anda ditolak oleh ${
          req.user.nama || "Penerima"
        }. Alasan: ${keterangan || "Tidak ada alasan diberikan"}`,
        tipe: "donasi",
      });

      const updatedDonasi = await Donasi.findById(id);

      return res.status(200).json({
        success: true,
        message: "Donasi berhasil ditolak",
        data: updatedDonasi,
      });
    } catch (error) {
      console.error("Reject direct donation error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  // Lihat history donasi dengan penerima tertentu (untuk chat/komunikasi)
  static async getDirectDonationHistory(req, res) {
    try {
      const { penerima_id } = req.params;

      const pool = require("../config/database");

      // Cek apakah user adalah donatur atau penerima untuk donasi ini
      const [donations] = await pool.query(
        `
        SELECT 
          d.id,
          d.donatur_id,
          d.penerima_id,
          d.jenis_donasi,
          d.nama_barang,
          d.jumlah,
          d.deskripsi,
          d.status,
          d.foto_donasi,
          d.created_at,
          d.updated_at,
          u_donatur.nama as donatur_nama,
          u_donatur.email as donatur_email,
          u_donatur.no_hp as donatur_hp,
          u_penerima.nama as penerima_nama,
          u_penerima.email as penerima_email,
          u_penerima.no_hp as penerima_hp
        FROM donasi d
        LEFT JOIN users u_donatur ON d.donatur_id = u_donatur.id
        LEFT JOIN users u_penerima ON d.penerima_id = u_penerima.id
        WHERE d.penerima_id = ? AND d.donatur_id = ?
        ORDER BY d.created_at DESC
      `,
        [penerima_id, req.user.id]
      );

      return res.status(200).json({
        success: true,
        message: "History donasi berhasil diambil",
        data: donations,
      });
    } catch (error) {
      console.error("Get direct donation history error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  // ==================== FITUR KONEKSI VIA KEBUTUHAN ====================

  // Donatur melihat SEMUA kebutuhan penerima yang masih aktif
  static async getActiveNeeds(req, res) {
    try {
      if (req.user.role !== "donatur") {
        return res.status(403).json({
          success: false,
          message: "Hanya donatur yang dapat melihat kebutuhan",
        });
      }

      const pool = require("../config/database");
      const [needs] = await pool.query(`
        SELECT 
          kp.id as kebutuhan_id,
          kp.penerima_id,
          kp.jenis_kebutuhan,
          kp.deskripsi,
          kp.jumlah,
          kp.status,
          kp.foto_kebutuhan,
          kp.created_at,
          u.id as penerima_id,
          u.nama as penerima_nama,
          u.email as penerima_email,
          u.no_hp as penerima_hp,
          u.alamat as penerima_alamat,
          COUNT(d.id) as total_donasi_masuk
        FROM kebutuhan_penerima kp
        LEFT JOIN users u ON kp.penerima_id = u.id
        LEFT JOIN donasi d ON kp.penerima_id = d.penerima_id AND d.status != 'dibatalkan'
        WHERE kp.status = 'aktif' AND u.status = 'aktif'
        GROUP BY kp.id
        ORDER BY kp.created_at DESC
      `);

      return res.status(200).json({
        success: true,
        message: "Daftar kebutuhan aktif berhasil diambil",
        data: needs,
      });
    } catch (error) {
      console.error("Get active needs error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  // Donatur melihat kebutuhan spesifik dari penerima tertentu
  static async getRecipientNeeds(req, res) {
    try {
      if (req.user.role !== "donatur") {
        return res.status(403).json({
          success: false,
          message: "Hanya donatur yang dapat melihat kebutuhan",
        });
      }

      const { penerima_id } = req.params;
      const pool = require("../config/database");

      const [needs] = await pool.query(
        `
        SELECT 
          kp.id as kebutuhan_id,
          kp.penerima_id,
          kp.jenis_kebutuhan,
          kp.deskripsi,
          kp.jumlah,
          kp.status,
          kp.foto_kebutuhan,
          kp.created_at,
          u.nama as penerima_nama,
          u.email as penerima_email,
          u.no_hp as penerima_hp,
          u.alamat as penerima_alamat,
          COUNT(d.id) as total_donasi_masuk
        FROM kebutuhan_penerima kp
        LEFT JOIN users u ON kp.penerima_id = u.id
        LEFT JOIN donasi d ON kp.penerima_id = d.penerima_id AND d.status != 'dibatalkan'
        WHERE kp.penerima_id = ? AND u.status = 'aktif'
        GROUP BY kp.id
        ORDER BY kp.created_at DESC
      `,
        [penerima_id]
      );

      return res.status(200).json({
        success: true,
        message: "Kebutuhan penerima berhasil diambil",
        data: needs,
      });
    } catch (error) {
      console.error("Get recipient needs error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  // Donatur DONASIKAN LANGSUNG ke KEBUTUHAN tertentu
  static async donateToNeed(req, res) {
    try {
      const { kebutuhan_id, jenis_donasi, nama_barang, jumlah, deskripsi } =
        req.body;
      const { latitude, longitude, alamat } = req.body;

      // Validasi input
      if (!kebutuhan_id || !jenis_donasi || !nama_barang || !jumlah) {
        return res.status(400).json({
          success: false,
          message:
            "Kebutuhan ID, jenis donasi, nama barang, dan jumlah harus diisi",
        });
      }

      if (!latitude || !longitude) {
        return res.status(400).json({
          success: false,
          message: "Lokasi (latitude dan longitude) harus diisi",
        });
      }

      const pool = require("../config/database");
      const KebutuhanPenerima = require("../models/KebutuhanPenerima");

      // Cek kebutuhan ada atau tidak
      const kebutuhan = await KebutuhanPenerima.findById(kebutuhan_id);
      if (!kebutuhan) {
        return res.status(404).json({
          success: false,
          message: "Kebutuhan tidak ditemukan",
        });
      }

      // Cek penerima ada atau tidak
      const penerima = await User.findById(kebutuhan.penerima_id);
      if (!penerima || penerima.role !== "penerima") {
        return res.status(404).json({
          success: false,
          message: "Penerima tidak ditemukan",
        });
      }

      // Get foto path dari multer jika file di-upload
      const fotoPath = req.file ? `/uploads/donasi/${req.file.filename}` : null;

      // Normalize jenis_donasi
      let normalizedJenisDonasi = jenis_donasi.toLowerCase();
      if (
        normalizedJenisDonasi.includes("makanan") ||
        normalizedJenisDonasi.includes("buku")
      ) {
        normalizedJenisDonasi = "makanan";
      } else {
        normalizedJenisDonasi = "barang";
      }

      // Buat donasi LANGSUNG DIVERIFIKASI
      const donasiId = await Donasi.create({
        donatur_id: req.user.id,
        jenis_donasi: normalizedJenisDonasi,
        nama_barang,
        jumlah: parseInt(jumlah),
        deskripsi: deskripsi || null,
        foto_donasi: fotoPath || null,
      });

      // Set penerima_id langsung dari kebutuhan
      await Donasi.update(donasiId, {
        penerima_id: kebutuhan.penerima_id,
        status: "diverifikasi", // Langsung diverifikasi
      });

      // Buat lokasi donasi
      await LokasiDonasi.create({
        donasi_id: donasiId,
        latitude: parseFloat(latitude),
        longitude: parseFloat(longitude),
        alamat: alamat || null,
      });

      // Buat riwayat donasi
      await RiwayatDonasi.create({
        donasi_id: donasiId,
        user_id: req.user.id,
        aksi: "dibuat",
        keterangan: `Donasi untuk kebutuhan: ${kebutuhan.jenis_kebutuhan}`,
      });

      // Notifikasi ke penerima - ada donasi masuk
      await Notifikasi.create({
        user_id: kebutuhan.penerima_id,
        judul: "Donasi Masuk untuk Kebutuhan Anda",
        pesan: `Anda menerima donasi "${nama_barang}" (${jumlah}) dari ${
          req.user.nama || "Donatur"
        } untuk kebutuhan ${kebutuhan.jenis_kebutuhan}`,
        tipe: "donasi",
      });

      const donasi = await Donasi.findById(donasiId);

      return res.status(201).json({
        success: true,
        message: "Donasi untuk kebutuhan berhasil dikirim",
        data: {
          ...donasi,
          kebutuhan_id: kebutuhan_id,
          kebutuhan_jenis: kebutuhan.jenis_kebutuhan,
        },
      });
    } catch (error) {
      console.error("Donate to need error:", error);
      return res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada server",
        error: error.message,
      });
    }
  }

  // ==================== END FITUR KONEKSI ====================
}

module.exports = DonasiController;
