<?php
session_start();
header('Content-Type: application/json');
include '../config/api.php';

$api = new ApiClient();
$api->setToken($_SESSION['api_token'] ?? '');

$action = $_GET['action'] ?? '';
$userId = $_GET['id'] ?? '';

if ($action == 'delete' && $userId) {
    $result = $api->delete("/users/$userId");
    
    if ($result['status'] == 200) {
        echo json_encode([
            'success' => true,
            'message' => 'User berhasil dihapus'
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => $result['data']['message'] ?? 'Gagal menghapus user'
        ]);
    }
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid request'
    ]);
}
?>
