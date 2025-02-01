<?php
require_once '../libs/alert.php';
require_once '../config/config.php';
$version = isset($_GET['version']) ? $_GET['version'] : '';
require_once '../libs/checkversion.php';

$banner1url = '../img/banners/cut_the_rope_banner.jpg';
$banner2url = '../img/banners/minecraft_banner.jpg';

// URL, по которому доступен JSON-developers
$url = $apiurl . 'developers.php?pass=' . $password; // Замените на ваш URL

// Получаем JSON-ответ по ссылке
$jsonResponse = file_get_contents($url);

// Проверяем, удалось ли получить данные
if ($jsonResponse === FALSE) {
    die("Ошибка: Не удалось получить данные по указанной ссылке.");
}

// Декодируем JSON-ответ в массив
$data = json_decode($jsonResponse, true);

// Проверяем, удалось ли декодировать JSON
if (json_last_error() !== JSON_ERROR_NONE) {
    // Выводим ошибку и необработанный ответ
    die("Ошибка: Неверный формат JSON. Ответ сервера: " . htmlspecialchars($jsonResponse));
}

// Извлекаем username из каждой строки
$usernames = array_column($data, 'username');

// Объединяем username через запятую
$usernamesString = implode(', ', $usernames);
?>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">

<style>

.input-search{
  position: relative;
  display: block;
  /*border-radius: 8px;*/
  background: linear-gradient(to bottom, #404040, #242424);
  box-shadow: 0px -1px 0px rgba(255, 255, 255, .25), 0px 1px 0px rgba(0, 0, 0, .5), inset 0px 2px 3px rgba(0, 0, 0, .25);
  border: 1px solid #3c3c3c;
  font-size: 15px;
  color: #000000;
  padding: 7px 16px;
  margin: 0 8px 0 0;
  flex: 1 1 90%;
  width: unset;
  opacity: 1;
    width: 87.5%;
    height: 26px;
}


.banner{
	display: inline-block;
	margin: 10px;
	width: 40%;
	border-radius: 10px;
	box-shadow: 0px 1px 1px 1px #000;
}
</style>

<head>
    <meta content="yes" name="apple-mobile-web-app-capable" />
    <meta content="index,follow" name="robots" />
    <meta content="text/html; charset=utf-8" http-equiv="Content-Type" />
    <link href="pics/homescreen.gif" rel="apple-touch-icon" />
    <meta content="minimum-scale=1.0, width=device-width, maximum-scale=0.6667, user-scalable=no" name="viewport" />
    <link href="../css/style.css" rel="stylesheet" media="screen" type="text/css" />
    <title>Музыка</title>
</head>

<center>
	<!--<form action="search/index.php" method="post" enctype="multipart/form-data"><input class="input-search" type="text" name="search" id="search" placeholder="search"></form>-->
        <form action="search/index.php" method="post" enctype="multipart/form-data"><input class="input-search" type="text" name="search" id="search" placeholder="Поиск"></form>
		
		<!--<a href='zemu://music?id=3'><img src="<?php echo $banner1url; ?>" class='banner'></a>
		<a href='zemu://music?id=12'><img src="<?php echo $banner2url; ?>" class='banner'></a>-->
	</center>


<body class="applist">
    <div id="content">

    <?php
    require_once '../config/config.php';

    // Предположим, что у вас есть ссылка на JSON файл
    $jsonUrl = $apiurl . 'categories.php?pass=' . $password . '&originalicon=true';

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

    // Выводим данные
    foreach ($data as $item) {
        echo '<li>
        <a class="noeffect" href="section?data=' . $item['name'] . '&sec=' . $item['runame'] . '">
        <span class="image" style="background-image: url(' . $item['icon'] . ')"></span>
        <span class="name">' . $item['runame'] . '</span>
        <span class="stars4"></span>
        <span class="arrow"></span>
        <span class="price"></span></a>
        </li>';
    }

    ?>
    </div>
</body>

<center><?php alert('Разработчики', $usernamesString, false, false) ?><button>Разработчики</button></a></center>

</html>