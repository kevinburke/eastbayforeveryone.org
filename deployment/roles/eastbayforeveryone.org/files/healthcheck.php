<?php
// Health check endpoint for post-deploy verification.
// Tests MySQL connectivity by writing and reading a WordPress transient.

require_once dirname(__FILE__) . '/wp-load.php';

header('Content-Type: application/json');

$key = '_deploy_healthcheck';
$value = 'ok_' . wp_generate_password(12, false);

// Test write
$written = set_transient($key, $value, 60);
if (!$written) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'failed to write transient']);
    exit;
}

// Test read
$read = get_transient($key);
if ($read !== $value) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'read value does not match written value']);
    exit;
}

// Cleanup
delete_transient($key);

echo json_encode(['status' => 'ok']);
