const bcrypt = require("bcryptjs");

// Generate hash untuk password
async function generateHash() {
  const password1 = "mersi123";
  const password2 = "petugas123";

  const hash1 = await bcrypt.hash(password1, 10);
  const hash2 = await bcrypt.hash(password2, 10);

  console.log(`mersi123 => ${hash1}`);
  console.log(`petugas123 => ${hash2}`);
}

generateHash();
