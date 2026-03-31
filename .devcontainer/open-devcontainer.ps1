# open-devcontainer.ps1
#
# Usage: run from inside any project directory in Windows PowerShell.
#
#   cd C:\Users\<you>\projects\hello-world
#   open-devcontainer.ps1
#
# What it does:
#   1. Resolves dev-sandbox as the parent of .devcontainer\ (the directory
#      containing this script).
#   2. Derives PROJECT_NAME from the current directory name and PROJECT_PATH
#      from the current directory's absolute path.
#   3. Writes .devcontainer\workspace.code-workspace with exactly two folders:
#      /workspace (dev-sandbox root) and /workspace/<PROJECT_NAME> (project).
#      This prevents VS Code from accumulating ghost folders across sessions.
#   4. Checks if a container named dev-sandbox-<PROJECT_NAME> already exists.
#      - If yes: reuses it (VS Code will restart it if stopped).
#      - If no: removes any other dev-sandbox-* containers, then opens VS Code
#        to trigger a fresh build.
#   5. Sets PROJECT_NAME and PROJECT_PATH as process-scoped environment
#      variables so devcontainer.json can read them via ${localEnv:...}.
#   6. Opens VS Code using the generated workspace file, which pins the
#      Explorer to exactly the two folders for this session.
#
# Requirements:
#   - 'code' must be on PATH (VS Code "Install code command" in PATH)
#   - Docker Desktop must be running
#   - This script must live inside dev-sandbox\.devcontainer\

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -- Resolve dev-sandbox -------------------------------------------------------

# $PSScriptRoot is the directory containing this script, i.e. .devcontainer\.
# dev-sandbox is one level up.
$devSandboxPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

if (-not (Test-Path $devSandboxPath)) {
    Write-Error "dev-sandbox not found at: $devSandboxPath"
    exit 1
}

# -- Resolve project -----------------------------------------------------------

$projectPath = $PWD.Path
$projectName = Split-Path $projectPath -Leaf

# Guard against accidentally opening devcontainer internals.
$reserved = @(".devcontainer", ".claude", ".uv-data")
if ($reserved -contains $projectName) {
    Write-Error "'$projectName' is a reserved directory name and cannot be used as a project."
    exit 1
}

if (-not (Test-Path $projectPath)) {
    Write-Error "Current directory does not exist: $projectPath"
    exit 1
}

# -- Write workspace file ------------------------------------------------------

# Written to dev-sandbox root (mounted at /workspace inside the container).
# postAttachCommand in devcontainer.json opens it after VS Code connects,
# switching the Explorer to exactly the two folders for this session.
# The file is gitignored; only this script (which generates it) is versioned.
$workspaceFile = Join-Path $devSandboxPath "workspace.code-workspace"
$workspaceContent = @"
{
  "folders": [
    { "path": "." },
    { "path": ".claude" },
    { "path": "../$projectName" }
  ]
}
"@
Set-Content -Path $workspaceFile -Encoding UTF8 -Value $workspaceContent
Write-Host "Wrote workspace file: $workspaceFile"


# -- Manage containers ---------------------------------------------------------

$targetContainerName = "dev-sandbox-$projectName"

# Check if the target container already exists (running or stopped).
$existing = docker ps -aq --filter "name=^${targetContainerName}$" 2>$null

if ($existing) {
    Write-Host "Reusing existing container: $targetContainerName"
} else {
    # Remove any other dev-sandbox-* containers before building a new one.
    $others = docker ps -aq --filter "name=^dev-sandbox-" 2>$null
    if ($others) {
        foreach ($id in $others) {
            $name = docker inspect --format "{{.Name}}" $id 2>$null
            # Strip the leading slash Docker adds to container names.
            $name = $name.TrimStart("/")
            Write-Host "Removing old container: $name"
            docker rm -f $id | Out-Null
        }
    }
    Write-Host "No existing container found. VS Code will build a new one."
}

# -- Export variables for VS Code ----------------------------------------------

# Process-scoped only: inherited by VS Code child process but not written
# permanently to the user or system environment.
$env:PROJECT_PATH = $projectPath
$env:PROJECT_NAME = $projectName

Write-Host "Opening dev-sandbox with project: $projectName"
Write-Host "  PROJECT_PATH = $projectPath"
Write-Host "  PROJECT_NAME = $projectName"
Write-Host "  dev-sandbox  = $devSandboxPath"

# -- Launch VS Code ------------------------------------------------------------

# Open dev-sandbox as a folder so Dev Containers finds .devcontainer/ and
# connects. postAttachCommand will then open workspace.code-workspace from
# inside the container, switching to the multi-root workspace view.
$uri = [uri]::new($devSandboxPath).AbsoluteUri
code --folder-uri $uri