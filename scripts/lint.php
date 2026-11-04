<?php

// hh_client --lint exits zero even when it reports lint errors. Check its JSON
// result so Composer and CI fail when diagnostics are present.
$files = [];
foreach (['src', 'tests'] as $directory) {
    $iterator = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($directory, FilesystemIterator::SKIP_DOTS)
    );
    foreach ($iterator as $file) {
        if ($file->isFile() && $file->getExtension() === 'hack') {
            $files[] = $file->getPathname();
        }
    }
}
sort($files);
if (!$files) {
    fwrite(STDERR, "No Hack source files found.\n");
    exit(1);
}

exec('hh_client --lint --json '.implode(' ', array_map('escapeshellarg', $files)), $output, $status);
if ($status !== 0) {
    fwrite(STDERR, implode("\n", $output)."\n");
    exit($status);
}

try {
    $result = json_decode(implode("\n", $output), true, 512, JSON_THROW_ON_ERROR);
} catch (JsonException $exception) {
    fwrite(STDERR, 'Invalid linter output: '.$exception->getMessage()."\n");
    exit(1);
}
if (!isset($result['errors']) || !is_array($result['errors'])) {
    fwrite(STDERR, "Linter output is missing the errors array.\n");
    exit(1);
}
if ($result['errors']) {
    fwrite(STDERR, json_encode($result['errors'], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES)."\n");
    exit(1);
}
printf("No lint errors (%d files checked).\n", count($files));
