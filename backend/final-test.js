#!/usr/bin/env node

/**
 * API Test menggunakan native fetch
 */

const BASE_URL = "http://localhost:3000/api";

async function test() {
  console.log("\n=== BACKEND API TEST ===\n");

  try {
    // Test 1: Login
    console.log("1️⃣  Login test...");
    const loginRes = await fetch(`${BASE_URL}/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        email: "petugas@gmail.com",
        password: "petugas123",
      }),
    });

    const loginData = await loginRes.json();

    if (!loginRes.ok) {
      throw new Error(`Login gagal: ${loginData.message}`);
    }

    console.log("   ✅ Login berhasil");
    console.log(`   Name: ${loginData.user.nama}`);
    console.log(`   Role: ${loginData.user.role}`);

    const token = loginData.token;

    // Test 2: Get all donasi
    console.log("\n2️⃣  Get all donasi...");
    const donasiRes = await fetch(`${BASE_URL}/donasi`, {
      headers: { Authorization: `Bearer ${token}` },
    });

    const donasiData = await donasiRes.json();
    if (!donasiRes.ok) {
      throw new Error(`Get donasi gagal: ${donasiData.message}`);
    }

    console.log("   ✅ Get donasi berhasil");
    console.log(`   Total: ${donasiData.data.length}`);

    // Test 3: Get profile
    console.log("\n3️⃣  Get profile...");
    const profileRes = await fetch(`${BASE_URL}/auth/profile`, {
      headers: { Authorization: `Bearer ${token}` },
    });

    const profileData = await profileRes.json();
    if (!profileRes.ok) {
      throw new Error(`Get profile gagal`);
    }

    console.log("   ✅ Get profile berhasil");
    console.log(`   Email: ${profileData.data.email}`);
    console.log(`   Phone: ${profileData.data.no_hp}`);

    // Test 4: Get notifikasi
    console.log("\n4️⃣  Get notifikasi...");
    const notifRes = await fetch(`${BASE_URL}/notifikasi`, {
      headers: { Authorization: `Bearer ${token}` },
    });

    const notifData = await notifRes.json();
    if (!notifRes.ok) {
      throw new Error(`Get notifikasi gagal`);
    }

    console.log("   ✅ Get notifikasi berhasil");
    console.log(`   Total: ${notifData.data.length}`);

    console.log("\n" + "=".repeat(40));
    console.log("✅ SEMUA TEST PASSED - READY TO RILOT");
    console.log("=".repeat(40) + "\n");
  } catch (error) {
    console.error("\n❌ TEST FAILED:", error.message, "\n");
    process.exit(1);
  }
}

test();
