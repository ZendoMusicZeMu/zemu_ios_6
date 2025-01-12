<?php
session_start();
require_once '../../config/db.php';
require_once '../config/config.php';

$login = isset($_GET['login']) ? $_GET['login'] : '';
$password = isset($_GET['password']) ? $_GET['password'] : '';

$query = "SELECT * FROM users WHERE username = ?";
$stmt = $pdo->prepare($query);
$stmt->execute([$login]);
$results = $stmt->fetchAll(PDO::FETCH_ASSOC);

if ($stmt->rowCount() == 0) {
    header("HTTP/1.0 404 Not Found");
    die();
}

foreach ($results as $result) {
    $id = $result["id"];
    $username = $result["username"];
    $icon = $websiteurl . substr($result["icon"], 6);
    $CheckMark = $result["CheckMark"];
    $developer = $result["developer"];
    $headcolor = $result["headcolor"];
    $background = $websiteurl . substr($result["background"], 6);
    $telegram = $result["telegram"];
    $youtube = $result["youtube"];
    $bio = $result["bio"];
    $customprofilebg = $websiteurl . substr($result["customprofilebg"], 6);

    if(password_verify($password, $result['password'])){
        $die = 0;
    } else {
        die();
    }
}

// Проверка на бан
$ban_query = "SELECT ban FROM users WHERE id = :id";
$ban_stmt = $pdo->prepare($ban_query);
$ban_stmt->execute(["id" => $id]);
$ban_result = $ban_stmt->fetch(PDO::FETCH_ASSOC);

if ($ban_result && $ban_result['ban'] == 1) {
    header("HTTP/1.0 404 Not Found");
    die();
}

echo $username . ',' . $icon . ',' . $CheckMark . ',' . $developer . ',' . $headcolor . ',' . $background . ',' . $bio . ',' . $customprofilebg;

$stmt = $pdo->prepare("SELECT * FROM songs WHERE author = ? ORDER BY id DESC LIMIT 1");
$stmt->execute([$username]);
$row = $stmt->fetch();

if ($row) {
    $newmusic_id = $row['id'];
    $newmusic_name = $row['name'];
    $newmusic_icon = '../content/' . $row['url'] . '/' . $row['name'] . '.mp3.png';
} else {
    $newmusic_id = 'notfound';
    $newmusic_name = 'Увы, не было найдено ничего';
    $newmusic_icon = '';
}

$stmt = $pdo->prepare("SELECT COUNT(*) FROM songs WHERE author = ?");
$stmt->execute([$username]);
$all_songs = $stmt->fetchColumn();

$stmt = $pdo->prepare("SELECT COUNT(*) FROM posts WHERE author = ?");
$stmt->execute([$username]);
$all_posts = $stmt->fetchColumn();

$stmt = $pdo->prepare("SELECT COUNT(*) FROM comments WHERE author = ?");
$stmt->execute([$username]);
$all_comments = $stmt->fetchColumn();

$stmtasa = $pdo->prepare("SELECT COUNT(*) FROM follows WHERE content_author_id = ?");
$stmtasa->execute([$id]);
$followers_count = $stmtasa->fetchColumn();

$stmt = $pdo->prepare("SELECT COUNT(*) FROM albums WHERE authorid = ?");
$stmt->execute([$id]);
$albums_count = $stmt->fetchColumn();

$posts_per_page = 8;
$current_page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$offset = ($current_page - 1) * $posts_per_page;

$query = $pdo->prepare("SELECT * FROM posts WHERE author = ? ORDER BY id DESC LIMIT ? OFFSET ?");
$query->bindValue(1, $username, PDO::PARAM_STR);
$query->bindValue(2, $posts_per_page, PDO::PARAM_INT);
$query->bindValue(3, $offset, PDO::PARAM_INT);
$query->execute();
$posts = $query->fetchAll(PDO::FETCH_ASSOC);

$total_posts_query = $pdo->prepare("SELECT COUNT(*) FROM posts WHERE author = ?");
$total_posts_query->execute([$username]);
$total_posts = $total_posts_query->fetchColumn();
$total_pages = ceil($total_posts / $posts_per_page);

// Check subscription status for the user with the given ID
$stmt = $pdo->prepare("SELECT * FROM subscription WHERE userid = ? AND type = 1");
$stmt->execute([$id]);
$subscription = $stmt->fetch(PDO::FETCH_ASSOC);

$hasSubscription = $subscription ? true : false;

$subscriptionIs = "";

if ($hasSubscription) {
    $subscriptionIs = "1";
} else {
    $subscriptionIs = "0";
}

?>