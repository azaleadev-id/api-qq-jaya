<?php

declare(strict_types=1);

$apiKey = trim((string) getenv('APP_API_KEY'));

if ($apiKey === '') {
    throw new RuntimeException('APP_API_KEY is required.');
}

return [
    'name' => 'QQ Jaya Cell API',
    'environment' => getenv('APP_ENV') ?: 'production',
    'debug' => (getenv('APP_DEBUG') ?: 'false') === 'true',
    'api_key' => $apiKey,
];
