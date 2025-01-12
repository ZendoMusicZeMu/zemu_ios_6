<?php
function alert($name, $text, $auto, $closed) {
    echo '<a id="autoLink" href="zemu://alert?name=' . $name . '&text=' . $text . '" target="_blank">';
    if($closed==='true') {
        echo '</a>';
    }
    if($auto==='true') {
        echo "<script>
        // JavaScript код для автоматического открытия ссылки
        window.onload = function() {
            document.getElementById('autoLink').click();
        };
        </script>";
    }
}
?>