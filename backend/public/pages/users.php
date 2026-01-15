<?php
session_start();
$page_title = 'User Management';
include '../includes/header.php';
include '../config/api.php';

$api = new ApiClient();
$api->setToken($_SESSION['api_token'] ?? '');

$action = $_GET['action'] ?? '';
$userId = $_GET['id'] ?? '';
$message = '';
$error = '';

// Fetch users dari API
$users = [];
$usersResponse = $api->get('/users');
if ($usersResponse['status'] == 200 && isset($usersResponse['data']['data'])) {
    $users = $usersResponse['data']['data'];
} else {
    // Fallback ke hardcoded jika API gagal
    $users = [
        ['id' => 1, 'nama' => 'Petugas', 'email' => 'petugas@gmail.com', 'no_hp' => '081234567890', 'role' => 'petugas', 'status' => 'aktif'],
        ['id' => 2, 'nama' => 'Admin', 'email' => 'admin@gmail.com', 'no_hp' => '082345678901', 'role' => 'admin', 'status' => 'aktif'],
        ['id' => 3, 'nama' => 'Donatur 1', 'email' => 'donatur1@gmail.com', 'no_hp' => '083456789012', 'role' => 'donatur', 'status' => 'aktif'],
        ['id' => 4, 'nama' => 'Penerima 1', 'email' => 'penerima1@gmail.com', 'no_hp' => '084567890123', 'role' => 'penerima', 'status' => 'aktif'],
    ];
}

// Handle form submission
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $post_action = $_POST['action'] ?? '';
    
    if ($post_action == 'add') {
        $newUser = [
            'nama' => $_POST['nama'] ?? '',
            'email' => $_POST['email'] ?? '',
            'no_hp' => $_POST['no_hp'] ?? '',
            'role' => $_POST['role'] ?? '',
            'password' => $_POST['password'] ?? 'password123' // Default password
        ];
        
        $result = $api->post('/users', $newUser);
        if ($result['status'] == 201 || $result['status'] == 200) {
            $message = '✓ User berhasil ditambahkan';
        } else {
            $error = $result['data']['message'] ?? 'Gagal menambah user';
        }
    } else if ($post_action == 'edit') {
        $editId = $_POST['user_id'] ?? '';
        $updateData = [
            'nama' => $_POST['nama'] ?? '',
            'no_hp' => $_POST['no_hp'] ?? '',
            'status' => $_POST['status'] ?? 'aktif'
        ];
        
        $result = $api->put("/users/$editId", $updateData);
        if ($result['status'] == 200) {
            $message = '✓ User berhasil diperbarui';
        } else {
            $error = $result['data']['message'] ?? 'Gagal mengubah user';
        }
    }
}

$message = $_GET['message'] ?? $message;
$error = $_GET['error'] ?? $error;
?>

<div class="row">
  <div class="col-md-12">
    <div class="card">
      <div class="card-header d-flex justify-content-between align-items-center">
        <h5 class="mb-0">Daftar Users</h5>
        <button type="button" class="btn btn-sm btn-primary" data-bs-toggle="modal" data-bs-target="#addUserModal">
          <i class="bi bi-plus-circle"></i> Tambah User
        </button>
      </div>
      <div class="card-body">
        <?php if ($message): ?>
        <div class="alert alert-success alert-dismissible fade show" role="alert">
          <?php echo htmlspecialchars($message); ?>
          <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <?php endif; ?>
        
        <?php if ($error): ?>
        <div class="alert alert-danger alert-dismissible fade show" role="alert">
          <?php echo htmlspecialchars($error); ?>
          <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <?php endif; ?>

        <div class="table-responsive">
          <table class="table table-hover">
            <thead class="table-light">
              <tr>
                <th>ID</th>
                <th>Nama</th>
                <th>Email</th>
                <th>No HP</th>
                <th>Role</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <?php foreach ($users as $user): ?>
              <tr>
                <td><?php echo $user['id']; ?></td>
                <td><?php echo htmlspecialchars($user['nama']); ?></td>
                <td><?php echo htmlspecialchars($user['email']); ?></td>
                <td><?php echo htmlspecialchars($user['no_hp']); ?></td>
                <td>
                  <span class="badge bg-info"><?php echo ucfirst($user['role']); ?></span>
                </td>
                <td>
                  <span class="badge bg-success"><?php echo ucfirst($user['status']); ?></span>
                </td>
                <td>
                  <div class="action-buttons">
                    <button class="btn btn-sm btn-warning" data-bs-toggle="modal" data-bs-target="#editUserModal"
                      onclick="editUser(<?php echo $user['id']; ?>)">
                      <i class="bi bi-pencil"></i>
                    </button>
                    <button class="btn btn-sm btn-danger" onclick="deleteUser(<?php echo $user['id']; ?>)">
                      <i class="bi bi-trash"></i>
                    </button>
                  </div>
                </td>
              </tr>
              <?php endforeach; ?>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- Add User Modal -->
<div class="modal fade" id="addUserModal" tabindex="-1">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title">Tambah User Baru</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <form method="POST">
        <div class="modal-body">
          <input type="hidden" name="action" value="add">
          <div class="mb-3">
            <label for="nama" class="form-label">Nama</label>
            <input type="text" class="form-control" id="nama" name="nama" required>
          </div>
          <div class="mb-3">
            <label for="email" class="form-label">Email</label>
            <input type="email" class="form-control" id="email" name="email" required>
          </div>
          <div class="mb-3">
            <label for="no_hp" class="form-label">No HP</label>
            <input type="text" class="form-control" id="no_hp" name="no_hp" required>
          </div>
          <div class="mb-3">
            <label for="role" class="form-label">Role</label>
            <select class="form-select" id="role" name="role" required>
              <option value="">-- Pilih Role --</option>
              <option value="donatur">Donatur</option>
              <option value="penerima">Penerima</option>
              <option value="petugas">Petugas</option>
              <option value="admin">Admin</option>
            </select>
          </div>
          <div class="mb-3">
            <label for="password" class="form-label">Password</label>
            <input type="password" class="form-control" id="password" name="password" placeholder="password123">
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Batal</button>
          <button type="submit" class="btn btn-primary">Simpan</button>
        </div>
      </form>
    </div>
  </div>
</div>

<!-- Edit User Modal -->
<div class="modal fade" id="editUserModal" tabindex="-1">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title">Edit User</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <form method="POST">
        <div class="modal-body">
          <input type="hidden" name="action" value="edit">
          <input type="hidden" id="edit_user_id" name="user_id">
          
          <div class="mb-3">
            <label for="edit_nama" class="form-label">Nama</label>
            <input type="text" class="form-control" id="edit_nama" name="nama" required>
          </div>
          <div class="mb-3">
            <label for="edit_email" class="form-label">Email</label>
            <input type="email" class="form-control" id="edit_email" disabled>
            <small class="text-muted">Email tidak dapat diubah</small>
          </div>
          <div class="mb-3">
            <label for="edit_no_hp" class="form-label">No HP</label>
            <input type="text" class="form-control" id="edit_no_hp" name="no_hp" required>
          </div>
          <div class="mb-3">
            <label for="edit_role" class="form-label">Role</label>
            <input type="text" class="form-control" id="edit_role" disabled>
            <small class="text-muted">Role tidak dapat diubah</small>
          </div>
          <div class="mb-3">
            <label for="edit_status" class="form-label">Status</label>
            <select class="form-select" id="edit_status" name="status">
              <option value="aktif">Aktif</option>
              <option value="nonaktif">Nonaktif</option>
              <option value="suspended">Suspended</option>
            </select>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Batal</button>
          <button type="submit" class="btn btn-primary">Simpan Perubahan</button>
        </div>
      </form>
    </div>
  </div>
</div>

<script>
let currentUser = null;

function editUser(userId) {
  // Find user in table
  const users = <?php echo json_encode($users); ?>;
  const user = users.find(u => u.id == userId);
  
  if (user) {
    currentUser = user;
    document.getElementById('edit_user_id').value = user.id;
    document.getElementById('edit_nama').value = user.nama;
    document.getElementById('edit_email').value = user.email;
    document.getElementById('edit_no_hp').value = user.no_hp;
    document.getElementById('edit_role').value = user.role;
    document.getElementById('edit_status').value = user.status || 'aktif';
    
    // Show modal
    const modal = new bootstrap.Modal(document.getElementById('editUserModal'));
    modal.show();
  } else {
    alert('User tidak ditemukan');
  }
}

function deleteUser(userId) {
  const users = <?php echo json_encode($users); ?>;
  const user = users.find(u => u.id == userId);
  
  if (!user) {
    alert('User tidak ditemukan');
    return;
  }
  
  if (confirm(`Yakin ingin menghapus user "${user.nama}"?\n\nTindakan ini tidak dapat dibatalkan.`)) {
    // Show loading
    const btn = event.target.closest('button');
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>';
    
    // Make delete request via fetch
    fetch('/pages/users-api.php?action=delete&id=' + userId, {
      method: 'GET'
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        alert('✓ User berhasil dihapus');
        location.reload();
      } else {
        alert('❌ ' + (data.message || 'Gagal menghapus user'));
        btn.disabled = false;
        btn.innerHTML = '<i class="bi bi-trash"></i>';
      }
    })
    .catch(error => {
      alert('Error: ' + error);
      btn.disabled = false;
      btn.innerHTML = '<i class="bi bi-trash"></i>';
    });
  }
}
</script>

<?php include '../includes/footer.php'; ?>