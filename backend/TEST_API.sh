#!/bin/bash

# Script testing API Aplikasi Donasi Makanan
# Change BASE_URL if needed
BASE_URL="http://localhost:3000/api"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Aplikasi Donasi Makanan - API Testing ===${NC}\n"

# ============================================
# TEST 1: LOGIN AS ADMIN
# ============================================
echo -e "${YELLOW}TEST 1: Login as Admin${NC}"
ADMIN_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@gmail.com",
    "password": "Rhifaldy26"
  }')

ADMIN_TOKEN=$(echo $ADMIN_LOGIN | grep -o '"token":"[^"]*' | cut -d'"' -f4)
ADMIN_ID=$(echo $ADMIN_LOGIN | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -z "$ADMIN_TOKEN" ]; then
  echo -e "${RED}✗ Admin login failed${NC}"
  echo "Response: $ADMIN_LOGIN"
else
  echo -e "${GREEN}✓ Admin login successful${NC}"
  echo "Token: $ADMIN_TOKEN"
  echo "ID: $ADMIN_ID"
fi
echo ""

# ============================================
# TEST 2: LOGIN AS PETUGAS
# ============================================
echo -e "${YELLOW}TEST 2: Login as Petugas${NC}"
PETUGAS_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "petugas@gmail.com",
    "password": "petugas123"
  }')

PETUGAS_TOKEN=$(echo $PETUGAS_LOGIN | grep -o '"token":"[^"]*' | cut -d'"' -f4)
PETUGAS_ID=$(echo $PETUGAS_LOGIN | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -z "$PETUGAS_TOKEN" ]; then
  echo -e "${RED}✗ Petugas login failed${NC}"
  echo "Response: $PETUGAS_LOGIN"
else
  echo -e "${GREEN}✓ Petugas login successful${NC}"
  echo "Token: $PETUGAS_TOKEN"
  echo "ID: $PETUGAS_ID"
fi
echo ""

# ============================================
# TEST 3: REGISTER NEW DONATUR
# ============================================
echo -e "${YELLOW}TEST 3: Register New Donatur${NC}"
REGISTER=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "nama": "Ahmad Donatur",
    "email": "ahmad.donatur@example.com",
    "password": "password123",
    "password_confirm": "password123",
    "no_hp": "081234567890",
    "alamat": "Jl. Merdeka No. 123, Jakarta"
  }')

DONATUR_TOKEN=$(echo $REGISTER | grep -o '"token":"[^"]*' | cut -d'"' -f4)
DONATUR_ID=$(echo $REGISTER | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -z "$DONATUR_TOKEN" ]; then
  echo -e "${RED}✗ Register donatur failed${NC}"
  echo "Response: $REGISTER"
else
  echo -e "${GREEN}✓ Register donatur successful${NC}"
  echo "Token: $DONATUR_TOKEN"
  echo "ID: $DONATUR_ID"
fi
echo ""

# ============================================
# TEST 4: CREATE DONASI
# ============================================
echo -e "${YELLOW}TEST 4: Create Donasi${NC}"
CREATE_DONASI=$(curl -s -X POST "$BASE_URL/donasi" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $DONATUR_TOKEN" \
  -d '{
    "jenis_donasi": "makanan",
    "nama_barang": "Nasi Kuning",
    "jumlah": 50,
    "deskripsi": "Nasi kuning siap saji berkualitas",
    "latitude": -6.2088,
    "longitude": 106.8456,
    "alamat": "Kantor Pusat Jakarta Pusat"
  }')

DONASI_ID=$(echo $CREATE_DONASI | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -z "$DONASI_ID" ]; then
  echo -e "${RED}✗ Create donasi failed${NC}"
  echo "Response: $CREATE_DONASI"
else
  echo -e "${GREEN}✓ Create donasi successful${NC}"
  echo "Donasi ID: $DONASI_ID"
fi
echo ""

# ============================================
# TEST 5: GET ALL DONASI
# ============================================
echo -e "${YELLOW}TEST 5: Get All Donasi${NC}"
GET_ALL=$(curl -s -X GET "$BASE_URL/donasi" \
  -H "Authorization: Bearer $PETUGAS_TOKEN")

echo -e "${GREEN}✓ Get all donasi response:${NC}"
echo $GET_ALL | python -m json.tool 2>/dev/null || echo $GET_ALL
echo ""

# ============================================
# TEST 6: VERIFY DONASI (Petugas)
# ============================================
if [ ! -z "$DONASI_ID" ]; then
  echo -e "${YELLOW}TEST 6: Verify Donasi (Petugas)${NC}"
  VERIFY=$(curl -s -X POST "$BASE_URL/donasi/$DONASI_ID/verify" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $PETUGAS_TOKEN" \
    -d '{
      "penerima_id": null
    }')

  if echo $VERIFY | grep -q '"success":true'; then
    echo -e "${GREEN}✓ Donasi verified successfully${NC}"
  else
    echo -e "${RED}✗ Verify donasi failed${NC}"
    echo "Response: $VERIFY"
  fi
  echo ""
fi

# ============================================
# TEST 7: GET DONASI DETAIL
# ============================================
if [ ! -z "$DONASI_ID" ]; then
  echo -e "${YELLOW}TEST 7: Get Donasi Detail${NC}"
  DETAIL=$(curl -s -X GET "$BASE_URL/donasi/$DONASI_ID" \
    -H "Authorization: Bearer $PETUGAS_TOKEN")

  echo -e "${GREEN}✓ Donasi detail response:${NC}"
  echo $DETAIL | python -m json.tool 2>/dev/null || echo $DETAIL
  echo ""
fi

# ============================================
# TEST 8: GET MAP DATA
# ============================================
echo -e "${YELLOW}TEST 8: Get Map Data${NC}"
MAP_DATA=$(curl -s -X GET "$BASE_URL/lokasi/map/data" \
  -H "Authorization: Bearer $PETUGAS_TOKEN")

echo -e "${GREEN}✓ Map data response:${NC}"
echo $MAP_DATA | python -m json.tool 2>/dev/null || echo $MAP_DATA
echo ""

# ============================================
# TEST 9: GET PROFILE
# ============================================
echo -e "${YELLOW}TEST 9: Get Profile (Admin)${NC}"
PROFILE=$(curl -s -X GET "$BASE_URL/auth/profile" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

echo -e "${GREEN}✓ Profile response:${NC}"
echo $PROFILE | python -m json.tool 2>/dev/null || echo $PROFILE
echo ""

# ============================================
# TEST 10: GET NOTIFIKASI
# ============================================
echo -e "${YELLOW}TEST 10: Get Notifikasi${NC}"
NOTIFIKASI=$(curl -s -X GET "$BASE_URL/notifikasi" \
  -H "Authorization: Bearer $DONATUR_TOKEN")

echo -e "${GREEN}✓ Notifikasi response:${NC}"
echo $NOTIFIKASI | python -m json.tool 2>/dev/null || echo $NOTIFIKASI
echo ""

echo -e "${GREEN}=== Testing Complete ===${NC}"
