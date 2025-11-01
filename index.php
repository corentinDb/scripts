<?php
/**
 * Directory listing with intelligent format selection
 * CLI tools (curl, wget, etc.) get plain text listing
 * Browsers get HTML directory listing
 */

// Get the User-Agent header
$userAgent = $_SERVER['HTTP_USER_AGENT'] ?? '';

// List of CLI tool patterns to detect
$cliPatterns = [
    'curl',           // curl/7.64.1
    'Wget',           // Wget/1.20.3
    'wget',           // alternate case
    'HTTPie',         // HTTPie/3.0.0
    'aria2c?',        // aria2/1.36.0 or aria2c
    'lynx',           // lynx browser
    'links',          // links browser
    'w3m',            // w3m browser
    'python-requests',// requests library
    'node-fetch',     // node.js fetch
    'urllib',         // Python urllib
    'perl',           // perl LWP
    'java',           // java HttpClient
    'powershell',     // PowerShell
    'pwsh',           // PowerShell Core
    'fetch',          // fetch utility
    'axel',           // axel download
    'lftp',           // lftp client
];

// Check if this is a CLI tool
$isCliTool = preg_match('/' . implode('|', $cliPatterns) . '/i', $userAgent);

// Get the current directory
$dir = getcwd();

// Get directory listing
try {
    $files = @scandir($dir);
    if ($files === false) {
        http_response_code(403);
        if ($isCliTool) {
            header('Content-Type: text/plain; charset=utf-8');
            echo "Permission denied\n";
        } else {
            header('Content-Type: text/html; charset=utf-8');
            echo "<!DOCTYPE html><html><body><h1>403 - Permission Denied</h1></body></html>";
        }
        exit;
    }

    // Filter out current directory entry, sort alphabetically
    $files = array_filter($files, function($item) {
        return $item !== '.';
    });
    sort($files);
} catch (Exception $e) {
    http_response_code(500);
    if ($isCliTool) {
        header('Content-Type: text/plain; charset=utf-8');
        echo "Error reading directory\n";
    } else {
        header('Content-Type: text/html; charset=utf-8');
        echo "<!DOCTYPE html><html><body><h1>500 - Server Error</h1></body></html>";
    }
    exit;
}

// Output based on client type
if ($isCliTool) {
    // Plain text output for CLI tools
    header('Content-Type: text/plain; charset=utf-8');
    foreach ($files as $file) {
        if (is_dir($file)) {
            echo $file . "/\n";
        } else {
            echo $file . "\n";
        }
    }
} else {
    // HTML output for browsers
    header('Content-Type: text/html; charset=utf-8');
    $indexPath = dirname($_SERVER['REQUEST_URI'] ?: '/');
    if ($indexPath !== '/') {
        $indexPath = rtrim($indexPath, '/');
    }
    ?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Index of <?php echo htmlspecialchars($indexPath); ?></title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            max-width: 900px;
            margin: 0 auto;
            padding: 20px;
            background: #f8f9fa;
            color: #333;
        }
        h1 {
            color: #333;
            border-bottom: 2px solid #ddd;
            padding-bottom: 10px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            background: white;
            margin: 20px 0;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        th {
            background: #f5f5f5;
            padding: 10px;
            text-align: left;
            font-weight: 600;
            border-bottom: 1px solid #ddd;
        }
        td {
            padding: 8px 10px;
            border-bottom: 1px solid #eee;
        }
        tr:hover {
            background: #f9f9f9;
        }
        a {
            color: #0066cc;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
        .dir {
            font-weight: 600;
        }
    </style>
</head>
<body>
    <h1>Index of <?php echo htmlspecialchars($indexPath); ?></h1>
    <table>
        <tr>
            <th>Name</th>
            <th style="width: 100px;">Type</th>
        </tr>
        <?php
        // Add parent directory link if not at root
        if ($indexPath !== '/') {
            ?>
        <tr>
            <td><a href="../">../</a></td>
            <td>Dir</td>
        </tr>
            <?php
        }

        // List all files and directories
        foreach ($files as $file):
            $isDir = is_dir($file);
            $displayFile = htmlspecialchars($file);
            $href = htmlspecialchars($file . ($isDir ? '/' : ''));
            $type = $isDir ? 'Dir' : 'File';
            $class = $isDir ? ' class="dir"' : '';
        ?>
        <tr>
            <td><a href="<?php echo $href; ?>"<?php echo $class; ?>><?php echo $displayFile; if ($isDir) echo '/'; ?></a></td>
            <td><?php echo $type; ?></td>
        </tr>
        <?php endforeach; ?>
    </table>
</body>
</html>
    <?php
}
