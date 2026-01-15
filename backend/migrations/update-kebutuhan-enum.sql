-- Migration: Update kebutuhan_penerima table to support new jenis_kebutuhan values
-- Date: 2026-01-11
-- Run this SQL to update the existing database table

-- Update the enum column to include new categories
ALTER TABLE kebutuhan_penerima 
MODIFY COLUMN jenis_kebutuhan enum('makanan','pakaian','buku','kesehatan','barang','lainnya') NOT NULL;

-- Verify the change
DESCRIBE kebutuhan_penerima;
