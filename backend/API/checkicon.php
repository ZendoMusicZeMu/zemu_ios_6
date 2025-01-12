<?php
function checkicon($iconurl, $backurl)
{


    $result = substr(str_replace('%20', ' ', $iconurl), 20);
    $checkicon = $backurl . $result;
    if (!file_exists($checkicon)) {
        $icon = $backurl . 'content/img/none-music.png'; // Возвращаем иконку по умолчанию, если файл не существует
    }
    else {
        $icon = substr(str_replace(' ', '%20', $iconurl), 20);; // Возвращаем оригинальный URL, если все в порядке
    }
    return $icon;
}
?>