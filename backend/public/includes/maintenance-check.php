<?php
/**
 * Maintenance Mode Check
 * Dijalankan sebelum login untuk mengecek apakah sistem dalam maintenance mode
 */

$settings_file = __DIR__ . '/../data/settings.json';
$settings = [];

if (file_exists($settings_file)) {
    $settings = json_decode(file_get_contents($settings_file), true) ?? [];
}

// Check jika maintenance mode aktif
if ($settings['maintenance_mode'] ?? false) {
    // Izinkan akses hanya untuk halaman login admin atau halaman maintenance
    $current_page = basename($_SERVER['PHP_SELF']);
    $is_admin_login = strpos($_SERVER['REQUEST_URI'], 'admin') !== false || 
                      strpos($_SERVER['REQUEST_URI'], 'login') !== false;
    
    // Jika user sudah login sebagai admin, izinkan
    if (isset($_SESSION['admin_id']) || (isset($_SESSION['role']) && $_SESSION['role'] === 'admin')) {
        // Admin bisa akses
    } else {
        // Non-admin tidak bisa akses, tampilkan halaman maintenance
        $maintenance_msg = $settings['maintenance_msg'] ?? 'Sistem sedang dalam pemeliharaan. Mohon coba kembali nanti.';
        ?>
<!DOCTYPE html>
<html lang="id">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Maintenance Mode</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <style>
  body {
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 100vh;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  }

  .maintenance-container {
    text-align: center;
    background: white;
    padding: 50px;
    border-radius: 10px;
    box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
    max-width: 500px;
  }

  .maintenance-icon {
    font-size: 80px;
    margin-bottom: 20px;
  }

  h1 {
    color: #333;
    margin-bottom: 15px;
  }

  p {
    color: #666;
    font-size: 16px;
    margin-bottom: 30px;
  }

  .spinner {
    margin: 20px 0;
  }
  </style>
</head>

<body>
  <div class="maintenance-container">
    <div class="maintenance-icon">🔧</div>
    <h1>Maintenance Mode</h1>
    <p><?php echo htmlspecialchars($maintenance_msg); ?></p>
    <div class="spinner-border text-primary" role="status">
      <span class="visually-hidden">Loading...</span>
    </div>
    <p style="margin-top: 30px; font-size: 14px; color: #999;">
      Sistem akan kembali normal dalam beberapa saat...
    </p>
  </div>
</body>

</html>
<?php
        exit();
    }
}
?>