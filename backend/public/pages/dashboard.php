<?php
session_start();
$page_title = 'Dashboard';
include '../includes/header.php';
include '../config/api.php';

$api = new ApiClient();
$api->setToken($_SESSION['api_token'] ?? '');

// Get dashboard stats
$donasiRes = $api->get('/donasi');
$kebutuhanRes = $api->get('/kebutuhan');

// Calculate stats
$donasiStats = [
    'total' => 0,
    'menunggu' => 0,
    'diverifikasi' => 0,
    'diterima' => 0,
    'selesai' => 0
];

$kebutuhanStats = [
    'total' => 0,
    'aktif' => 0,
    'terpenuhi' => 0
];

if ($donasiRes['status'] == 200 && isset($donasiRes['data']['data'])) {
    foreach ($donasiRes['data']['data'] as $d) {
        $donasiStats['total']++;
        $status = $d['status'] ?? 'menunggu';
        if (isset($donasiStats[$status])) {
            $donasiStats[$status]++;
        }
    }
}

if ($kebutuhanRes['status'] == 200 && isset($kebutuhanRes['data']['data'])) {
    foreach ($kebutuhanRes['data']['data'] as $k) {
        $kebutuhanStats['total']++;
        $status = $k['status'] ?? 'aktif';
        if (isset($kebutuhanStats[$status])) {
            $kebutuhanStats[$status]++;
        }
    }
}
?>

<div class="row">
    <div class="col-md-3 col-sm-6">
        <div class="stat-card success">
            <div style="display: flex; justify-content: space-between; align-items: flex-start;">
                <div>
                    <div class="stat-label">Total Donasi</div>
                    <div class="stat-number"><?php echo $donasiStats['total']; ?></div>
                </div>
                <div class="stat-icon" style="color: #2ecc71;">
                    <i class="bi bi-box"></i>
                </div>
            </div>
        </div>
    </div>

    <div class="col-md-3 col-sm-6">
        <div class="stat-card warning">
            <div style="display: flex; justify-content: space-between; align-items: flex-start;">
                <div>
                    <div class="stat-label">Menunggu Verifikasi</div>
                    <div class="stat-number"><?php echo $donasiStats['menunggu']; ?></div>
                </div>
                <div class="stat-icon" style="color: #f39c12;">
                    <i class="bi bi-clock"></i>
                </div>
            </div>
        </div>
    </div>

    <div class="col-md-3 col-sm-6">
        <div class="stat-card info">
            <div style="display: flex; justify-content: space-between; align-items: flex-start;">
                <div>
                    <div class="stat-label">Total Kebutuhan</div>
                    <div class="stat-number"><?php echo $kebutuhanStats['total']; ?></div>
                </div>
                <div class="stat-icon" style="color: #3498db;">
                    <i class="bi bi-hand-thumbs-up"></i>
                </div>
            </div>
        </div>
    </div>

    <div class="col-md-3 col-sm-6">
        <div class="stat-card" style="border-left-color: #2ecc71;">
            <div style="display: flex; justify-content: space-between; align-items: flex-start;">
                <div>
                    <div class="stat-label">Kebutuhan Terpenuhi</div>
                    <div class="stat-number"><?php echo $kebutuhanStats['terpenuhi']; ?></div>
                </div>
                <div class="stat-icon" style="color: #2ecc71;">
                    <i class="bi bi-check-circle"></i>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="row mt-4">
    <div class="col-md-6">
        <div class="card">
            <div class="card-header bg-primary text-white">
                <h5 class="mb-0">Status Donasi</h5>
            </div>
            <div class="card-body">
                <div class="row text-center">
                    <div class="col-md-6">
                        <div style="padding: 15px;">
                            <div style="font-size: 28px; font-weight: bold; color: #f39c12;">
                                <?php echo $donasiStats['menunggu']; ?>
                            </div>
                            <div style="color: #7f8c8d;">Menunggu</div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div style="padding: 15px;">
                            <div style="font-size: 28px; font-weight: bold; color: #3498db;">
                                <?php echo $donasiStats['diverifikasi']; ?>
                            </div>
                            <div style="color: #7f8c8d;">Diverifikasi</div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div style="padding: 15px;">
                            <div style="font-size: 28px; font-weight: bold; color: #2ecc71;">
                                <?php echo $donasiStats['diterima']; ?>
                            </div>
                            <div style="color: #7f8c8d;">Diterima</div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div style="padding: 15px;">
                            <div style="font-size: 28px; font-weight: bold; color: #27ae60;">
                                <?php echo $donasiStats['selesai']; ?>
                            </div>
                            <div style="color: #7f8c8d;">Selesai</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="col-md-6">
        <div class="card">
            <div class="card-header bg-success text-white">
                <h5 class="mb-0">Status Kebutuhan</h5>
            </div>
            <div class="card-body">
                <div class="row text-center">
                    <div class="col-md-6">
                        <div style="padding: 20px;">
                            <div style="font-size: 28px; font-weight: bold; color: #3498db;">
                                <?php echo $kebutuhanStats['aktif']; ?>
                            </div>
                            <div style="color: #7f8c8d;">Aktif</div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div style="padding: 20px;">
                            <div style="font-size: 28px; font-weight: bold; color: #2ecc71;">
                                <?php echo $kebutuhanStats['terpenuhi']; ?>
                            </div>
                            <div style="color: #7f8c8d;">Terpenuhi</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="card mt-4">
    <div class="card-header">
        <h5 class="mb-0">Quick Actions</h5>
    </div>
    <div class="card-body">
        <div class="row">
            <div class="col-md-3">
                <a href="donasi.php?filter=menunggu" class="btn btn-outline-warning w-100">
                    <i class="bi bi-exclamation-circle"></i> Verifikasi Donasi
                </a>
            </div>
            <div class="col-md-3">
                <a href="kebutuhan.php" class="btn btn-outline-info w-100">
                    <i class="bi bi-hand-thumbs-up"></i> Lihat Kebutuhan
                </a>
            </div>
            <div class="col-md-3">
                <a href="users.php" class="btn btn-outline-primary w-100">
                    <i class="bi bi-people"></i> Kelola Users
                </a>
            </div>
            <div class="col-md-3">
                <a href="settings.php" class="btn btn-outline-secondary w-100">
                    <i class="bi bi-gear"></i> System Settings
                </a>
            </div>
        </div>
    </div>
</div>

<?php include '../includes/footer.php'; ?>
