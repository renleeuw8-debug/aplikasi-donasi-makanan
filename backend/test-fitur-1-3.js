#!/usr/bin/env node
/**
 * Test Script untuk Fitur 1 (Bukti Terima Foto) dan Fitur 3 (Nama Panti Asuhan)
 */

const axios = require("axios");
const fs = require("fs");
const FormData = require("form-data");
const path = require("path");

const API_URL = "http://192.168.100.9:3000/api";

// Test user credentials
const testUsers = {
  donatur: {
    email: "rully@gmail.com",
    password: "password123",
  },
  penerima: {
    email: "putri@gmail.com",
    password: "password123",
  },
};

let tokens = {};

// Helper untuk membuat file dummy untuk testing
function createDummyImage() {
  const imagePath = path.join(__dirname, "test-bukti.jpg");

  // Buat file JPG dummy sederhana (1x1 pixel red JPG)
  const jpgBuffer = Buffer.from([
    0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46, 0x00, 0x01,
    0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xff, 0xdb, 0x00, 0x43,
    0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
    0x09, 0x08, 0x0a, 0x0c, 0x14, 0x0d, 0x0c, 0x0b, 0x0b, 0x0c, 0x19, 0x12,
    0x13, 0x0f, 0x14, 0x1d, 0x1a, 0x1f, 0x1e, 0x1d, 0x1a, 0x1c, 0x1c, 0x20,
    0x24, 0x2e, 0x27, 0x20, 0x22, 0x2c, 0x23, 0x1c, 0x1c, 0x28, 0x37, 0x29,
    0x2c, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1f, 0x27, 0x39, 0x3d, 0x38, 0x32,
    0x3c, 0x2e, 0x33, 0x34, 0x32, 0xff, 0xc0, 0x00, 0x0b, 0x08, 0x00, 0x01,
    0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xff, 0xc4, 0x00, 0x1f, 0x00, 0x00,
    0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
    0x09, 0x0a, 0x0b, 0xff, 0xc4, 0x00, 0xb5, 0x10, 0x00, 0x02, 0x01, 0x03,
    0x03, 0x02, 0x04, 0x03, 0x05, 0x05, 0x04, 0x04, 0x00, 0x00, 0x01, 0x7d,
    0x01, 0x02, 0x03, 0x00, 0x04, 0x11, 0x05, 0x12, 0x21, 0x31, 0x41, 0x06,
    0x13, 0x51, 0x61, 0x07, 0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xa1, 0x08,
    0x23, 0x42, 0xb1, 0xc1, 0x15, 0x52, 0xd1, 0xf0, 0x24, 0x33, 0x62, 0x72,
    0x82, 0x09, 0x0a, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x25, 0x26, 0x27, 0x28,
    0x29, 0x2a, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x43, 0x44, 0x45,
    0x46, 0x47, 0x48, 0x49, 0x4a, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59,
    0x5a, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x73, 0x74, 0x75,
    0x76, 0x77, 0x78, 0x79, 0x7a, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89,
    0x8a, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0xa2, 0xa3,
    0xa4, 0xa5, 0xa6, 0xa7, 0xa8, 0xa9, 0xaa, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6,
    0xb7, 0xb8, 0xb9, 0xba, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9,
    0xca, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xe1, 0xe2,
    0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xf1, 0xf2, 0xf3, 0xf4,
    0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa, 0xff, 0xda, 0x00, 0x08, 0x01, 0x01,
    0x00, 0x00, 0x3f, 0x00, 0xfb, 0xd2, 0x8a, 0x28, 0xa0, 0x0f, 0xff, 0xd9,
  ]);

  fs.writeFileSync(imagePath, jpgBuffer);
  return imagePath;
}

// Test functions
async function login(role) {
  try {
    console.log(`\n📝 Logging in sebagai ${role}...`);
    const user = testUsers[role];

    const response = await axios.post(`${API_URL}/auth/login`, {
      email: user.email,
      password: user.password,
    });

    if (response.data.success) {
      tokens[role] = response.data.token;
      console.log(`✅ Login berhasil untuk ${role}`);
      console.log(`   Token: ${response.data.token.substring(0, 20)}...`);
      return response.data;
    } else {
      console.log(`❌ Login gagal: ${response.data.message}`);
      return null;
    }
  } catch (error) {
    console.error(`❌ Error login:`, error.response?.data || error.message);
    return null;
  }
}

async function testRegisterWithPantiName() {
  try {
    console.log(`\n🏥 Testing Fitur 3: Register dengan Nama Panti Asuhan...`);

    const newPenerima = {
      nama: "Tes Panti Asuhan " + Date.now(),
      email: `panti-${Date.now()}@test.com`,
      password: "password123",
      password_confirm: "password123",
      no_hp: "08123456789",
      alamat: "Jl. Panti Asuhan No. 1",
      role: "penerima",
      latitude: "-6.2088",
      longitude: "106.8456",
      nama_panti_asuhan: "Panti Asuhan Bahagia " + Date.now(),
    };

    const response = await axios.post(`${API_URL}/auth/register`, newPenerima);

    if (response.data.success) {
      console.log(`✅ Register dengan nama panti berhasil`);
      console.log(`   User ID: ${response.data.user_id}`);
      console.log(`   Nama Panti: ${newPenerima.nama_panti_asuhan}`);
      return response.data;
    } else {
      console.log(`❌ Register gagal: ${response.data.message}`);
      return null;
    }
  } catch (error) {
    console.error(`❌ Error register:`, error.response?.data || error.message);
    return null;
  }
}

async function testAcceptDonationWithPhoto() {
  try {
    console.log(`\n📸 Testing Fitur 1: Accept Donasi dengan Foto Bukti...`);

    if (!tokens.penerima) {
      console.log("❌ Token penerima tidak tersedia, skip test");
      return null;
    }

    // Buat dummy image
    const imagePath = createDummyImage();
    console.log(`✓ File foto test dibuat: ${imagePath}`);

    // Ambil donasi yang tersedia untuk penerima
    console.log(`   Mengambil daftar donasi yang tersedia...`);
    const donasiResponse = await axios.get(
      `${API_URL}/donasi/penerima/available`,
      {
        headers: { Authorization: `Bearer ${tokens.penerima}` },
      }
    );

    if (!donasiResponse.data.success || donasiResponse.data.data.length === 0) {
      console.log("❌ Tidak ada donasi yang tersedia untuk diterima");
      fs.unlinkSync(imagePath);
      return null;
    }

    const donasiToAccept = donasiResponse.data.data[0];
    console.log(
      `   Donasi ditemukan: ID=${donasiToAccept.id}, Barang=${donasiToAccept.nama_barang}`
    );

    // Accept donasi dengan file upload
    const form = new FormData();
    form.append("foto_bukti_terima", fs.createReadStream(imagePath));
    form.append("keterangan", "Sudah diterima dengan baik");

    const acceptResponse = await axios.post(
      `${API_URL}/donasi/${donasiToAccept.id}/accept-direct`,
      form,
      {
        headers: {
          ...form.getHeaders(),
          Authorization: `Bearer ${tokens.penerima}`,
        },
      }
    );

    if (acceptResponse.data.success) {
      console.log(`✅ Accept donasi dengan foto berhasil`);
      console.log(`   Donasi ID: ${donasiToAccept.id}`);
      console.log(`   Status diubah menjadi: diterima`);
      console.log(`   Foto bukti tersimpan`);
      fs.unlinkSync(imagePath);
      return acceptResponse.data;
    } else {
      console.log(`❌ Accept donasi gagal: ${acceptResponse.data.message}`);
      fs.unlinkSync(imagePath);
      return null;
    }
  } catch (error) {
    console.error(
      `❌ Error accept donasi:`,
      error.response?.data || error.message
    );
    return null;
  }
}

async function runTests() {
  console.log("=".repeat(60));
  console.log("TEST FITUR 1 & 3 - BACKEND IMPLEMENTATION");
  console.log("=".repeat(60));

  // Login test users
  await login("donatur");
  await login("penerima");

  // Test Fitur 3
  await testRegisterWithPantiName();

  // Test Fitur 1
  await testAcceptDonationWithPhoto();

  console.log("\n" + "=".repeat(60));
  console.log("✅ Semua test selesai!");
  console.log("=".repeat(60));
}

// Run tests
runTests().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
