<?php
// post.php - receives base64 image from cam and saves it as PNG
$imageData = $_POST['cat'] ?? '';

if (empty($imageData)) {
    exit;
}

// Remove metadata prefix (e.g., "data:image/png;base64,")
$filteredData = substr($imageData, strpos($imageData, ",") + 1);
$decodedData = base64_decode($filteredData);

if ($decodedData === false) {
    exit;
}

// Generate unique filename with microtime to avoid overwriting
$timestamp = date('Ymd_His') . '_' . microtime(true);
$filename = "cam_{$timestamp}.png";
file_put_contents($filename, $decodedData);

// Log the event (optional, for monitoring)
$logEntry = date('Y-m-d H:i:s') . " - Image saved: $filename\n";
file_put_contents('Log.log', $logEntry, FILE_APPEND);

exit;
?>
