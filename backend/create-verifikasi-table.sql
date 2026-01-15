-- Tambah tabel verifikasi untuk mencatat history verifikasi donasi
CREATE TABLE IF NOT EXISTS `verifikasi` (
  `id` int NOT NULL AUTO_INCREMENT,
  `donasi_id` int NOT NULL,
  `petugas_id` int NOT NULL,
  `catatan` text,
  `status_verifikasi` enum('disetujui','ditolak','perlu_revisi') DEFAULT 'disetujui',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `donasi_id` (`donasi_id`),
  KEY `petugas_id` (`petugas_id`),
  CONSTRAINT `verifikasi_ibfk_1` FOREIGN KEY (`donasi_id`) REFERENCES `donasi` (`id`) ON DELETE CASCADE,
  CONSTRAINT `verifikasi_ibfk_2` FOREIGN KEY (`petugas_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
