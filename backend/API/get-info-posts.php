<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);
require_once '../../config/db.php';

// Проверка на существование и корректность idauthor
if (!isset($_GET['idauthor']) || !is_numeric($_GET['idauthor'])) {
    http_response_code(400); // Bad Request
    echo json_encode(['error' => 'Invalid or missing idauthor']);
    exit;
}

$idauthor = intval($_GET['idauthor']);

try {
    $stmt = $pdo->prepare("SELECT * FROM posts WHERE idauthor = :idauthor");
    $stmt->execute(['idauthor' => $idauthor]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    header('Content-Type: application/json');
    echo json_encode($rows);
} catch (PDOException $e) {
    http_response_code(500); // Internal Server Error
    echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
}
?>