<?php

// Name of file
$file = "example.json";

// Save new styles to the JSON file
function saveStyle($file, $selector, $value) {
	$string = file_get_contents($file);
	$json = json_decode($string, true);
	$json[$selector] = $value;
	file_put_contents($file, json_encode($json));
}

// Get the CSS for the browser from the JSON file
function json2Css($file) {
	$string = file_get_contents($file);
	$css = "";
	$json = json_decode($string, true);
	$jsonIterator = new RecursiveIteratorIterator(
						new RecursiveArrayIterator($json),
						RecursiveIteratorIterator::SELF_FIRST);

	foreach ($jsonIterator as $key => $val) {
	    if(is_array($val)) {
	        $css .= "}\n$key {\n";
	    } else {
	        $css .= "\t$key: $val;\n";
	    }
	}

	return substr($css, 2) . "}";
}

// Saving the new styles
if(isset($_POST["selector"])) {
	saveStyle($file, $_POST["selector"], $_POST["value"]);

// Requesting CSS
} elseif(isset($_GET["css"])) {
	header("Content-type: text/css");
	header("Expires: Mon, 26 Jul 1990 05:00:00 GMT");
	header("Last-Modified: " . gmdate("D, d M Y H:i:s") . " GMT");
	header("Cache-Control: no-store, no-cache, must-revalidate");
	header("Cache-Control: post-check=0, pre-check=0", false);
	header("Pragma: no-cache");

	echo json2Css($file);

// Requesting JSON
} elseif(isset($_GET["json"])) {
	header('Content-type: application/json');
	$string = file_get_contents($file);

	echo $string;
}