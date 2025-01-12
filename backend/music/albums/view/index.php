<?php
$idalbum = isset($_GET['id']) ? $_GET['id'] : '';
$namealbum = isset($_GET['name']) ? $_GET['name'] : '';

$page = isset($_GET['page']) ? max(1, intval($_GET['page'])) : 1; // Текущая страница
$perPage = 6; // Количество карточек на странице
?>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">

<head>
    <meta content="yes" name="apple-mobile-web-app-capable" />
    <meta content="index,follow" name="robots" />
    <meta content="text/html; charset=utf-8" http-equiv="Content-Type" />
    <link href="pics/homescreen.gif" rel="apple-touch-icon" />
    <meta content="minimum-scale=1.0, width=device-width, maximum-scale=0.6667, user-scalable=no" name="viewport" />
    <link href="../../../css/style.css" rel="stylesheet" media="screen" type="text/css" />
    <title><?php echo $namealbum; ?></title>
</head>

<body class="applist">
<div id="content">

    <?php
    require_once '../../../config/config.php';
    require_once '../../../API/checkicon.php';

    // Предположим, что у вас есть ссылка на JSON файл
    $jsonUrl = $apiurl . 'songs-from-album.php?idalbum=' . $idalbum . '&pass=' . $password;

    // Отключаем проверку SSL-сертификата
    $context = stream_context_create([
        "ssl" => [
            "verify_peer" => false,
            "verify_peer_name" => false,
        ],
    ]);

    // Читаем содержимое JSON файла
    $jsonData = file_get_contents($jsonUrl, false, $context);

    if ($jsonData === false) {
        die("Не удалось получить данные с сервера.");
    }

    // Декодируем JSON в массив
    $data = json_decode($jsonData, true);

    if ($data === null) {
        die("Не удалось декодировать JSON.");
    }

    // Общее количество элементов
    $total = count($data);

    // Вычисляем общее количество страниц
    $totalPages = ceil($total / $perPage);

    // Вычисляем начальный и конечный индексы для текущей страницы
    $start = ($page - 1) * $perPage;
    $end = min($start + $perPage, $total);

    // Выводим данные для текущей страницы
    for ($i = $start; $i < $end; $i++) {
        if (!isset($data[$i])) {
            continue; // Пропускаем несуществующие элементы
        }

        $row = $data[$i];

        // Проверяем иконку
        $icon = checkicon($row['icon'], '../../../../');

        echo '<li><a class="noeffect" href="zemu://music?id=' . $row['id'] . '"><span class="image" style="background-image: url(' . $icon . ')"></span><span class="comment">' . $row['author'] . '</span><span class="name">' . $row['songname'] . '</span><span class="stars4"></span><span class="arrow"></span><span class="price"></span></a></li>';
    }

    echo '</div>';

    // Пагинация
    echo '<center><div class="pagination">';
    if ($page > 1) {
        echo '<a href="?id=' . $idalbum . '&name=' . $namealbum . '&page=' . ($page - 1) . '"><button><</button></a>';
    } else {
        echo '<a class="disabled"><button><</button></a>';
    }
    echo '<a href="?id=' . $idalbum . '&name=' . $namealbum . '&page=' . $page . '" class="active"><button>' . $page . '</button></a>';
    if ($page < $totalPages) {
        echo '<a href="?id=' . $idalbum . '&name=' . $namealbum . '&page=' . ($page + 1) . '"><button>></button></a>';
    } else {
        echo '<a class="disabled"><button>></button></a>';
    }
    echo '</div></center>';
    ?>

</body>
</html>