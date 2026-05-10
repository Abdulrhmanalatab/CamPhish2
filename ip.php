<?php
// ip.php - capture visitor IP and user agent
function getClientIP() {
    $headers = [
        'HTTP_CLIENT_IP',
        'HTTP_X_FORWARDED_FOR',
        'HTTP_X_FORWARDED',
        'HTTP_FORWARDED_FOR',
        'HTTP_FORWARDED',
        'REMOTE_ADDR'
    ];
    foreach ($headers as $key) {
        if (!empty($_SERVER[$key])) {
            $ips = explode(',', $_SERVER[$key]);
            return trim($ips[0]);
        }
    }
    return 'UNKNOWN';
}

$ip = getClientIP();
$useragent = $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown UA';
$date = date('Y-m-d H:i:s');

$log = "[$date] IP: $ip | User-Agent: $useragent\n";
file_put_contents('ip.txt', $log, FILE_APPEND);
?>
