<?php
require_once '../../config/db.php';

// Запрос для поиска аккаунта по имени
$query = "SELECT  *  FROM users WHERE username LIKE ?";

// Подготовка запроса
$stmt = $pdo->prepare($query);

// Установка параметров для оператора LIKE
$likeParameter = "%{$_GET['search']}%"; // Получаем значение для поиска из GET-параметра

// Выполнение запроса
$stmt->execute([$likeParameter]);

// Получение результатов
$results = $stmt->fetchAll(PDO::FETCH_ASSOC);

// Вывод результатов
foreach ($results as $result) {
	$username = $result['username'];
	$icon = $result['icon'];
	$CheckMark = $result['CheckMark'];
	$developer = $result['developer'];
	$headcolor = $result['headcolor'];
	$headbackground = $result['headbackground'];
	$background = $result['background'];
	$telegram = $result['telegram'];
}

?>

<html lang="en">

<style>
.bp{
	background: <?php echo $background; ?>;
}

label{
	color: white;
	font-family: 'Arial', 'Verdana', sans-serif;
	text-shadow:
      2px 0 black,
      0 -2px black,
      -2px 0 black,
      0 2px black;
}

.head-div{
	position: relative;
	width: 100%;
	background: rgba(39, 41, 47, 0.3) !important;
	background-image: url('<?php echo $headbackground; ?>');
    background-size: cover;
	border-radius: 10px;
	border: 3px solid <?php echo $headcolor; ?>;
}

.icon-profile{
	border-radius: 50%;
	width: 175px;
	height: 175px
}

.name{
	height: 75px;
 	line-height: 50px;
 	text-align: center;
}

.menu{
	position: fixed;
	top: 25%;
}

.menu-right{
	position: fixed;
	right: 1%;
	top: 40%;
}

.menu-icons{
	max-width: 50px;
}

.mark{
	color: green;
	height: 100px;
 	line-height: 100px;
 	text-align: center;
}

.post{
	background: rgba(39, 41, 47, 0.3) !important;
	border-radius: 10px;
	border: 3px solid <?php echo $headcolor; ?>;
	width: 95%;
}

.text-post{
	color: white;
}

.marks-icons{
	position: absolute;
	max-width: 50px;
	right: 1%;
}

.marks-icons-developer{
	position: absolute;
	max-width: 50px;
	right: 5%;
}

.post img {
    max-width: 500px;
}

.previous {
  color: white;
  position: fixed;
  z-index: 100;
  font-family: 'Arial', 'Verdana', sans-serif;
  font-size: 50;
}

a {
  text-decoration: none;
  display: inline-block;
  padding: 8px 16px;
}
</style>

<head>
<a href="javascript:history.back()" class="previous"><</a>
    <meta charset="UTF-8">
    <title>ZeMu</title>
	<link href="../csstest2/style.css" rel="stylesheet">
</head>
<body class="bp">
    <div class="head-div"><br><center><img src="<?php echo $icon; ?>" class="icon-profile"></center><h1 class="name"><?php echo $username; ?></h1></div><br>
</body>
</html>

<?php

// Запрос к базе данных
$query = $pdo->prepare("SELECT  *  FROM posts WHERE author = ? ORDER BY id DESC");
$query->execute([$username]);
echo '<center>';
// Получаем результаты и выводим их
while ($row = $query->fetch(PDO::FETCH_ASSOC)) {
    echo '<div class="post"><h1>' . $row['date'] . '</h1><h2 class="text-post">' . $row['text'] . '</h2><img src="' . $row['image'] . '"></div><br>'; // Выводим имя записи
}
echo '</center>';
?>