const http = require("http");

// Token dari petugas yang sudah login di Flutter
// Ambil dari Flutter console atau generate baru
const token =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwibmFtYSI6IlBldHVnYXMgVGVzdCIsImVtYWlsIjoicGV0dWdhc0Bkb25hc2kuY29tIiwicm9sZSI6InBldHVnYXMiLCJpYXQiOjE3MzY1Mzc2MDAsImV4cCI6MTczNzE0MjQwMH0.test";

const options = {
  hostname: "localhost",
  port: 3000,
  path: "/api/donasi/verify/menunggu",
  method: "GET",
  headers: {
    Authorization: `Bearer ${token}`,
    "Content-Type": "application/json",
  },
};

const req = http.request(options, (res) => {
  let data = "";
  res.on("data", (chunk) => {
    data += chunk;
  });
  res.on("end", () => {
    console.log("=== /api/donasi/verify/menunggu ===");
    console.log("Status:", res.statusCode);
    try {
      console.log(JSON.stringify(JSON.parse(data), null, 2));
    } catch (e) {
      console.log(data);
    }
    testDisverifikasi();
  });
});

req.on("error", (error) => {
  console.error("Error:", error);
});

req.end();

function testDisverifikasi() {
  const options2 = {
    hostname: "localhost",
    port: 3000,
    path: "/api/donasi/verify/diverifikasi",
    method: "GET",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
  };

  const req2 = http.request(options2, (res) => {
    let data = "";
    res.on("data", (chunk) => {
      data += chunk;
    });
    res.on("end", () => {
      console.log("\n=== /api/donasi/verify/diverifikasi ===");
      console.log("Status:", res.statusCode);
      try {
        console.log(JSON.stringify(JSON.parse(data), null, 2));
      } catch (e) {
        console.log(data);
      }
      process.exit(0);
    });
  });

  req2.on("error", (error) => {
    console.error("Error:", error);
    process.exit(1);
  });

  req2.end();
}
