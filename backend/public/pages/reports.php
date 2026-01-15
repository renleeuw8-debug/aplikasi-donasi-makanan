<?php
session_start();
$page_title = 'Reports';
include '../includes/header.php';
include '../config/api.php';

$api = new ApiClient();
$api->setToken($_SESSION['api_token'] ?? '');

// Get data untuk reports
$donasiRes = $api->get('/donasi');
$kebutuhanRes = $api->get('/kebutuhan');

$donasi_list = $donasiRes['data']['data'] ?? [];
$kebutuhan_list = $kebutuhanRes['data']['data'] ?? [];
?>

<div class="row mb-4">
  <div class="col-md-12">
    <div class="card">
      <div class="card-header">
        <h5 class="mb-0">Export Data</h5>
      </div>
      <div class="card-body">
        <div class="row">
          <div class="col-md-6">
            <a href="#" class="btn btn-outline-success w-100" onclick="exportToCSV('donasi')">
              <i class="bi bi-file-earmark-spreadsheet"></i> Export Donasi (CSV)
            </a>
          </div>
          <div class="col-md-6">
            <a href="#" class="btn btn-outline-primary w-100" onclick="printReport()">
              <i class="bi bi-printer"></i> Print Report
            </a>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<div class="row">
  <div class="col-md-6">
    <div class="card">
      <div class="card-header">
        <h5 class="mb-0">Analitik - Donasi berdasarkan Jenis</h5>
      </div>
      <div class="card-body">
        <?php 
                    $jenis_count = [];
                    foreach ($donasi_list as $d) {
                        $jenis = $d['jenis_donasi'] ?? 'unknown';
                        $jenis_count[$jenis] = ($jenis_count[$jenis] ?? 0) + 1;
                    }
                ?>
        <div class="table-responsive">
          <table class="table">
            <thead>
              <tr>
                <th>Jenis Donasi</th>
                <th>Jumlah</th>
                <th>Persentase</th>
              </tr>
            </thead>
            <tbody>
              <?php 
                                $total = count($donasi_list);
                                foreach ($jenis_count as $jenis => $count):
                                    $percentage = $total > 0 ? round(($count / $total) * 100, 2) : 0;
                            ?>
              <tr>
                <td><?php echo ucfirst($jenis); ?></td>
                <td><?php echo $count; ?></td>
                <td>
                  <div class="progress">
                    <div class="progress-bar" style="width: <?php echo $percentage; ?>%">
                      <?php echo $percentage; ?>%
                    </div>
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

<script>
function exportToCSV(type) {
  let data = [];
  let headers = [];
  let filename = '';

  if (type === 'donasi') {
    data = <?php echo json_encode($donasi_list); ?>;
    headers = ['ID', 'Jenis Donasi', 'Nama Barang', 'Jumlah', 'Donatur', 'Status', 'Tanggal'];
    filename = 'donasi-' + new Date().toISOString().slice(0, 10) + '.csv';
  } else if (type === 'kebutuhan') {
    data = <?php echo json_encode($kebutuhan_list); ?>;
    headers = ['ID', 'Jenis Kebutuhan', 'Deskripsi', 'Jumlah', 'Penerima', 'Status', 'Tanggal'];
    filename = 'kebutuhan-' + new Date().toISOString().slice(0, 10) + '.csv';
  }

  if (data.length === 0) {
    alert('Tidak ada data untuk di-export');
    return;
  }

  // Buat CSV content
  let csv = headers.join(',') + '\n';

  data.forEach(row => {
    let values = [];

    if (type === 'donasi') {
      values = [
        row.id || '',
        row.jenis_donasi || '',
        (row.nama_barang || '').replace(/,/g, ';'),
        row.jumlah || '',
        row.donatur_nama || '',
        row.status || '',
        row.created_at ? new Date(row.created_at).toLocaleDateString('id-ID') : ''
      ];
    }

    csv += values.map(v => `"${v}"`).join(',') + '\n';
  });

  // Download CSV
  const link = document.createElement('a');
  const blob = new Blob([csv], {
    type: 'text/csv;charset=utf-8;'
  });
  const url = URL.createObjectURL(blob);
  link.setAttribute('href', url);
  link.setAttribute('download', filename);
  link.style.visibility = 'hidden';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}

function printReport() {
  window.print();
}
</script>

<?php include '../includes/footer.php'; ?>