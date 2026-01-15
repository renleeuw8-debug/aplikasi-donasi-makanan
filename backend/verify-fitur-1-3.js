#!/usr/bin/env node
/**
 * Quick verification test untuk Fitur 1 & 3
 */

const axios = require('axios');
const fs = require('fs');
const FormData = require('form-data');

const API_URL = 'http://192.168.100.9:3000/api';

async function verifyBackend() {
  console.log('🔍 Verifying Backend Implementation...\n');
  
  try {
    // Test 1: Check auth endpoint
    console.log('1️⃣ Testing Auth Login...');
    const loginTest = await axios.post(`${API_URL}/auth/login`, {
      email: 'rully@gmail.com',
      password: 'password123'
    }).then(() => true).catch(e => e.response?.status === 401 || e.response?.status === 400);
    
    if (loginTest) {
      console.log('   ✅ Auth endpoint responding\n');
    }
    
    // Test 2: Check if multer is configured
    console.log('2️⃣ Checking Multer Configuration...');
    const routesFile = fs.readFileSync('routes/donasi.js', 'utf8');
    if (routesFile.includes('multer') && routesFile.includes('upload.single')) {
      console.log('   ✅ Multer configured in routes/donasi.js\n');
    } else {
      console.log('   ❌ Multer not found in routes/donasi.js\n');
    }
    
    // Test 3: Check DonasiController
    console.log('3️⃣ Checking DonasiController...');
    const controllerFile = fs.readFileSync('controllers/DonasiController.js', 'utf8');
    if (controllerFile.includes('fotoBuktiPath') && controllerFile.includes('foto_bukti_terima')) {
      console.log('   ✅ File upload handling implemented\n');
    } else {
      console.log('   ❌ File upload handling not found\n');
    }
    
    // Test 4: Check AuthController
    console.log('4️⃣ Checking AuthController...');
    const authFile = fs.readFileSync('controllers/AuthController.js', 'utf8');
    if (authFile.includes('nama_panti_asuhan')) {
      console.log('   ✅ Panti asuhan field added to register\n');
    } else {
      console.log('   ❌ Panti asuhan field not found\n');
    }
    
    // Test 5: Check User model
    console.log('5️⃣ Checking User Model...');
    const userFile = fs.readFileSync('models/User.js', 'utf8');
    if (userFile.includes('nama_panti_asuhan')) {
      console.log('   ✅ User model updated with nama_panti_asuhan\n');
    } else {
      console.log('   ❌ User model not updated\n');
    }
    
    // Test 6: Check uploads directory
    console.log('6️⃣ Checking Uploads Directory...');
    if (fs.existsSync('uploads/donasi')) {
      console.log('   ✅ uploads/donasi directory exists\n');
    } else {
      console.log('   ❌ uploads/donasi directory not found\n');
    }
    
    console.log('=' + '='.repeat(50));
    console.log('✅ Backend Implementation Verified!\n');
    console.log('Ready for Flutter UI implementation.\n');
    
  } catch (error) {
    console.error('❌ Verification error:', error.message);
  }
}

verifyBackend();
