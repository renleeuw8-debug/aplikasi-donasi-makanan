<?php
session_start();
$page_title = 'Kebutuhan Management';
include '../includes/header.php';
include '../config/api.php';

$api = new ApiClient();
$api->setToken($_SESSION['api_token'] ?? '');

$filter = $_GET['filter'] ?? '';
$message = '';
$error = '';

// Get kebutuhan dari API
$kebutuhanRes = $api->get('/kebutuhan');
$kebutuhan_list = [];

// Check different response formats
if ($kebutuhanRes['status'] == 200) {
    // Try format 1: { status: 200, data: { data: { data: [...] } } }
    if (isset($kebutuhanRes['data']['data']['data']) && is_array($kebutuhanRes['data']['data']['data'])) {
        $kebutuhan_list = $kebutuhanRes['data']['data']['data'];
    } 
    // Try format 2: { data: { data: [...] } }
    else if (isset($kebutuhanRes['data']['data']) && is_array($kebutuhanRes['data']['data'])) {
        $kebutuhan_list = $kebutuhanRes['data']['data'];
    } 
    // Try format 3: { data: [...] }
    else if (isset($kebutuhanRes['data']) && is_array($kebutuhanRes['data'])) {
        $kebutuhan_list = $kebutuhanRes['data'];
    }
}

// Filter out incomplete entries (must have id)
if (!empty($kebutuhan_list)) {
    $kebutuhan_list = array_filter($kebutuhan_list, function($k) {
        return isset($k['id']) && !empty($k['id']);
    });
}

// Apply status filter
if ($filter) {
    $kebutuhan_list = array_filter($kebutuhan_list, function($k) use ($filter) {
        return ($k['status'] ?? 'aktif') === $filter;
    });
}

// Get count by status
$status_count = ['aktif' => 0, 'terpenuhi' => 0];
foreach ($kebutuhan_list as $k) {
    $status = $k['status'] ?? 'aktif';
    if (in_array($status, ['aktif', 'terpenuhi'])) {
        $status_count[$status]++;
    } else {
        // Default to 'aktif' untuk status tidak dikenal
        $status_count['aktif']++;
    }
}

// Handle actions via POST
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $action = $_POST['action'] ?? '';
    $kebutuhan_id = $_POST['kebutuhan_id'] ?? '';
    
    if ($action == 'fulfilled') {
        $result = $api->put("/kebutuhan/$kebutuhan_id", ['status' => 'terpenuhi']);
        if ($result['status'] == 200) {
            $message = '✓ Kebutuhan berhasil ditandai terpenuhi';
            // Reload halaman setelah 1.5 detik
            header("Refresh: 1.5; url=kebutuhan.php");
        } else {
            $error = $result['data']['message'] ?? 'Gagal update status';
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
      <a href="kebutuhan.php" class="btn btn-outline-secondary <?php echo !$filter ? 'active' : ''; ?>">
        Semua (<?php echo count($kebutuhan_list); ?>)
      </a>
      <a href="kebutuhan.php?filter=aktif"
        class="btn btn-outline-info <?php echo $filter == 'aktif' ? 'active' : ''; ?>">
        Aktif (<?php echo $status_count['aktif']; ?>)
      </a>
      <a href="kebutuhan.php?filter=terpenuhi"
        class="btn btn-outline-success <?php echo $filter == 'terpenuhi' ? 'active' : ''; ?>">
        Terpenuhi (<?php echo $status_count['terpenuhi']; ?>)
      </a>
    </div>
  </div>
</div>

<div class="card">
  <div class="card-header">
    <h5 class="mb-0">Daftar Kebutuhan</h5>
  </div>
  <div class="card-body">
    <div class="table-responsive">
      <table class="table table-hover">
        <thead class="table-light">
          <tr>
            <th>ID</th>
            <th>Jenis</th>
            <th>Deskripsi</th>
            <th>Jumlah</th>
            <th>Penerima</th>
            <th>Status</th>
            <th>Tanggal</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <?php foreach ($kebutuhan_list as $k): ?>
          <tr>
            <td>#<?php echo htmlspecialchars($k['id'] ?? '-'); ?></td>
            <td>
              <span class="badge bg-primary"><?php echo ucfirst($k['jenis_kebutuhan'] ?? ''); ?></span>
            </td>
            <td><?php echo htmlspecialchars(substr($k['deskripsi'] ?? '', 0, 50)); ?>...</td>
            <td><?php echo htmlspecialchars($k['jumlah'] ?? ''); ?></td>
            <td><?php echo htmlspecialchars($k['penerima_nama'] ?? 'N/A'); ?></td>
            <td>
              <?php 
                $status = $k['status'] ?? 'aktif';
                if ($status === 'aktif'): 
              ?>
              <span class="badge bg-warning">Aktif</span>
              <?php elseif ($status === 'terpenuhi'): ?>
              <span class="badge bg-success">Terpenuhi</span>
              <?php else: ?>
              <span class="badge bg-secondary"><?php echo ucfirst($status); ?></span>
              <?php endif; ?>
            </td>
            <td><?php echo isset($k['created_at']) ? date('d/m/Y', strtotime($k['created_at'])) : '-'; ?></td>
            <td>
              <div class="action-buttons">
                <a href="#" class="btn btn-sm btn-info" data-bs-toggle="modal" data-bs-target="#detailModal"
                  onclick="loadDetail(<?php echo htmlspecialchars($k['id'] ?? 0); ?>)">
                  <i class="bi bi-eye"></i>
                </a>
                <?php if (($k['status'] ?? '') === 'aktif'): ?>
                <button class="btn btn-sm btn-success"
                  onclick="markFulfilled(<?php echo htmlspecialchars($k['id'] ?? 0); ?>)">
                  <i class="bi bi-check-circle"></i>
                </button>
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
        <h5 class="modal-title">Detail Kebutuhan</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body" id="detailContent">
        Loading...
      </div>
    </div>
  </div>
</div>

<script>
// Store kebutuhan data for client-side access
const kebutuhanData = <?php echo json_encode($kebutuhan_list); ?>;

function loadDetail(id) {
  const kebutuhan = kebutuhanData.find(k => k.id == id);
  if (!kebutuhan) {
    document.getElementById('detailContent').innerHTML = '<p class="text-danger">Data tidak ditemukan</p>';
    return;
  }

  const created = new Date(kebutuhan.created_at).toLocaleDateString('id-ID');
  const html = `
    <div class="row">
      <div class="col-md-6">
        <h6 class="text-muted">Jenis Kebutuhan</h6>
        <p class="mb-3">${kebutuhan.jenis_kebutuhan}</p>
        
        <h6 class="text-muted">Deskripsi</h6>
        <p class="mb-3">${kebutuhan.deskripsi}</p>
        
        <h6 class="text-muted">Jumlah Kebutuhan</h6>
        <p class="mb-3">${kebutuhan.jumlah}</p>
      </div>
      <div class="col-md-6">
        <h6 class="text-muted">Nama Penerima</h6>
        <p class="mb-3"><strong>${kebutuhan.penerima_nama}</strong></p>
        
        <h6 class="text-muted">Email</h6>
        <p class="mb-3">${kebutuhan.penerima_email || '-'}</p>
        
        <h6 class="text-muted">No HP</h6>
        <p class="mb-3">${kebutuhan.penerima_no_hp || '-'}</p>
        
        <h6 class="text-muted">Status</h6>
        <p class="mb-3">
          <span class="badge ${kebutuhan.status == 'aktif' ? 'bg-info' : 'bg-success'}">
            ${kebutuhan.status == 'aktif' ? 'Aktif' : 'Terpenuhi'}
          </span>
        </p>
        
        <h6 class="text-muted">Tanggal Dibuat</h6>
        <p>${created}</p>
      </div>
    </div>
  `;
  document.getElementById('detailContent').innerHTML = html;
}

function markFulfilled(id) {
  if (confirm('Tandai kebutuhan sebagai terpenuhi?')) {
    const form = document.createElement('form');
    form.method = 'POST';
    form.innerHTML = `
      <input type="hidden" name="action" value="fulfilled">
      <input type="hidden" name="kebutuhan_id" value="${id}">
    `;
    document.body.appendChild(form);
    form.submit();
  }
}
</script>

<?php include '../includes/footer.php'; ?>