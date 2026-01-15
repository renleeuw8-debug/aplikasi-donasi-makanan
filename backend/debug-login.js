require("dotenv").config();
const http = require("http");

console.log("🔍 Debug Login Test\n");

// Check environment variables
console.log("📋 Environment Variables:");
console.log(
  `   JWT_SECRET: ${process.env.JWT_SECRET ? "✅ Ada" : "❌ Tidak ada"}`
);
console.log(`   DB_HOST: ${process.env.DB_HOST}`);
console.log(`   DB_NAME: ${process.env.DB_NAME}`);
console.log(`   PORT: ${process.env.PORT}\n`);

// Test login request
const postData = JSON.stringify({
  email: "petugas@gmail.com",
  password: "password123",
});

const options = {
  hostname: "localhost",
  port: 3000,
  path: "/api/auth/login",
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "Content-Length": Buffer.byteLength(postData),
  },
};

console.log("🔄 Mengirim request login...\n");

const req = http.request(options, (res) => {
  let data = "";

  res.on("data", (chunk) => {
    data += chunk;
  });

  res.on("end", () => {
    console.log(`📊 Response Status: ${res.statusCode}`);
    console.log("📝 Response Body:\n");
    try {
      const json = JSON.parse(data);
      console.log(JSON.stringify(json, null, 2));
    } catch (e) {
      console.log(data);
    }
  });
});

req.on("error", (error) => {
  console.error("❌ Request Error:", error.message);
  console.error("\n💡 Tips:");
  console.error("   - Apakah server sudah running di port 3000?");
  console.error("   - Jalankan: npm start atau npm run dev");
});

req.write(postData);
req.end();
