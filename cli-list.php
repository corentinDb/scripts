<?php
/**
 * CLI directory listing - recursive plain text output
 * Returns recursive list of files and directories for curl, wget, and other tools
 */

header('Content-Type: text/plain; charset=utf-8');

// Get the requested path
$basePath = __DIR__;
$requestPath = $_GET['path'] ?? '';

// Clean the path - remove trailing slashes and normalize
$requestPath = trim($requestPath, '/');

// Construct the full path
$fullPath = $basePath;
if ($requestPath) {
    $fullPath = $basePath . '/' . $requestPath;
}

// Security: prevent directory traversal
$realPath = realpath($fullPath);
if ($realPath === false || strpos($realPath, $basePath) !== 0) {
    http_response_code(404);
    echo "Not found\n";
    exit;
}

// Check if path is a directory
if (!is_dir($realPath)) {
    http_response_code(404);
    echo "Not found\n";
    exit;
}

// Change to the requested directory for relative path listing
chdir($realPath);

// Recursive iterator to get all files and directories
try {
    $iterator = new RecursiveDirectoryIterator(
        '.',
        RecursiveDirectoryIterator::SKIP_DOTS
    );
    $iteratorIterator = new RecursiveIteratorIterator($iterator);

    $items = [];
    foreach ($iteratorIterator as $fileinfo) {
        $path = $fileinfo->getPathname();

        // Skip hidden files/dirs (starting with .)
        if (preg_match('/\/\./', $path) || strpos(basename($path), '.') === 0) {
            continue;
        }

        // Skip cli-list.php
        if (basename($path) === 'cli-list.php') {
            continue;
        }

        // Store items with directory suffix
        if ($fileinfo->isDir()) {
            $items[] = $path . '/';
        } else {
            $items[] = $path;
        }
    }

    // Sort items
    sort($items);

    // Output
    foreach ($items as $item) {
        echo $item . "\n";
    }

} catch (Exception $e) {
    http_response_code(500);
    echo "Error reading directory\n";
    exit;
}
