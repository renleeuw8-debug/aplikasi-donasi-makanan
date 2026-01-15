<?php
session_start();

// Check maintenance mode
include 'includes/maintenance-check.php';

// Jika sudah login, redirect ke dashboard
if (isset($_SESSION['admin_id'])) {
    header('Location: pages/dashboard.php');
    exit;
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $email = $_POST['email'] ?? '';
    $password = $_POST['password'] ?? '';

    if (empty($email) || empty($password)) {
        $error = 'Email dan password tidak boleh kosong';
    } else {
        // Authenticate dengan Backend API
        $api_url = 'http://localhost:3000/api/auth/login';
        
        $postData = json_encode([
            'email' => $email,
            'password' => $password
        ]);
        
        $ch = curl_init($api_url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $postData);
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        curl_setopt($ch, CURLOPT_TIMEOUT, 5);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        // Debug logging
        error_log("Login attempt - Email: $email, HTTP Code: $httpCode");
        error_log("Response: " . substr($response, 0, 500));
        
        if ($httpCode === 200) {
            $data = json_decode($response, true);
            error_log("Decoded response: " . json_encode($data));
            
            if (isset($data['user']) && isset($data['token'])) {
                $user = $data['user'];
                error_log("User found: " . json_encode($user));
                
                // Check role - hanya admin & petugas yang bisa akses web panel
                if ($user['role'] !== 'admin' && $user['role'] !== 'petugas') {
                    $error = 'Anda tidak memiliki akses ke admin panel (Role: ' . $user['role'] . ')';
                } else {
                    // Set session
                    $_SESSION['admin_id'] = $user['id'];
                    $_SESSION['admin_name'] = $user['nama'];
                    $_SESSION['admin_email'] = $user['email'];
                    $_SESSION['admin_role'] = $user['role'];
                    $_SESSION['api_token'] = $data['token'];
                    
                    error_log("Login successful for: " . $email);
                    header('Location: pages/dashboard.php');
                    exit;
                }
            } else {
                error_log("Invalid response structure: " . json_encode($data));
                $error = 'Format response tidak valid dari server. Hubungi administrator.';
            }
        } else if ($httpCode === 401) {
            $error = 'Email atau password salah';
        } else if ($httpCode === 0) {
            $error = 'Tidak bisa terhubung ke server backend. Pastikan server running di http://localhost:3000';
        } else {
            error_log("HTTP Error: $httpCode - Response: $response");
            $error = 'Terjadi kesalahan (HTTP ' . $httpCode . '). Cek backend server.';
        }
    }
}
?>

<!DOCTYPE html>
<html lang="id">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Login - Admin Panel Donasi Makanan</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css" rel="stylesheet">
  <style>
  body {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    display: flex;
    justify-content: center;
    align-items: center;
    height: 100vh;
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  }

  .login-container {
    background: white;
    padding: 40px;
    border-radius: 10px;
    box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
    width: 100%;
    max-width: 400px;
  }

  .login-header {
    text-align: center;
    margin-bottom: 30px;
  }

  .login-header h1 {
    color: #667eea;
    font-size: 28px;
    margin-bottom: 10px;
  }

  .login-header p {
    color: #7f8c8d;
    font-size: 14px;
  }

  .form-group {
    margin-bottom: 20px;
  }

  .form-control {
    padding: 12px;
    border: 1px solid #ddd;
    border-radius: 5px;
    font-size: 14px;
  }

  .form-control:focus {
    border-color: #667eea;
    box-shadow: 0 0 0 0.2rem rgba(102, 126, 234, 0.25);
  }

  .btn-login {
    background: #667eea;
    border: none;
    padding: 12px;
    font-weight: 600;
    width: 100%;
    border-radius: 5px;
  }

  .btn-login:hover {
    background: #5568d3;
  }

  .alert-danger {
    margin-bottom: 20px;
    border: none;
    background-color: #f8d7da;
    border-radius: 5px;
  }

  .demo-credentials {
    background: #f0f8ff;
    padding: 15px;
    border-radius: 5px;
    margin-top: 20px;
    border-left: 4px solid #667eea;
  }

  .demo-credentials h6 {
    color: #667eea;
    font-size: 12px;
    margin-bottom: 10px;
    margin-top: 0;
  }

  .demo-credentials p {
    margin: 5px 0;
    font-size: 13px;
    color: #555;
  }
  </style>
</head>

<body>
  <div class="login-container">
    <div class="login-header">
      <h1><i class="bi bi-shield-lock"></i></h1>
      <h1>Admin Panel</h1>
      <p>Aplikasi Donasi Makanan</p>
    </div>

    <?php if ($error): ?>
    <div class="alert alert-danger alert-dismissible fade show" role="alert">
      <i class="bi bi-exclamation-circle"></i> <?php echo htmlspecialchars($error); ?>
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
    <?php endif; ?>

    <form method="POST">
      <div class="form-group">
        <label for="email" class="form-label">Email</label>
        <input type="email" class="form-control" id="email" name="email" placeholder="Masukkan email" required>
      </div>

      <div class="form-group">
        <label for="password" class="form-label">Password</label>
        <input type="password" class="form-control" id="password" name="password" placeholder="Masukkan password"
          required>
      </div>

      <button type="submit" class="btn btn-primary btn-login">
        <i class="bi bi-box-arrow-in-right"></i> Login
      </button>
    </form>


  </div>

  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>

</html>