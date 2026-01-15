-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Jan 10, 2026 at 06:20 PM
-- Server version: 8.0.30
-- PHP Version: 8.1.10

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `donasi_makanan`
--

-- --------------------------------------------------------

--
-- Table structure for table `donasi`
--

CREATE TABLE `donasi` (
  `id` int NOT NULL,
  `donatur_id` int NOT NULL,
  `jenis_donasi` enum('makanan','barang') NOT NULL,
  `nama_barang` varchar(100) NOT NULL,
  `jumlah` int NOT NULL,
  `deskripsi` text,
  `status` enum('menunggu','diverifikasi','diterima','dibatalkan','selesai') DEFAULT 'menunggu',
  `petugas_id` int DEFAULT NULL,
  `penerima_id` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `foto_donasi` text COMMENT 'URL foto donasi'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `kebutuhan_penerima`
--

CREATE TABLE `kebutuhan_penerima` (
  `id` int NOT NULL,
  `penerima_id` int NOT NULL,
  `jenis_kebutuhan` enum('makanan','pakaian','buku','kesehatan','barang','lainnya') NOT NULL,
  `deskripsi` text,
  `jumlah` int DEFAULT NULL,
  `status` enum('aktif','terpenuhi') DEFAULT 'aktif',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `foto_kebutuhan` text COMMENT 'URL foto kebutuhan'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `lokasi_donasi`
--

CREATE TABLE `lokasi_donasi` (
  `id` int NOT NULL,
  `donasi_id` int NOT NULL,
  `latitude` decimal(10,8) NOT NULL,
  `longitude` decimal(11,8) NOT NULL,
  `alamat` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `notifikasi`
--

CREATE TABLE `notifikasi` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `judul` varchar(100) NOT NULL,
  `pesan` text NOT NULL,
  `tipe` enum('donasi','kebutuhan','verifikasi','sistem') DEFAULT 'sistem',
  `is_read` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `riwayat_donasi`
--

CREATE TABLE `riwayat_donasi` (
  `id` int NOT NULL,
  `donasi_id` int NOT NULL,
  `user_id` int NOT NULL,
  `aksi` enum('dibuat','diverifikasi','diterima','dibatalkan','selesai') NOT NULL,
  `keterangan` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int NOT NULL,
  `nama` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `no_hp` varchar(20) DEFAULT NULL,
  `role` enum('donatur','penerima','petugas','admin') NOT NULL,
  `status` enum('aktif','nonaktif') DEFAULT 'aktif',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `alamat` text COMMENT 'Alamat lengkap pengguna'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `nama`, `email`, `password_hash`, `no_hp`, `role`, `status`, `created_at`, `updated_at`, `alamat`) VALUES
(1, 'Petugas', 'petugas@gmail.com', '2dad904f71aa0dcf6ea1addaa084a5865ffe448e4d3f900668e1cc7e7b6153d7', NULL, 'petugas', 'aktif', '2026-01-10 17:53:59', '2026-01-10 17:53:59', NULL),
(2, 'Admin', 'admin@gmail.com', '127e4d2c7152af4c783e58970eb8f7d60a82c2052c6fb8e12c3eb740f83d51b8', NULL, 'admin', 'aktif', '2026-01-10 17:53:59', '2026-01-10 17:53:59', NULL);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_donasi_peta`
-- (See below for the actual view)
--
CREATE TABLE `v_donasi_peta` (
`id` int
,`nama_barang` varchar(100)
,`jenis_donasi` enum('makanan','barang')
,`status` enum('menunggu','diverifikasi','diterima','dibatalkan','selesai')
,`latitude` decimal(10,8)
,`longitude` decimal(11,8)
,`alamat` text
);

-- --------------------------------------------------------

--
-- Structure for view `v_donasi_peta`
--
DROP TABLE IF EXISTS `v_donasi_peta`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_donasi_peta`  AS SELECT `d`.`id` AS `id`, `d`.`nama_barang` AS `nama_barang`, `d`.`jenis_donasi` AS `jenis_donasi`, `d`.`status` AS `status`, `l`.`latitude` AS `latitude`, `l`.`longitude` AS `longitude`, `l`.`alamat` AS `alamat` FROM (`donasi` `d` join `lokasi_donasi` `l` on((`d`.`id` = `l`.`donasi_id`))) WHERE (`d`.`status` in ('diverifikasi','menunggu'))  ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `donasi`
--
ALTER TABLE `donasi`
  ADD PRIMARY KEY (`id`),
  ADD KEY `donatur_id` (`donatur_id`),
  ADD KEY `petugas_id` (`petugas_id`),
  ADD KEY `penerima_id` (`penerima_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_jenis` (`jenis_donasi`);

--
-- Indexes for table `kebutuhan_penerima`
--
ALTER TABLE `kebutuhan_penerima`
  ADD PRIMARY KEY (`id`),
  ADD KEY `penerima_id` (`penerima_id`);

--
-- Indexes for table `lokasi_donasi`
--
ALTER TABLE `lokasi_donasi`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `donasi_id` (`donasi_id`);

--
-- Indexes for table `notifikasi`
--
ALTER TABLE `notifikasi`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user` (`user_id`),
  ADD KEY `idx_read` (`is_read`);

--
-- Indexes for table `riwayat_donasi`
--
ALTER TABLE `riwayat_donasi`
  ADD PRIMARY KEY (`id`),
  ADD KEY `donasi_id` (`donasi_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `idx_role` (`role`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `donasi`
--
ALTER TABLE `donasi`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `kebutuhan_penerima`
--
ALTER TABLE `kebutuhan_penerima`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `lokasi_donasi`
--
ALTER TABLE `lokasi_donasi`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `notifikasi`
--
ALTER TABLE `notifikasi`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `riwayat_donasi`
--
ALTER TABLE `riwayat_donasi`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `donasi`
--
ALTER TABLE `donasi`
  ADD CONSTRAINT `donasi_ibfk_1` FOREIGN KEY (`donatur_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `donasi_ibfk_2` FOREIGN KEY (`petugas_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `donasi_ibfk_3` FOREIGN KEY (`penerima_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `kebutuhan_penerima`
--
ALTER TABLE `kebutuhan_penerima`
  ADD CONSTRAINT `kebutuhan_penerima_ibfk_1` FOREIGN KEY (`penerima_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `lokasi_donasi`
--
ALTER TABLE `lokasi_donasi`
  ADD CONSTRAINT `lokasi_donasi_ibfk_1` FOREIGN KEY (`donasi_id`) REFERENCES `donasi` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `notifikasi`
--
ALTER TABLE `notifikasi`
  ADD CONSTRAINT `notifikasi_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `riwayat_donasi`
--
ALTER TABLE `riwayat_donasi`
  ADD CONSTRAINT `riwayat_donasi_ibfk_1` FOREIGN KEY (`donasi_id`) REFERENCES `donasi` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `riwayat_donasi_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
