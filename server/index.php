<?php

$account_name = 'ACCOUNT_NAME';
$api_key = 'API_KEY';
$application_id = 'APPLICATION_ID';

header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");

$query = http_build_query([
    'account_name' => $account_name,
    'api_key' => $api_key,
    'application_id' => $application_id
]);

readfile('https://api.voximplant.com/platform_api/GetUsers?' . $query);