<?php
session_start();
$page_title = 'Profile';
include '../includes/header.php';

$admin_name = $_SESSION['admin_name'] ?? 'Admin';
$admin_email = $_SESSION['admin_email'] ?? 'admin@gmail.com';
$admin_role = $_SESSION['admin_role'] ?? 'admin';
$admin_id = $_SESSION['admin_id'] ?? 'admin_001';

$message = '';
$error = '';

// Handle file upload
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $action = $_POST['action'] ?? '';
    
    if ($action == 'update_profile') {
        $_SESSION['admin_name'] = $_POST['nama'] ?? $admin_name;
        $message = 'Profil berhasil diperbarui';
        $admin_name = $_SESSION['admin_name'];
    } else if ($action == 'change_password') {
        $old_password = $_POST['old_password'] ?? '';
        $new_password = $_POST['new_password'] ?? '';
        $confirm_password = $_POST['confirm_password'] ?? '';
        
        if ($new_password !== $confirm_password) {
            $error = 'Password baru tidak cocok';
        } else {
            // TODO: Verify old password and update
            $message = 'Password berhasil diubah';
        }
    } else if ($action == 'upload_photo' && isset($_FILES['photo'])) {
        $file = $_FILES['photo'];
        
        // Validasi file
        $allowed_ext = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
        $file_ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
        $file_size = $file['size'];
        $max_size = 5 * 1024 * 1024; // 5MB
        
        if (!in_array($file_ext, $allowed_ext)) {
            $error = 'Format file tidak diizinkan. Gunakan: JPG, PNG, WEBP, GIF';
        } else if ($file_size > $max_size) {
            $error = 'Ukuran file terlalu besar. Maksimal 5MB';
        } else {
            // Buat folder uploads jika belum ada
            $uploads_dir = '../uploads/admin';
            if (!is_dir($uploads_dir)) {
                mkdir($uploads_dir, 0755, true);
            }
            
            // Generate unique filename
            $filename = 'admin_' . time() . '.' . $file_ext;
            $filepath = $uploads_dir . '/' . $filename;
            
            if (move_uploaded_file($file['tmp_name'], $filepath)) {
                // Hapus file lama jika ada
                $old_photo = $_SESSION['admin_photo'] ?? '';
                if ($old_photo && file_exists('../uploads/admin/' . $old_photo)) {
                    unlink('../uploads/admin/' . $old_photo);
                }
                
                $_SESSION['admin_photo'] = $filename;
                $message = '✓ Foto profil berhasil diupload';
            } else {
                $error = 'Gagal mengupload file. Cek permissions folder uploads';
            }
        }
    }
}

$admin_photo = $_SESSION['admin_photo'] ?? '';
?>


<div class="row">
  <div class="col-md-8">
    <div class="card mb-4">
      <div class="card-header">
        <h5 class="mb-0">Informasi Profil</h5>
      </div>
      <div class="card-body">
        <?php if ($message): ?>
        <div class="alert alert-success alert-dismissible fade show" role="alert">
          <?php echo htmlspecialchars($message); ?>
          <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <?php endif; ?>

        <form method="POST">
          <input type="hidden" name="action" value="update_profile">

          <div class="mb-3">
            <label for="nama" class="form-label">Nama Lengkap</label>
            <input type="text" class="form-control" id="nama" name="nama"
              value="<?php echo htmlspecialchars($admin_name); ?>" required>
          </div>

          <div class="mb-3">
            <label for="email" class="form-label">Email</label>
            <input type="email" class="form-control" id="email" value="<?php echo htmlspecialchars($admin_email); ?>"
              disabled>
            <small class="text-muted">Email tidak dapat diubah</small>
          </div>

          <div class="mb-3">
            <label for="role" class="form-label">Role</label>
            <input type="text" class="form-control" id="role" value="<?php echo ucfirst($admin_role); ?>" disabled>
          </div>

          <button type="submit" class="btn btn-primary">
            <i class="bi bi-save"></i> Simpan Profil
          </button>
        </form>
      </div>
    </div>

    <div class="card">
      <div class="card-header">
        <h5 class="mb-0">Ubah Password</h5>
      </div>
      <div class="card-body">
        <?php if ($error): ?>
        <div class="alert alert-danger alert-dismissible fade show" role="alert">
          <?php echo htmlspecialchars($error); ?>
          <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <?php endif; ?>

        <form method="POST">
          <input type="hidden" name="action" value="change_password">

          <div class="mb-3">
            <label for="old_password" class="form-label">Password Lama</label>
            <input type="password" class="form-control" id="old_password" name="old_password" required>
          </div>

          <div class="mb-3">
            <label for="new_password" class="form-label">Password Baru</label>
            <input type="password" class="form-control" id="new_password" name="new_password" required>
          </div>

          <div class="mb-3">
            <label for="confirm_password" class="form-label">Konfirmasi Password</label>
            <input type="password" class="form-control" id="confirm_password" name="confirm_password" required>
          </div>

          <button type="submit" class="btn btn-primary">
            <i class="bi bi-lock"></i> Ubah Password
          </button>
        </form>
      </div>
    </div>
  </div>

  <div class="col-md-4">
    <div class="card mb-4">
      <div class="card-body text-center">
        <div style="position: relative; display: inline-block;">
          <?php if ($admin_photo && file_exists('../uploads/admin/' . $admin_photo)): ?>
          <img src="../uploads/admin/<?php echo htmlspecialchars($admin_photo); ?>?t=<?php echo time(); ?>" 
               alt="Admin Photo" 
               style="width: 120px; height: 120px; border-radius: 50%; object-fit: cover; border: 3px solid #667eea;">
          <?php else: ?>
          <div class="avatar mx-auto"
            style="width: 120px; height: 120px; background: #667eea; color: white; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 48px; font-weight: bold;">
            <?php echo strtoupper(substr($admin_name, 0, 1)); ?>
          </div>
          <?php endif; ?>
          
          <!-- Upload Overlay Button -->
          <button type="button" 
                  class="btn btn-sm btn-warning" 
                  data-bs-toggle="modal" 
                  data-bs-target="#uploadPhotoModal"
                  style="position: absolute; bottom: -5px; right: -5px; border-radius: 50%; width: 40px; height: 40px; padding: 0; display: flex; align-items: center; justify-content: center;">
            <i class="bi bi-camera-fill" style="font-size: 16px;"></i>
          </button>
        </div>
        
        <h5 class="mt-4"><?php echo htmlspecialchars($admin_name); ?></h5>
        <p class="text-muted mb-3"><?php echo htmlspecialchars($admin_email); ?></p>
        <span class="badge bg-primary"><?php echo ucfirst($admin_role); ?></span>
      </div>
    </div>

    <div class="card">
      <div class="card-header">
        <h6 class="mb-0">Informasi Akun</h6>
      </div>
      <div class="card-body">
        <p class="mb-2">
          <small class="text-muted">Member Sejak:</small><br>
          <strong>11 Januari 2026</strong>
        </p>
        <p>
          <small class="text-muted">Last Login:</small><br>
          <strong>Hari ini, 18:00</strong>
        </p>
      </div>
    </div>
  </div>
</div>

<!-- Modal Upload Foto -->
<div class="modal fade" id="uploadPhotoModal" tabindex="-1">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title">Upload Foto Profil</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <form method="POST" enctype="multipart/form-data">
        <div class="modal-body">
          <input type="hidden" name="action" value="upload_photo">
          
          <div class="mb-3">
            <label for="photo" class="form-label">Pilih Foto</label>
            <input type="file" 
                   class="form-control" 
                   id="photo" 
                   name="photo" 
                   accept="image/*" 
                   required>
            <small class="text-muted d-block mt-2">
              ✓ Format: JPG, PNG, WEBP, GIF<br>
              ✓ Ukuran maksimal: 5MB
            </small>
          </div>
          
          <div id="preview-container" class="text-center mb-3" style="display: none;">
            <img id="preview" src="" alt="Preview" style="max-width: 100%; max-height: 300px; border-radius: 8px;">
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Batal</button>
          <button type="submit" class="btn btn-primary">
            <i class="bi bi-upload"></i> Upload
          </button>
        </div>
      </form>
    </div>
  </div>
</div>

<script>
document.getElementById('photo').addEventListener('change', function(e) {
  const file = e.target.files[0];
  if (file) {
    const reader = new FileReader();
    reader.onload = function(event) {
      document.getElementById('preview').src = event.target.result;
      document.getElementById('preview-container').style.display = 'block';
    };
    reader.readAsDataURL(file);
  }
});
</script>

<?php include '../includes/footer.php'; ?>