const jwt = require("jsonwebtoken");
const mysql = require("mysql2/promise");
const http = require("http");

async function test() {
  try {
    // Get donatur user ID 5 dari database
    const pool = mysql.createPool({
      host: "localhost",
      user: "root",
      password: "",
      database: "donasi_makanan",
    });

    const conn = await pool.getConnection();

    const [users] = await conn.execute(
      "SELECT id, nama, email, role FROM users WHERE id = 5"
    );

    if (!users.length) {
      console.error("User ID 5 not found");
      process.exit(1);
    }

    const user = users[0];
    console.log("User found:", user);

    // Generate token
    const token = jwt.sign(
      { id: user.id, nama: user.nama, email: user.email, role: user.role },
      "aplikasi_donasi_makanan_secret_2026_jwt_key",
      { expiresIn: "7d" }
    );

    console.log("\nTesting /api/donasi/my/menunggu...\n");

    const options = {
      hostname: "localhost",
      port: 3000,
      path: "/api/donasi/my/menunggu",
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
