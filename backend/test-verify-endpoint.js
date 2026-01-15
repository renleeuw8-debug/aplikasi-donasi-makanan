const jwt = require("jsonwebtoken");
const mysql = require("mysql2/promise");

async function test() {
  try {
    // Get petugas user dari database
    const pool = mysql.createPool({
      host: "localhost",
      user: "root",
      password: "",
      database: "donasi_makanan",
    });

    const conn = await pool.getConnection();

    const [users] = await conn.execute(
      'SELECT id, nama, email, role FROM users WHERE role = "petugas" LIMIT 1'
    );

    if (!users.length) {
      console.error("No petugas user found");
      process.exit(1);
    }

    const petugas = users[0];
    console.log("Petugas found:", petugas);

    // Generate token
    const token = jwt.sign(
      {
        id: petugas.id,
        nama: petugas.nama,
        email: petugas.email,
        role: petugas.role,
      },
      "aplikasi_donasi_makanan_secret_2026_jwt_key",
      { expiresIn: "7d" }
    );

    console.log("\nGenerated token:", token);

    // Now test the endpoint
    const http = require("http");

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

    console.log("\n=== Testing /api/donasi/verify/menunggu ===");

    const req = http.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => {
        data += chunk;
      });
      res.on("end", () => {
        console.log("Status:", res.statusCode);
        try {
          const result = JSON.parse(data);
          console.log(JSON.stringify(result, null, 2));
        } catch (e) {
          console.log(data);
        }
        conn.release();
        process.exit(0);
      });
    });

    req.on("error", (error) => {
      console.error("Request error:", error);
      process.exit(1);
    });

    req.end();
  } catch (error) {
    console.error("Error:", error.message);
    process.exit(1);
  }
}

test();
