@REM Database Setup Helper Script for Windows
@echo off
chcp 65001 > nul
title Aplikasi Donasi Makanan - Database Setup

cls
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║  Aplikasi Donasi Makanan - Database Setup Helper           ║
echo ║  Created: January 2026                                     ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

:menu
echo.
echo Pilih opsi:
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo  1. Check Database Connection
echo  2. Create/Import Database (donasi_makanan.sql)
echo  3. Check MySQL Service Status
echo  4. Start MySQL Service
echo  5. Reset Database
echo  6. Exit
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

set /p choice="Enter your choice (1-6): "

if "%choice%"=="1" goto check_db
if "%choice%"=="2" goto import_db
if "%choice%"=="3" goto check_service
if "%choice%"=="4" goto start_service
if "%choice%"=="5" goto reset_db
if "%choice%"=="6" goto exit
echo Invalid choice. Please try again.
goto menu

:check_db
cls
echo.
echo 🔍 Checking Database Connection...
echo.
cd /d D:\aplikasi_donasi_makanan\backend
node check-db.js
pause
goto menu

:import_db
cls
echo.
echo 📥 Importing Database Structure...
echo.
echo This will create/reset the donasi_makanan database.
echo Make sure MySQL is running!
echo.
set /p password="Enter MySQL root password (press Enter if empty): "
cd /d D:\aplikasi_donasi_makanan
if "%password%"=="" (
  mysql -u root < donasi_makanan.sql
) else (
  mysql -u root -p%password% < donasi_makanan.sql
)
echo.
if %errorlevel% equ 0 (
  echo ✅ Database imported successfully!
  echo.
  echo Default accounts created:
  echo  📧 Admin: admin@gmail.com / Rhifaldy26
  echo  📧 Petugas: petugas@gmail.com / petugas123
) else (
  echo ❌ Database import failed!
  echo Troubleshooting:
  echo  1. Make sure MySQL is running
  echo  2. Check if password is correct
  echo  3. Check MySQL path is in environment variables
)
pause
goto menu

:check_service
cls
echo.
echo 🔍 Checking MySQL Service Status...
echo.
netstat -ano | findstr :3306
if %errorlevel% equ 0 (
  echo ✅ MySQL is running on port 3306
) else (
  echo ❌ MySQL is NOT running
  echo To start MySQL:
  echo  1. Open Services (services.msc)
  echo  2. Find "MySQL80" or "MySQL57"
  echo  3. Right-click and select "Start"
)
echo.
pause
goto menu

:start_service
cls
echo.
echo 🚀 Starting MySQL Service...
echo.
echo Trying to start MySQL service...
echo (This requires Administrator privileges)
echo.
net start MySQL80 2>nul
if %errorlevel% equ 0 (
  echo ✅ MySQL service started successfully!
) else (
  echo Trying alternative service name...
  net start MySQL57 2>nul
  if %errorlevel% equ 0 (
    echo ✅ MySQL service started successfully!
  ) else (
    echo ❌ Could not start MySQL service
    echo Try manually:
    echo  1. Open Services (services.msc)
    echo  2. Find MySQL service
    echo  3. Right-click and select "Start"
  )
)
echo.
pause
goto menu

:reset_db
cls
echo.
echo ⚠️  WARNING: This will DELETE all data in donasi_makanan database!
echo.
set /p confirm="Are you sure? (yes/no): "
if /i "%confirm%"=="yes" goto do_reset
if /i "%confirm%"=="y" goto do_reset
echo Cancelled.
pause
goto menu

:do_reset
cls
echo.
echo 🔄 Resetting Database...
echo.
set /p password="Enter MySQL root password (press Enter if empty): "
cd /d D:\aplikasi_donasi_makanan
if "%password%"=="" (
  mysql -u root -e "DROP DATABASE IF EXISTS donasi_makanan;"
  mysql -u root < donasi_makanan.sql
) else (
  mysql -u root -p%password% -e "DROP DATABASE IF EXISTS donasi_makanan;"
  mysql -u root -p%password% < donasi_makanan.sql
)
echo.
if %errorlevel% equ 0 (
  echo ✅ Database reset successfully!
) else (
  echo ❌ Database reset failed!
)
pause
goto menu

:exit
cls
echo.
echo Thank you for using Aplikasi Donasi Makanan Database Setup!
echo.
exit /b 0
