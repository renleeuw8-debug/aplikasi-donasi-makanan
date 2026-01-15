<?php
session_start();
$page_title = 'System Settings';
include '../includes/header.php';
include '../config/api.php';

$api = new ApiClient();
$api->setToken($_SESSION['api_token'] ?? '');

// Define kategori
$kategori_donasi = ['makanan', 'barang'];
$kategori_kebutuhan = ['makanan', 'pakaian', 'buku', 'kesehatan', 'barang', 'lainnya'];

$message = $_GET['message'] ?? '';
$error = $_GET['error'] ?? '';

// Load settings from file
$settings_file = '../data/settings.json';
$settings = [];
if (file_exists($settings_file)) {
    $settings = json_decode(file_get_contents($settings_file), true) ?? [];
}

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $action = $_POST['action'] ?? '';
    
    if ($action == 'add_kategori') {
        $type = $_POST['type'] ?? '';
        $name = $_POST['name'] ?? '';
        
        if ($type && $name) {
            // TODO: Call API to add kategori
            $message = 'Kategori berhasil ditambahkan';
        } else {
            $error = 'Semua field harus diisi';
        }
    } else if ($action == 'update_config') {
        // Simpan konfigurasi sistem
        $settings['app_name'] = $_POST['app_name'] ?? 'Aplikasi Donasi Makanan';
        $settings['app_url'] = $_POST['app_url'] ?? 'http://localhost:3000';
        $settings['max_upload'] = $_POST['max_upload'] ?? 10;
        $settings['verify_timeout'] = $_POST['verify_timeout'] ?? 24;
        $settings['timezone'] = $_POST['timezone'] ?? 'Asia/Jakarta';
        $settings['maintenance_mode'] = isset($_POST['maintenance_mode']) ? true : false;
        $settings['maintenance_msg'] = $_POST['maintenance_msg'] ?? '';
        
        // Buat direktori jika tidak ada
        if (!is_dir('../data')) {
            mkdir('../data', 0755, true);
        }
        
        // Simpan ke file JSON
        if (file_put_contents($settings_file, json_encode($settings, JSON_PRETTY_PRINT))) {
            $message = '✓ Konfigurasi sistem berhasil disimpan';
        } else {
            $error = '❌ Gagal menyimpan konfigurasi';
        }
    }
}
?>

<div class="row">
  <div class="col-md-12">
    <ul class="nav nav-tabs" role="tablist">
      <li class="nav-item">
        <a class="nav-link active" data-bs-toggle="tab" href="#kategori-tab">Kategori Management</a>
      </li>
      <li class="nav-item">
        <a class="nav-link" data-bs-toggle="tab" href="#notifikasi-tab">Notifikasi Settings</a>
      </li>
      <li class="nav-item">
        <a class="nav-link" data-bs-toggle="tab" href="#config-tab">Konfigurasi Sistem</a>
      </li>
    </ul>

    <div class="tab-content mt-4">
      <!-- TAB 1: KATEGORI MANAGEMENT -->
      <div id="kategori-tab" class="tab-pane fade show active">
        <div class="row">
          <div class="col-md-6">
            <div class="card">
              <div class="card-header">
                <h5 class="mb-0">Kategori Donasi</h5>
              </div>
              <div class="card-body">
                <div class="list-group mb-3">
                  <?php foreach ($kategori_donasi as $kat): ?>
                  <div class="list-group-item d-flex justify-content-between align-items-center">
                    <span><?php echo ucfirst($kat); ?></span>
                    <button class="btn btn-sm btn-danger" onclick="deleteKategori('donasi', '<?php echo $kat; ?>')">
                      <i class="bi bi-trash"></i>
                    </button>
                  </div>
                  <?php endforeach; ?>
                </div>

                <form method="POST">
                  <input type="hidden" name="action" value="add_kategori">
                  <input type="hidden" name="type" value="donasi">
                  <div class="input-group">
                    <input type="text" class="form-control" name="name" placeholder="Nama kategori baru" required>
                    <button class="btn btn-primary" type="submit">
                      <i class="bi bi-plus-circle"></i>
                    </button>
                  </div>
                </form>
              </div>
            </div>
          </div>

          <div class="col-md-6">
            <div class="card">
              <div class="card-header">
                <h5 class="mb-0">Kategori Kebutuhan</h5>
              </div>
              <div class="card-body">
                <div class="list-group mb-3">
                  <?php foreach ($kategori_kebutuhan as $kat): ?>
                  <div class="list-group-item d-flex justify-content-between align-items-center">
                    <span><?php echo ucfirst($kat); ?></span>
                    <button class="btn btn-sm btn-danger" onclick="deleteKategori('kebutuhan', '<?php echo $kat; ?>')">
                      <i class="bi bi-trash"></i>
                    </button>
                  </div>
                  <?php endforeach; ?>
                </div>

                <form method="POST">
                  <input type="hidden" name="action" value="add_kategori">
                  <input type="hidden" name="type" value="kebutuhan">
                  <div class="input-group">
                    <input type="text" class="form-control" name="name" placeholder="Nama kategori baru" required>
                    <button class="btn btn-primary" type="submit">
                      <i class="bi bi-plus-circle"></i>
                    </button>
                  </div>
                </form>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- TAB 2: NOTIFIKASI SETTINGS -->
      <div id="notifikasi-tab" class="tab-pane fade">
        <div class="card">
          <div class="card-header">
            <h5 class="mb-0">Konfigurasi Notifikasi</h5>
          </div>
          <div class="card-body">
            <form method="POST">
              <input type="hidden" name="action" value="update_notifikasi">

              <div class="mb-3">
                <div class="form-check">
                  <input class="form-check-input" type="checkbox" id="notify_donasi" checked>
                  <label class="form-check-label" for="notify_donasi">
                    Notifikasi donasi baru ke petugas
                  </label>
                </div>
              </div>

              <div class="mb-3">
                <div class="form-check">
                  <input class="form-check-input" type="checkbox" id="notify_verify" checked>
                  <label class="form-check-label" for="notify_verify">
                    Notifikasi donasi terverifikasi ke donatur
                  </label>
                </div>
              </div>

              <div class="mb-3">
                <div class="form-check">
                  <input class="form-check-input" type="checkbox" id="notify_receive" checked>
                  <label class="form-check-label" for="notify_receive">
                    Notifikasi donasi diterima ke donatur
                  </label>
                </div>
              </div>

              <div class="mb-3">
                <div class="form-check">
                  <input class="form-check-input" type="checkbox" id="notify_kebutuhan" checked>
                  <label class="form-check-label" for="notify_kebutuhan">
                    Notifikasi kebutuhan baru ke penerima
                  </label>
                </div>
              </div>

              <hr>

              <h6>Email Settings</h6>
              <div class="mb-3">
                <label for="smtp_host" class="form-label">SMTP Host</label>
                <input type="text" class="form-control" id="smtp_host" name="smtp_host" value="smtp.gmail.com">
              </div>

              <div class="mb-3">
                <label for="smtp_port" class="form-label">SMTP Port</label>
                <input type="number" class="form-control" id="smtp_port" name="smtp_port" value="587">
              </div>

              <div class="mb-3">
                <label for="smtp_user" class="form-label">SMTP Username</label>
                <input type="email" class="form-control" id="smtp_user" name="smtp_user" placeholder="your@email.com">
              </div>

              <div class="mb-3">
                <label for="smtp_pass" class="form-label">SMTP Password</label>
                <input type="password" class="form-control" id="smtp_pass" name="smtp_pass">
              </div>

              <button type="submit" class="btn btn-primary">
                <i class="bi bi-save"></i> Simpan Pengaturan
              </button>
            </form>
          </div>
        </div>
      </div>

      <!-- TAB 3: KONFIGURASI SISTEM -->
      <div id="config-tab" class="tab-pane fade">
        <div class="card">
          <div class="card-header">
            <h5 class="mb-0">Konfigurasi Sistem</h5>
          </div>
          <div class="card-body">
            <form method="POST">
              <input type="hidden" name="action" value="update_config">

              <div class="mb-3">
                <label for="app_name" class="form-label">Nama Aplikasi</label>
                <input type="text" class="form-control" id="app_name" name="app_name"
                  value="<?php echo htmlspecialchars($settings['app_name'] ?? 'Aplikasi Donasi Makanan'); ?>">
              </div>

              <div class="mb-3">
                <label for="app_url" class="form-label">URL Aplikasi</label>
                <input type="url" class="form-control" id="app_url" name="app_url"
                  value="<?php echo htmlspecialchars($settings['app_url'] ?? 'http://localhost:3000'); ?>">
              </div>

              <div class="mb-3">
                <label for="max_upload" class="form-label">Max Upload Size (MB)</label>
                <input type="number" class="form-control" id="max_upload" name="max_upload"
                  value="<?php echo $settings['max_upload'] ?? 10; ?>">
              </div>

              <div class="mb-3">
                <label for="verify_timeout" class="form-label">Verifikasi Timeout (jam)</label>
                <input type="number" class="form-control" id="verify_timeout" name="verify_timeout"
                  value="<?php echo $settings['verify_timeout'] ?? 24; ?>"
                  help="Donasi yang belum diverifikasi dalam jangka waktu ini akan otomatis dibatalkan">
              </div>

              <div class="mb-3">
                <label for="timezone" class="form-label">Timezone</label>
                <select class="form-select" id="timezone" name="timezone">
                  <option value="Asia/Jakarta"
                    <?php echo ($settings['timezone'] ?? '') === 'Asia/Jakarta' ? 'selected' : ''; ?>>Asia/Jakarta
                  </option>
                  <option value="Asia/Surabaya"
                    <?php echo ($settings['timezone'] ?? '') === 'Asia/Surabaya' ? 'selected' : ''; ?>>Asia/Surabaya
                  </option>
                  <option value="Asia/Bandung"
                    <?php echo ($settings['timezone'] ?? '') === 'Asia/Bandung' ? 'selected' : ''; ?>>Asia/Bandung
                  </option>
                </select>
              </div>

              <hr>
              <h6>Maintenance Mode</h6>
              <div class="mb-3">
                <div class="form-check form-switch">
                  <input class="form-check-input" type="checkbox" id="maintenance_mode" name="maintenance_mode"
                    <?php echo ($settings['maintenance_mode'] ?? false) ? 'checked' : ''; ?>>
                  <label class="form-check-label" for="maintenance_mode">
                    Enable Maintenance Mode
                  </label>
                </div>
              </div>

              <div class="mb-3">
                <label for="maintenance_msg" class="form-label">Pesan Maintenance</label>
                <textarea class="form-control" id="maintenance_msg" name="maintenance_msg" rows="3"
                  placeholder="Sistem sedang dalam pemeliharaan..."><?php echo htmlspecialchars($settings['maintenance_msg'] ?? ''); ?></textarea>
              </div>

              <button type="submit" class="btn btn-primary">
                <i class="bi bi-save"></i> Simpan Konfigurasi
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<script>
function deleteKategori(type, name) {
  if (confirm('Hapus kategori ini?')) {
    // TODO: Call API to delete kategori
    alert('Delete ' + type + ' kategori ' + name + ' - coming soon');
  }
}

// Auto refresh jika ada message
<?php if ($message): ?>
  setTimeout(() => {
    location.reload();
  }, 1500);
<?php endif; ?>
</script>

<?php include '../includes/footer.php'; ?>