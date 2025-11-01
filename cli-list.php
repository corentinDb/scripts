<?php
/**
 * CLI directory listing - plain text output
 * Returns list of files and directories for curl, wget, and other tools
 */

header('Content-Type: text/plain; charset=utf-8');

// Get directory listing
$files = @scandir('.');
if ($files === false) {
    http_response_code(403);
    echo "Permission denied\n";
    exit;
}

// Filter: exclude . .. and hidden files (starting with .)
$files = array_filter($files, function($item) {
    return !in_array($item, ['.', '..']) && strpos($item, '.') !== 0;
});

// Sort alphabetically
sort($files);

// Output
foreach ($files as $file) {
    if (is_dir($file)) {
        echo $file . "/\n";
    } else {
        echo $file . "\n";
    }
}
