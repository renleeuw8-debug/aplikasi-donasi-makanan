const mysql = require('mysql2/promise');

async function checkPenerima() {
  const pool = mysql.createPool({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'donasi_makanan',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
  });

  try {
    const connection = await pool.getConnection();
    
    console.log('=== Checking Penerima Data ===\n');
    
    // Check penerima with role='penerima'
    const [penerima] = await connection.execute(
      'SELECT id, nama, email, role, status FROM users WHERE role = ? ORDER BY id DESC LIMIT 10',
      ['penerima']
    );
    
    console.log('Penerima Users:');
    console.table(penerima);
    
    // Check junter specifically
    const [junter] = await connection.execute(
      'SELECT id, nama, email, role, status FROM users WHERE email = ?',
      ['junter@gmail.com']
    );
    
    console.log('\njunter@gmail.com Details:');
    console.table(junter);
    
    connection.release();
  } catch (err) {
    console.error('Error:', err.message);
  }
  
  process.exit(0);
}

checkPenerima();
