#!/usr/bin/env node

/**
 * Quick API Test menggunakan curl
 */

const { exec } = require("child_process");
const util = require("util");
const execPromise = util.promisify(exec);

const BASE_URL = "http://localhost:3000/api";

async function test() {
  console.log("\n=== TESTING BACKEND API ===\n");

  try {
    // Test 1: Login
    console.log("1. Testing login endpoint...");
    const loginCmd = `curl -s -X POST ${BASE_URL}/auth/login -H "Content-Type: application/json" -d "{\"email\":\"petugas@gmail.com\",\"password\":\"petugas123\"}"`;
    const { stdout: loginOut } = await execPromise(loginCmd);
    const loginData = JSON.parse(loginOut);

    if (loginData.success && loginData.token) {
      console.log("   ✅ Login berhasil");
      console.log(`   Token: ${loginData.token.substring(0, 30)}...`);

      // Test 2: Get donasi dengan token
      console.log("\n2. Testing get donasi endpoint...");
      const donasiCmd = `curl -s -X GET ${BASE_URL}/donasi -H "Authorization: Bearer ${loginData.token}"`;
      const { stdout: donasiOut } = await execPromise(donasiCmd);
      const donasiData = JSON.parse(donasiOut);

      if (donasiData.success) {
        console.log("   ✅ Get donasi berhasil");
        console.log(`   Total donasi: ${donasiData.data.length}`);
      } else {
        console.log("   ❌ Get donasi gagal:", donasiData.message);
      }

      // Test 3: Get profile
      console.log("\n3. Testing get profile endpoint...");
      const profileCmd = `curl -s -X GET ${BASE_URL}/auth/profile -H "Authorization: Bearer ${loginData.token}"`;
      const { stdout: profileOut } = await execPromise(profileCmd);
      const profileData = JSON.parse(profileOut);

      if (profileData.data) {
        console.log("   ✅ Get profile berhasil");
        console.log(
          `   User: ${profileData.data.nama} (${profileData.data.role})`
        );
      } else {
        console.log("   ❌ Get profile gagal");
      }
    } else {
      console.log("   ❌ Login gagal:", loginData.message);
    }

    console.log("\n✅ Basic API test completed\n");
  } catch (error) {
    console.error("❌ Error:", error.message);
    process.exit(1);
  }
}

test();
