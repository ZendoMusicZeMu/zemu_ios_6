<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);
require_once '../../config/db.php';

$id = isset($_GET['id']) ? $_GET['id'] : '';

$stmt = $pdo->prepare("SELECT id, username, CheckMark, developer, icon, telegram FROM users WHERE id = :id");
$stmt->execute(['id' => $id]);
$rows = $stmt->fetchAll();

header('Content-Type: application/json');
echo json_encode($rows);
?>