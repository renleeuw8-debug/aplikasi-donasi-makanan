const http = require("http");

console.log("=== TEST ENDPOINT PETUGAS ===\n");

// Login petugas
console.log("Login Petugas...");
const loginData = JSON.stringify({
  email: "petugas@gmail.com",
  password: "petugas123",
});

const loginReq = http.request(
  {
    hostname: "localhost",
    port: 3000,
    path: "/api/auth/login",
    method: "POST",
    headers: { "Content-Type": "application/json" },
  },
  (res) => {
    let data = "";
    res.on("data", (chunk) => {
      data += chunk;
    });
    res.on("end", () => {
      const result = JSON.parse(data);
      const token = result.token;
      console.log("✅ Login berhasil\n");

      // Test endpoint
      console.log("Cek donasi menunggu verifikasi...");
      const req = http.request(
        {
          hostname: "localhost",
          port: 3000,
          path: "/api/donasi/verify/menunggu",
          method: "GET",
          headers: { Authorization: `Bearer ${token}` },
        },
        (res) => {
          let data = "";
          res.on("data", (chunk) => {
            data += chunk;
          });
          res.on("end", () => {
            console.log("HTTP Status:", res.statusCode);
            try {
              const result = JSON.parse(data);
              console.log("Response:", JSON.stringify(result, null, 2));
            } catch (e) {
              console.log("Raw:", data);
            }
          });
        }
      );
      req.end();
    });
  }
);

loginReq.write(loginData);
loginReq.end();
