<?php
/**
 * Header Component
 */

// Check if user is logged in
if (!isset($_SESSION['admin_id'])) {
    header('Location: ../index.php?redirect=' . urlencode($_SERVER['REQUEST_URI']));
    exit;
}

// Check maintenance mode - tapi izinkan admin
include 'maintenance-check.php';

$admin_name = $_SESSION['admin_name'] ?? 'Admin';
$admin_role = $_SESSION['admin_role'] ?? 'admin';
?>

<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo $page_title ?? 'Admin Panel'; ?> - Aplikasi Donasi Makanan</title>
    
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css" rel="stylesheet">
    <!-- Custom CSS -->
    <link href="../assets/css/style.css" rel="stylesheet">
    
    <style>
        :root {
            --primary-color: #2ecc71;
            --secondary-color: #3498db;
            --danger-color: #e74c3c;
            --warning-color: #f39c12;
            --dark-color: #2c3e50;
        }

        body {
            background-color: #f5f7fa;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }

        .sidebar {
            background: linear-gradient(135deg, var(--dark-color) 0%, #34495e 100%);
            min-height: 100vh;
            padding: 20px 0;
            position: fixed;
            left: 0;
            top: 0;
            width: 250px;
            overflow-y: auto;
            box-shadow: 2px 0 5px rgba(0,0,0,0.1);
        }

        .sidebar .brand {
            padding: 20px;
            color: white;
            font-size: 18px;
            font-weight: bold;
            border-bottom: 1px solid rgba(255,255,255,0.1);
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .sidebar .nav-item {
            margin: 5px 0;
        }

        .sidebar .nav-link {
            color: rgba(255,255,255,0.7);
            padding: 12px 20px;
            border-left: 3px solid transparent;
            transition: all 0.3s;
        }

        .sidebar .nav-link:hover {
            color: white;
            background-color: rgba(255,255,255,0.1);
            border-left-color: var(--primary-color);
        }

        .sidebar .nav-link.active {
            color: white;
            background-color: var(--primary-color);
            border-left-color: white;
        }

        .main-content {
            margin-left: 250px;
            padding: 30px;
        }

        .topbar {
            background: white;
            padding: 20px;
            margin-bottom: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .user-info {
            display: flex;
            align-items: center;
            gap: 15px;
        }

        .user-info .avatar {
            width: 40px;
            height: 40px;
            background: var(--primary-color);
            color: white;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
        }

        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 20px;
            border-left: 4px solid var(--primary-color);
        }

        .stat-card.success {
            border-left-color: var(--primary-color);
        }

        .stat-card.info {
            border-left-color: var(--secondary-color);
        }

        .stat-card.warning {
            border-left-color: var(--warning-color);
        }

        .stat-card.danger {
            border-left-color: var(--danger-color);
        }

        .stat-number {
            font-size: 32px;
            font-weight: bold;
            color: var(--dark-color);
            margin: 10px 0;
        }

        .stat-label {
            color: #7f8c8d;
            font-size: 14px;
        }

        .stat-icon {
            font-size: 32px;
            margin-bottom: 10px;
        }

        .card {
            border: none;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }

        .badge-status {
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 500;
        }

        .badge-menunggu {
            background-color: #f8d7da;
            color: #721c24;
        }

        .badge-diverifikasi {
            background-color: #d1ecf1;
            color: #0c5460;
        }

        .badge-diterima {
            background-color: #d4edda;
            color: #155724;
        }

        .badge-selesai {
            background-color: #c3e6cb;
            color: #155724;
        }

        .badge-dibatalkan {
            background-color: #f5c6cb;
            color: #721c24;
        }

        .action-buttons {
            display: flex;
            gap: 5px;
        }

        .action-buttons .btn {
            padding: 6px 12px;
            font-size: 12px;
        }

        @media (max-width: 768px) {
            .sidebar {
                width: 200px;
            }
            .main-content {
                margin-left: 200px;
                padding: 15px;
            }
        }
    </style>
</head>
<body>
    <!-- Sidebar Navigation -->
    <div class="sidebar">
        <div class="brand">
            <i class="bi bi-gift"></i>
            <span>Admin Panel</span>
        </div>

        <nav class="nav flex-column">
            <a class="nav-link <?php echo (basename($_SERVER['PHP_SELF']) == 'dashboard.php') ? 'active' : ''; ?>" href="dashboard.php">
                <i class="bi bi-speedometer2"></i> Dashboard
            </a>
            <a class="nav-link <?php echo (basename($_SERVER['PHP_SELF']) == 'users.php') ? 'active' : ''; ?>" href="users.php">
                <i class="bi bi-people"></i> User Management
            </a>
            <a class="nav-link <?php echo (basename($_SERVER['PHP_SELF']) == 'donasi.php') ? 'active' : ''; ?>" href="donasi.php">
                <i class="bi bi-box"></i> Donasi Management
            </a>
            <a class="nav-link <?php echo (basename($_SERVER['PHP_SELF']) == 'kebutuhan.php') ? 'active' : ''; ?>" href="kebutuhan.php">
                <i class="bi bi-hand-thumbs-up"></i> Kebutuhan Management
            </a>
            <a class="nav-link <?php echo (basename($_SERVER['PHP_SELF']) == 'reports.php') ? 'active' : ''; ?>" href="reports.php">
                <i class="bi bi-bar-chart"></i> Reports
            </a>
            <a class="nav-link <?php echo (basename($_SERVER['PHP_SELF']) == 'settings.php') ? 'active' : ''; ?>" href="settings.php">
                <i class="bi bi-gear"></i> System Settings
            </a>
        </nav>

        <hr style="border-color: rgba(255,255,255,0.1); margin: 20px;">

        <nav class="nav flex-column">
            <a class="nav-link" href="profile.php">
                <i class="bi bi-person"></i> Profile
            </a>
            <a class="nav-link" href="../logout.php">
                <i class="bi bi-box-arrow-right"></i> Logout
            </a>
        </nav>
    </div>

    <!-- Main Content -->
    <div class="main-content">
        <!-- Topbar -->
        <div class="topbar">
            <h2><?php echo $page_title ?? 'Dashboard'; ?></h2>
            <div class="user-info">
                <div>
                    <div style="font-weight: 500;"><?php echo htmlspecialchars($admin_name); ?></div>
                    <div style="font-size: 12px; color: #7f8c8d;">Admin</div>
                </div>
                <div class="avatar"><?php echo strtoupper(substr($admin_name, 0, 1)); ?></div>
            </div>
        </div>
