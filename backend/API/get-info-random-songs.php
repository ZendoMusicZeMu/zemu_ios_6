<?php
require_once '../config/config.php';
error_reporting(E_ALL);
ini_set('display_errors', '1');


// Предположим, что у вас есть ссылка на JSON файл
$jsonUrl = $apiurl . 'random-song.php?pass=' . $password . '&originalurl=true&originalicon=true';

// Initialize cURL session
$ch = curl_init();

// Set cURL options
curl_setopt($ch, CURLOPT_URL, $jsonUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

// Disable SSL verification (Not recommended for production)
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);

// Execute cURL session and fetch data
$jsonData = curl_exec($ch);

// Check for cURL errors
if ($jsonData === false) {
    $error = curl_error($ch);
    echo "Failed to retrieve data from the server. Error: " . $error;
    curl_close($ch);
    exit;
}

// Close cURL session
curl_close($ch);

// Декодируем JSON в массив
$data = json_decode($jsonData, true);

if ($data === null) {
    // Check if there was an error during JSON decoding
    $error = json_last_error();
    if ($error !== JSON_ERROR_NONE) {
        echo "Failed to decode JSON data. Error: " . json_last_error_msg();
        echo $jsonUrl;
        exit;
    }
}

// Выводим данные
foreach ($data as $item) {

    $icon = $item['icon'];
    // Заменяем https на http в ссылке на иконку
    $icon = str_replace('https://', 'http://', $icon);
    
    $url = $item['url'];
    // Заменяем https на http в основном URL
    $url = str_replace('https://', 'http://', $url);

    if ($item['category'] === 'games') {
        $category = 'Игры';
    } elseif ($item['category'] === 'films') {
        $category = 'Фильмы';
    } elseif ($item['category'] === 'relax') {
        $category = 'Расслабляющая';
    } elseif ($item['category'] === 'rock') {
        $category = 'Рок';
    } elseif ($item['category'] === 'rap') {
        $category = 'Рэп';
    } elseif ($item['category'] === 'pop') {
        $category = 'Поп';
    } elseif ($item['category'] === 'phonk') {
        $category = 'Фонк';
    } elseif ($item['category'] === 'electro') {
        $category = 'Электро';
    } else {
        $category = 'Неизвестно';
    }
    
    if ($item['verified'] === 1) {
        $verified = 'Песня проверена';
    } else {
        $verified = 'Песня не была проверена';
    }
    
    $external_url = $url;

    echo $url . ',' . $icon . ',' . $item['songname'] . ',' . $item['author'] . ',ID: ' . $item['id'];
}
?>