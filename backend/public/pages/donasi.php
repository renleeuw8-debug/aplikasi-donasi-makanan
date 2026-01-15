<?php
session_start();
$page_title = 'Donasi Management';
include '../includes/header.php';
include '../config/api.php';

$api = new ApiClient();
$api->setToken($_SESSION['api_token'] ?? '');

$filter = $_GET['filter'] ?? '';
$message = '';
$error = '';

// Get donasi dari API
$donasiRes = $api->get('/donasi');
$donasi_list = [];

if ($donasiRes['status'] == 200 && isset($donasiRes['data']['data'])) {
    $donasi_list = $donasiRes['data']['data'];
    
    // Apply filter
    if ($filter) {
        $donasi_list = array_filter($donasi_list, function($d) use ($filter) {
            return ($d['status'] ?? '') === $filter;
        });
    }
}

// Get count by status
$status_count = ['menunggu' => 0, 'diverifikasi' => 0, 'diterima' => 0, 'selesai' => 0];
foreach ($donasi_list as $d) {
    $status = $d['status'] ?? 'menunggu';
    if (isset($status_count[$status])) {
        $status_count[$status]++;
    }
}

// Handle actions via POST
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $action = $_POST['action'] ?? '';
    $donasi_id = $_POST['donasi_id'] ?? '';
    
    if ($action == 'verify') {
        $result = $api->post("/donasi/$donasi_id/verify", []);
        if ($result['status'] == 200) {
            $message = '✓ Donasi berhasil diverifikasi';
        } else {
            $error = $result['data']['message'] ?? 'Gagal verifikasi donasi';
        }
    } else if ($action == 'receive') {
        $result = $api->post("/donasi/$donasi_id/receive", []);
        if ($result['status'] == 200) {
            $message = '✓ Donasi berhasil ditandai diterima';
        } else {
            $error = $result['data']['message'] ?? 'Gagal update status';
        }
    } else if ($action == 'complete') {
        $result = $api->post("/donasi/$donasi_id/complete", []);
        if ($result['status'] == 200) {
            $message = '✓ Donasi berhasil diselesaikan';
        } else {
            $error = $result['data']['message'] ?? 'Gagal selesaikan donasi';
        }
    }
}
?>

<div class="row mb-3">
  <div class="col-md-12">
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

    <div class="btn-group" role="group">
      <a href="donasi.php" class="btn btn-outline-secondary <?php echo !$filter ? 'active' : ''; ?>">
        Semua (<?php echo count($donasi_list); ?>)
      </a>
      <a href="donasi.php?filter=menunggu"
        class="btn btn-outline-warning <?php echo $filter == 'menunggu' ? 'active' : ''; ?>">
        Menunggu (<?php echo $status_count['menunggu']; ?>)
      </a>
      <a href="donasi.php?filter=diverifikasi"
        class="btn btn-outline-info <?php echo $filter == 'diverifikasi' ? 'active' : ''; ?>">
        Diverifikasi (<?php echo $status_count['diverifikasi']; ?>)
      </a>
      <a href="donasi.php?filter=diterima"
        class="btn btn-outline-success <?php echo $filter == 'diterima' ? 'active' : ''; ?>">
        Diterima (<?php echo $status_count['diterima']; ?>)
      </a>
    </div>
  </div>
</div>

<div class="card">
  <div class="card-header">
    <h5 class="mb-0">Daftar Donasi</h5>
  </div>
  <div class="card-body">
    <div class="table-responsive">
      <table class="table table-hover">
        <thead class="table-light">
          <tr>
            <th>ID</th>
            <th>Nama Barang</th>
            <th>Jenis</th>
            <th>Jumlah</th>
            <th>Donatur</th>
            <th>Status</th>
            <th>Tanggal</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <?php foreach ($donasi_list as $d): ?>
          <tr>
            <td>#<?php echo $d['id']; ?></td>
            <td><?php echo htmlspecialchars($d['nama_barang']); ?></td>
            <td>
              <span class="badge bg-primary"><?php echo ucfirst($d['jenis_donasi']); ?></span>
            </td>
            <td><?php echo $d['jumlah']; ?></td>
            <td><?php echo htmlspecialchars($d['donatur_nama'] ?? 'N/A'); ?></td>
            <td>
              <span class="badge-status badge-<?php echo $d['status']; ?>">
                <?php 
                                    $status_text = [
                                        'menunggu' => 'Menunggu',
                                        'diverifikasi' => 'Diverifikasi',
                                        'diterima' => 'Diterima',
                                        'selesai' => 'Selesai',
                                        'dibatalkan' => 'Dibatalkan'
                                    ];
                                    echo $status_text[$d['status']] ?? $d['status'];
                                ?>
              </span>
            </td>
            <td><?php echo date('d/m/Y', strtotime($d['created_at'])); ?></td>
            <td>
              <div class="action-buttons">
                <a href="#" class="btn btn-sm btn-info" data-bs-toggle="modal" data-bs-target="#detailModal"
                  onclick="loadDetail(<?php echo $d['id']; ?>); return false;">
                  <i class="bi bi-eye"></i>
                </a>
                <?php if ($d['status'] === 'menunggu'): ?>
                <form method="POST" style="display:inline;">
                  <input type="hidden" name="action" value="verify">
                  <input type="hidden" name="donasi_id" value="<?php echo $d['id']; ?>">
                  <button type="submit" class="btn btn-sm btn-success"
                    onclick="return confirm('Verifikasi donasi ini?')">
                    <i class="bi bi-check-circle"></i>
                  </button>
                </form>
                <?php endif; ?>
                <?php if ($d['status'] === 'diverifikasi'): ?>
                <form method="POST" style="display:inline;">
                  <input type="hidden" name="action" value="receive">
                  <input type="hidden" name="donasi_id" value="<?php echo $d['id']; ?>">
                  <button type="submit" class="btn btn-sm btn-warning"
                    onclick="return confirm('Tandai sebagai diterima?')">
                    <i class="bi bi-box-seam"></i>
                  </button>
                </form>
                <?php endif; ?>
                <?php if ($d['status'] === 'diterima'): ?>
                <form method="POST" style="display:inline;">
                  <input type="hidden" name="action" value="complete">
                  <input type="hidden" name="donasi_id" value="<?php echo $d['id']; ?>">
                  <button type="submit" class="btn btn-sm btn-primary"
                    onclick="return confirm('Selesaikan donasi ini?')">
                    <i class="bi bi-check-all"></i>
                  </button>
                </form>
                <?php endif; ?>
              </div>
            </td>
          </tr>
          <?php endforeach; ?>
        </tbody>
      </table>
    </div>
  </div>
</div>

<!-- Detail Modal -->
<div class="modal fade" id="detailModal" tabindex="-1">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title">Detail Donasi</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body" id="detailContent">
        Loading...
      </div>
    </div>
  </div>
</div>

<script>
function loadDetail(id) {
  const donasi_list = <?php echo json_encode($donasi_list); ?>;
  const donasi = donasi_list.find(d => d.id == id);

  if (!donasi) {
    document.getElementById('detailContent').innerHTML =
      '<div class="alert alert-danger">Data donasi tidak ditemukan</div>';
    return;
  }

  const createdAt = new Date(donasi.created_at).toLocaleDateString('id-ID', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });

  const html = `
    <div class="row">
      <div class="col-md-6">
        <h6 class="text-muted">Informasi Donasi</h6>
        <p>
          <strong>ID Donasi:</strong> #${donasi.id}<br>
          <strong>Nama Barang:</strong> ${donasi.nama_barang}<br>
          <strong>Jenis:</strong> ${donasi.jenis_donasi}<br>
          <strong>Jumlah:</strong> ${donasi.jumlah}<br>
          <strong>Keterangan:</strong> ${donasi.keterangan || '-'}<br>
        </p>
      </div>
      <div class="col-md-6">
        <h6 class="text-muted">Informasi Donatur</h6>
        <p>
          <strong>Nama:</strong> ${donasi.donatur_nama || '-'}<br>
          <strong>Email:</strong> ${donasi.donatur_email || '-'}<br>
          <strong>No HP:</strong> ${donasi.donatur_no_hp || '-'}<br>
        </p>
      </div>
    </div>
    <div class="row mt-3">
      <div class="col-md-12">
        <h6 class="text-muted">Status & Tanggal</h6>
        <p>
          <strong>Status:</strong> <span class="badge badge-${donasi.status}">${donasi.status}</span><br>
          <strong>Tanggal Dibuat:</strong> ${createdAt}<br>
          ${donasi.foto_url ? `<strong>Foto:</strong> <img src="${donasi.foto_url}" alt="Donasi" style="max-width: 200px; border-radius: 8px; margin-top: 10px;">` : ''}
        </p>
      </div>
    </div>
  `;

  document.getElementById('detailContent').innerHTML = html;
}
</script>

<?php include '../includes/footer.php'; ?>