<?php
require_once '../../config/db.php';

// Проверка соединения
if ($pdo === null) {
    die("Connection failed: " . $e->getMessage());
}

try {
    // Подготовка и выполнение запроса к базе данных
    $sql = "SELECT username FROM users WHERE developer = 1";
    $stmt = $pdo->prepare($sql);
    $stmt->execute();

    // Получаем данные из результата запроса
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if (count($users) > 0) {
        // Проходим по всем строкам результатов
        foreach ($users as $row) {
            echo $row["username"] . ", ";
        }
    } else {
        echo "Нет записей соответствуют условию.";
    }
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage();
}

?>