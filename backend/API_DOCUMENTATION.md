# 📚 API Documentation - Aplikasi Donasi Makanan

## Base URL

```
http://localhost:3000/api
```

## Authentication Header (untuk protected routes)

```
Authorization: Bearer {token}
Content-Type: application/json
```

---

## 🔐 Authentication Endpoints

### 1. Login

**POST** `/auth/login`

**Request Body:**

```json
{
  "email": "admin@gmail.com",
  "password": "Rhifaldy26"
}
```

**Response (200):**

```json
{
  "success": true,
  "message": "Login berhasil",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "nama": "Admin",
    "email": "admin@gmail.com",
    "role": "admin",
    "alamat": null,
    "no_hp": null
  }
}
```

**Response Error (401):**

```json
{
  "success": false,
  "message": "Email atau password tidak valid"
}
```

---

### 2. Register Donatur

**POST** `/auth/register`

⭐ **PENTING:** Field `no_hp` (nomor telpon) **WAJIB** diisi untuk registrasi donatur!

**Request Body:**

```json
{
  "nama": "Ahmad Donatur",
  "email": "ahmad.donatur@example.com",
  "password": "password123",
  "password_confirm": "password123",
  "no_hp": "081234567890",
  "alamat": "Jl. Merdeka No. 123, Jakarta Selatan"
}
```

**Field Description:**
| Field | Type | Required | Min Length | Validation |
|-------|------|----------|------------|-----------|
| nama | string | ✅ Yes | 1 | |
| email | string | ✅ Yes | - | Valid email format |
| password | string | ✅ Yes | 6 | Must match password_confirm |
| password_confirm | string | ✅ Yes | 6 | Must match password |
| no_hp | string | ✅ Yes | 10 digits | Minimum 10 digits |
| alamat | string | ❌ Optional | - | |

**Response Success (201):**

```json
{
  "success": true,
  "message": "Registrasi berhasil",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 3,
    "nama": "Ahmad Donatur",
    "email": "ahmad.donatur@example.com",
    "role": "donatur",
    "alamat": "Jl. Merdeka No. 123, Jakarta Selatan",
    "no_hp": "081234567890"
  }
}
```

**Response Validation Error (400):**

```json
{
  "success": false,
  "message": "Nomor telpon harus diisi"
}
```

atau

```json
{
  "success": false,
  "message": "Nomor telpon harus minimal 10 digit"
}
```

**Response Duplicate Error (400):**

```json
{
  "success": false,
  "message": "Email sudah terdaftar"
}
```

---

### 3. Get Profile

**GET** `/auth/profile`

**Headers:**

```
Authorization: Bearer {token}
```

**Response (200):**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "nama": "Admin",
    "email": "admin@gmail.com",
    "role": "admin",
    "alamat": null,
    "no_hp": null,
    "status": "aktif",
    "created_at": "2026-01-10T17:53:59.000Z"
  }
}
```

---

### 4. Update Profile

**PUT** `/auth/profile`

**Headers:**

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**

```json
{
  "nama": "Ahmad Updated",
  "no_hp": "089876543210",
  "alamat": "Jl. Sudirman No. 456, Jakarta Pusat"
}
```

**Response (200):**

```json
{
  "success": true,
  "message": "Profil berhasil diupdate",
  "data": {
    "id": 3,
    "nama": "Ahmad Updated",
    "email": "ahmad.donatur@example.com",
    "role": "donatur",
    "alamat": "Jl. Sudirman No. 456, Jakarta Pusat",
    "no_hp": "089876543210"
  }
}
```

---

## 🎁 Donasi Endpoints

### 1. Create Donasi

**POST** `/donasi`

**Headers:**

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**

```json
{
  "jenis_donasi": "makanan",
  "nama_barang": "Nasi Kuning",
  "jumlah": 50,
  "deskripsi": "Nasi kuning siap saji berkualitas tinggi",
  "foto_donasi": "https://example.com/image.jpg",
  "latitude": -6.2088,
  "longitude": 106.8456,
  "alamat": "Kantor Pusat Jakarta Pusat"
}
```

**Field Description:**
| Field | Type | Required | Values |
|-------|------|----------|--------|
| jenis_donasi | string | ✅ Yes | `makanan`, `barang` |
| nama_barang | string | ✅ Yes | |
| jumlah | number | ✅ Yes | Integer > 0 |
| deskripsi | string | ❌ Optional | |
| foto_donasi | string | ❌ Optional | URL foto |
| latitude | number | ✅ Yes | Decimal (-90 to 90) |
| longitude | number | ✅ Yes | Decimal (-180 to 180) |
| alamat | string | ❌ Optional | |

**Response Success (201):**

```json
{
  "success": true,
  "message": "Donasi berhasil dibuat",
  "data": {
    "id": 1,
    "donatur_id": 3,
    "donatur_nama": "Ahmad Donatur",
    "donatur_hp": "081234567890",
    "jenis_donasi": "makanan",
    "nama_barang": "Nasi Kuning",
    "jumlah": 50,
    "deskripsi": "Nasi kuning siap saji berkualitas tinggi",
    "foto_donasi": "https://example.com/image.jpg",
    "status": "menunggu",
    "petugas_id": null,
    "penerima_id": null,
    "created_at": "2026-01-11T10:30:00.000Z"
  }
}
```

---

### 2. Get All Donasi

**GET** `/donasi`

**Headers:**

```
Authorization: Bearer {token}
```

**Query Parameters:**
| Parameter | Type | Optional | Values |
|-----------|------|----------|--------|
| status | string | ✅ Yes | `menunggu`, `diverifikasi`, `diterima`, `selesai`, `dibatalkan` |
| jenis_donasi | string | ✅ Yes | `makanan`, `barang` |

**Example URL:**

```
GET /donasi?status=menunggu&jenis_donasi=makanan
```

**Response (200):**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "donatur_id": 3,
      "donatur_nama": "Ahmad Donatur",
      "donatur_hp": "081234567890",
      "jenis_donasi": "makanan",
      "nama_barang": "Nasi Kuning",
      "jumlah": 50,
      "status": "menunggu",
      "created_at": "2026-01-11T10:30:00.000Z",
      "lokasi": {
        "id": 1,
        "latitude": -6.2088,
        "longitude": 106.8456,
        "alamat": "Jakarta Pusat"
      }
    }
  ]
}
```

---

### 3. Get Donasi Detail

**GET** `/donasi/:id`

**Headers:**

```
Authorization: Bearer {token}
```

**Response (200):**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "donatur_id": 3,
    "donatur_nama": "Ahmad Donatur",
    "jenis_donasi": "makanan",
    "nama_barang": "Nasi Kuning",
    "jumlah": 50,
    "status": "menunggu",
    "lokasi": {
      "id": 1,
      "latitude": -6.2088,
      "longitude": 106.8456,
      "alamat": "Jakarta Pusat"
    },
    "riwayat": [
      {
        "id": 1,
        "aksi": "dibuat",
        "nama": "Ahmad Donatur",
        "created_at": "2026-01-11T10:30:00.000Z"
      }
    ]
  }
}
```

---

### 4. Update Donasi

**PUT** `/donasi/:id`

**Headers:**

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**

```json
{
  "nama_barang": "Nasi Kuning Premium",
  "jumlah": 75,
  "deskripsi": "Nasi kuning premium berkualitas premium"
}
```

**Response (200):**

```json
{
  "success": true,
  "message": "Donasi berhasil diupdate",
  "data": { ... }
}
```

---

### 5. Verify Donasi (Petugas Only)

**POST** `/donasi/:id/verify`

**Headers:**

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**

```json
{
  "penerima_id": null
}
```

**Response (200):**

```json
{
  "success": true,
  "message": "Donasi berhasil diverifikasi",
  "data": {
    "id": 1,
    "status": "diverifikasi",
    "petugas_id": 2
  }
}
```

---

### 6. Receive Donasi

**POST** `/donasi/:id/receive`

**Headers:**

```
Authorization: Bearer {token}
```

**Response (200):**

```json
{
  "success": true,
  "message": "Donasi berhasil diterima",
  "data": {
    "id": 1,
    "status": "diterima"
  }
}
```

---

### 7. Complete Donasi (Petugas Only)

**POST** `/donasi/:id/complete`

**Response (200):**

```json
{
  "success": true,
  "message": "Donasi berhasil diselesaikan",
  "data": {
    "id": 1,
    "status": "selesai"
  }
}
```

---

### 8. Cancel Donasi

**POST** `/donasi/:id/cancel`

**Request Body:**

```json
{
  "keterangan": "Donasi dibatalkan karena barang rusak"
}
```

**Response (200):**

```json
{
  "success": true,
  "message": "Donasi berhasil dibatalkan",
  "data": {
    "id": 1,
    "status": "dibatalkan"
  }
}
```

---

### 9. Delete Donasi

**DELETE** `/donasi/:id`

**Response (200):**

```json
{
  "success": true,
  "message": "Donasi berhasil dihapus"
}
```

---

## 📍 Location Endpoints

### 1. Get Map Data

**GET** `/lokasi/map/data`

**Headers:**

```
Authorization: Bearer {token}
```

**Response (200):**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "nama_barang": "Nasi Kuning",
      "jenis_donasi": "makanan",
      "status": "menunggu",
      "latitude": -6.2088,
      "longitude": 106.8456,
      "alamat": "Jakarta Pusat"
    }
  ]
}
```

---

### 2. Get Location Detail

**GET** `/lokasi/:donasi_id`

**Response (200):**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "donasi_id": 1,
    "latitude": -6.2088,
    "longitude": 106.8456,
    "alamat": "Jakarta Pusat",
    "created_at": "2026-01-11T10:30:00.000Z"
  }
}
```

---

### 3. Update Location

**PUT** `/lokasi/:donasi_id`

**Request Body:**

```json
{
  "latitude": -6.21,
  "longitude": 106.847,
  "alamat": "Jakarta Pusat Updated"
}
```

**Response (200):**

```json
{
  "success": true,
  "message": "Lokasi berhasil diupdate",
  "data": { ... }
}
```

---

## 📋 Kebutuhan Endpoints

### 1. Create Kebutuhan (Penerima Only)

**POST** `/kebutuhan`

**Request Body:**

```json
{
  "jenis_kebutuhan": "makanan",
  "deskripsi": "Butuh makanan bergizi untuk keluarga 5 orang",
  "jumlah": 100,
  "foto_kebutuhan": "https://example.com/image.jpg"
}
```

**Response (201):**

```json
{
  "success": true,
  "message": "Kebutuhan berhasil dibuat",
  "data": {
    "id": 1,
    "penerima_id": 4,
    "penerima_nama": "Keluarga Sejahtera",
    "jenis_kebutuhan": "makanan",
    "deskripsi": "Butuh makanan bergizi untuk keluarga 5 orang",
    "jumlah": 100,
    "status": "aktif",
    "created_at": "2026-01-11T11:00:00.000Z"
  }
}
```

---

### 2. Get All Kebutuhan

**GET** `/kebutuhan`

**Query Parameters:**
| Parameter | Type | Optional |
|-----------|------|----------|
| status | string | ✅ Yes - `aktif`, `terpenuhi` |

**Response (200):**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "penerima_id": 4,
      "penerima_nama": "Keluarga Sejahtera",
      "jenis_kebutuhan": "makanan",
      "deskripsi": "Butuh makanan bergizi",
      "jumlah": 100,
      "status": "aktif",
      "created_at": "2026-01-11T11:00:00.000Z"
    }
  ]
}
```

---

### 3. Update Kebutuhan

**PUT** `/kebutuhan/:id`

**Request Body:**

```json
{
  "deskripsi": "Butuh makanan bergizi berkualitas tinggi",
  "jumlah": 150,
  "status": "aktif"
}
```

**Response (200):**

```json
{
  "success": true,
  "message": "Kebutuhan berhasil diupdate",
  "data": { ... }
}
```

---

### 4. Delete Kebutuhan

**DELETE** `/kebutuhan/:id`

**Response (200):**

```json
{
  "success": true,
  "message": "Kebutuhan berhasil dihapus"
}
```

---

## 🔔 Notifikasi Endpoints

### 1. Get Notifikasi

**GET** `/notifikasi`

**Query Parameters:**
| Parameter | Type | Optional |
|-----------|------|----------|
| limit | number | ✅ Yes - Default: 20 |

**Response (200):**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "user_id": 3,
      "judul": "Donasi Berhasil Dibuat",
      "pesan": "Donasi Nasi Kuning Anda sudah terdaftar",
      "tipe": "donasi",
      "is_read": false,
      "created_at": "2026-01-11T10:35:00.000Z"
    }
  ]
}
```

---

### 2. Get Unread Count

**GET** `/notifikasi/unread/count`

**Response (200):**

```json
{
  "success": true,
  "data": {
    "unread_count": 3
  }
}
```

---

### 3. Mark as Read

**PUT** `/notifikasi/:id/read`

**Response (200):**

```json
{
  "success": true,
  "message": "Notifikasi berhasil ditandai sebagai telah dibaca"
}
```

---

### 4. Delete Notifikasi

**DELETE** `/notifikasi/:id`

**Response (200):**

```json
{
  "success": true,
  "message": "Notifikasi berhasil dihapus"
}
```

---

## ✅ Health Check

### Server Status

**GET** `/health`

**Response (200):**

```json
{
  "status": "OK",
  "message": "Server berjalan dengan baik"
}
```

---

## 🔒 Role-Based Access Control

| Endpoint                  | Public | Donatur | Penerima | Petugas | Admin |
| ------------------------- | ------ | ------- | -------- | ------- | ----- |
| POST /auth/login          | ✅     | ✅      | ✅       | ✅      | ✅    |
| POST /auth/register       | ✅     | -       | -        | -       | -     |
| GET /auth/profile         | -      | ✅      | ✅       | ✅      | ✅    |
| POST /donasi              | -      | ✅      | -        | -       | ✅    |
| GET /donasi               | -      | ✅      | ✅       | ✅      | ✅    |
| PUT /donasi/:id           | -      | Own     | -        | -       | ✅    |
| POST /donasi/:id/verify   | -      | -       | -        | ✅      | ✅    |
| POST /donasi/:id/complete | -      | -       | -        | ✅      | ✅    |
| POST /kebutuhan           | -      | -       | ✅       | -       | ✅    |
| GET /kebutuhan            | -      | ✅      | ✅       | ✅      | ✅    |

---

## ❌ Error Responses

### 400 - Bad Request

```json
{
  "success": false,
  "message": "Validation error message"
}
```

### 401 - Unauthorized

```json
{
  "success": false,
  "message": "Token tidak ditemukan"
}
```

atau

```json
{
  "success": false,
  "message": "Token tidak valid atau kadaluarsa"
}
```

### 403 - Forbidden

```json
{
  "success": false,
  "message": "Anda tidak memiliki akses ke resource ini"
}
```

### 404 - Not Found

```json
{
  "success": false,
  "message": "Resource tidak ditemukan"
}
```

### 500 - Server Error

```json
{
  "success": false,
  "message": "Terjadi kesalahan pada server",
  "error": "Error details"
}
```

---

## 📝 Notes

1. **Token Expiration:** 7 hari
2. **Phone Number Validation:** Minimum 10 digits untuk register donatur
3. **Status Workflow:** menunggu → diverifikasi → diterima → selesai
4. **File Upload:** Foto dapat diupload melalui URL string
5. **Coordinates:** Gunakan decimal format untuk latitude/longitude

---

**Last Updated:** January 2026
**Version:** 1.0.0
