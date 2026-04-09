param(
    [string]$SourceRoot = "src",
    [string]$OutputPath = "docs/functions.html"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-FirstHelpLine {
    param(
        [string]$FunctionText,
        [string]$Section
    )

    $pattern = "(?is)\.$Section\s*(?<content>.*?)(\r?\n\s*\.[A-Z]+|\r?\n\s*#>|$)"
    $match = [regex]::Match($FunctionText, $pattern)
    if (-not $match.Success) {
        return $null
    }

    $content = $match.Groups["content"].Value -split "`r?`n"
    foreach ($line in $content) {
        $clean = $line.Trim()
        $clean = $clean.TrimStart("#")
        $clean = $clean.Trim()
        if ([string]::IsNullOrWhiteSpace($clean)) {
            continue
        }

        return $clean
    }

    return $null
}

function Get-FallbackDescription {
    param(
        [string]$FunctionName,
        [string]$RelativeFile
    )

    if ($FunctionName -match "^(?<verb>[A-Za-z]+)-(?<noun>.+)$") {
        $verb = $matches["verb"]
        $noun = ($matches["noun"] -replace "-", " ")
        return "$verb action for $noun."
    }

    return "Utility function from $RelativeFile."
}

function Get-FallbackExample {
    param(
        [System.Management.Automation.Language.FunctionDefinitionAst]$FunctionAst
    )

    $name = $FunctionAst.Name
    $params = @()

    if ($FunctionAst.Body -and $FunctionAst.Body.ParamBlock -and $FunctionAst.Body.ParamBlock.Parameters) {
        foreach ($p in $FunctionAst.Body.ParamBlock.Parameters) {
            $params += $p.Name.VariablePath.UserPath
        }
    }

    if ($params.Count -gt 0) {
        $firstParam = $params[0]
        return "$name -$firstParam <value>"
    }

    return $name
}

function ConvertTo-HtmlEncoded {
    param([string]$Value)
    if ($null -eq $Value) {
        return ""
    }
    return [System.Net.WebUtility]::HtmlEncode($Value)
}

function Get-AstElementText {
  param([System.Management.Automation.Language.Ast]$AstElement)

  if ($null -eq $AstElement) {
    return $null
  }

  $text = $AstElement.Extent.Text.Trim()
  if (($text.StartsWith("'") -and $text.EndsWith("'")) -or ($text.StartsWith('"') -and $text.EndsWith('"'))) {
    if ($text.Length -ge 2) {
      $text = $text.Substring(1, $text.Length - 2)
    }
  }

  return $text
}

function Get-AliasMapFromAst {
  param([System.Management.Automation.Language.Ast]$Ast)

  $map = @{}
  $commands = $Ast.FindAll({
      param($node)
      $node -is [System.Management.Automation.Language.CommandAst]
    }, $true)

  foreach ($command in $commands) {
    $commandName = $command.GetCommandName()
    if ([string]::IsNullOrWhiteSpace($commandName) -or $commandName.ToLowerInvariant() -ne "set-alias") {
      continue
    }

    $aliasName = $null
    $aliasTarget = $null
    $elements = $command.CommandElements

    for ($i = 1; $i -lt $elements.Count; $i++) {
      $element = $elements[$i]

      if ($element -is [System.Management.Automation.Language.CommandParameterAst]) {
        $parameterName = $element.ParameterName.ToLowerInvariant()
        $next = if ($i + 1 -lt $elements.Count) { $elements[$i + 1] } else { $null }

        if ($next -and -not ($next -is [System.Management.Automation.Language.CommandParameterAst])) {
          if ($parameterName -eq "name") {
            $aliasName = Get-AstElementText -AstElement $next
            $i++
            continue
          }

          if ($parameterName -eq "value" -or $parameterName -eq "definition") {
            $aliasTarget = Get-AstElementText -AstElement $next
            $i++
            continue
          }
        }

        continue
      }

      $tokenText = Get-AstElementText -AstElement $element
      if ([string]::IsNullOrWhiteSpace($tokenText)) {
        continue
      }

      if ([string]::IsNullOrWhiteSpace($aliasName)) {
        $aliasName = $tokenText
        continue
      }

      if ([string]::IsNullOrWhiteSpace($aliasTarget)) {
        $aliasTarget = $tokenText
        continue
      }
    }

    if ([string]::IsNullOrWhiteSpace($aliasName) -or [string]::IsNullOrWhiteSpace($aliasTarget)) {
      continue
    }

    if (-not $map.ContainsKey($aliasTarget)) {
      $map[$aliasTarget] = New-Object System.Collections.Generic.List[string]
    }

    if (-not ($map[$aliasTarget] -contains $aliasName)) {
      [void]$map[$aliasTarget].Add($aliasName)
    }
  }

  return $map
}

if (-not (Test-Path -Path $SourceRoot -PathType Container)) {
    throw "Source root '$SourceRoot' was not found."
}

$files = Get-ChildItem -Path $SourceRoot -Recurse -Filter *.ps1 | Sort-Object FullName
$items = New-Object System.Collections.Generic.List[object]

foreach ($file in $files) {
    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors)

    if ($parseErrors -and $parseErrors.Count -gt 0) {
        Write-Warning "Skipping parse errors in $($file.FullName)."
    }

    $aliasMap = Get-AliasMapFromAst -Ast $ast

    $lines = [System.IO.File]::ReadAllLines($file.FullName)
    $functions = $ast.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)

    foreach ($func in $functions) {
        $start = [Math]::Max(1, $func.Extent.StartLineNumber)
        $end = [Math]::Min($lines.Length, $func.Extent.EndLineNumber)
        $slice = $lines[($start - 1)..($end - 1)]
        $functionText = $slice -join "`n"

        $synopsis = Get-FirstHelpLine -FunctionText $functionText -Section "SYNOPSIS"
        $example = Get-FirstHelpLine -FunctionText $functionText -Section "EXAMPLE"

        $relativeFile = [System.IO.Path]::GetRelativePath((Get-Location).Path, $file.FullName).Replace('\', '/')

        if ([string]::IsNullOrWhiteSpace($synopsis)) {
            $synopsis = Get-FallbackDescription -FunctionName $func.Name -RelativeFile $relativeFile
        }

        if ([string]::IsNullOrWhiteSpace($example)) {
            $example = Get-FallbackExample -FunctionAst $func
        }

        $aliases = @()
        if ($aliasMap.ContainsKey($func.Name)) {
          $aliases = @($aliasMap[$func.Name] | Sort-Object)
        }

        $folder = if ($relativeFile.StartsWith("src/andrei/")) { "andrei" } else { "pws" }

        $items.Add([PSCustomObject]@{
                Name = $func.Name
                Description = $synopsis
                Example = $example
                File = $relativeFile
                Folder = $folder
            Aliases = $aliases
            })
    }
}

$sorted = $items | Sort-Object Name
$generatedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$count = $sorted.Count

$cards = foreach ($item in $sorted) {
    $name = ConvertTo-HtmlEncoded $item.Name
    $description = ConvertTo-HtmlEncoded $item.Description
    $example = ConvertTo-HtmlEncoded $item.Example
    $filePath = ConvertTo-HtmlEncoded $item.File
    $folder = ConvertTo-HtmlEncoded $item.Folder
    $aliasesMarkup = ""

    if ($item.Aliases -and $item.Aliases.Count -gt 0) {
      $chips = foreach ($alias in $item.Aliases) {
        $aliasEncoded = ConvertTo-HtmlEncoded $alias
        "<span class=""alias-chip"">$aliasEncoded</span>"
      }
      $aliasesMarkup = "<div class=""aliases""><span class=""aliases-label"">Aliases:</span> $($chips -join ' ')</div>"
    }

    @"
<article class="card" data-name="$name">
  <div class="card-head">
    <h2>$name</h2>
    <span class="pill">$folder</span>
  </div>
  <p class="desc">$description</p>
  <div class="meta">Defined in <span>$filePath</span></div>
  $aliasesMarkup
  <pre><code>$example</code></pre>
</article>
"@
}

$html = @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>PowerShell Function Catalog</title>
  <style>
    :root {
      --bg1: #f7f2ea;
      --bg2: #dbe8f5;
      --ink: #1b2230;
      --muted: #5e6778;
      --card: rgba(255, 255, 255, 0.84);
      --line: #c9d2df;
      --accent: #be5a38;
      --accent-2: #246b8f;
      --pill: #eef4fb;
      --shadow: 0 14px 30px rgba(29, 50, 76, 0.16);
    }

    * { box-sizing: border-box; }

    body {
      margin: 0;
      color: var(--ink);
      font-family: "Bahnschrift", "Candara", "Segoe UI", sans-serif;
      background:
        radial-gradient(75rem 45rem at -10% -20%, #fff2cf 0%, transparent 55%),
        radial-gradient(70rem 40rem at 120% 0%, #c9e7ff 0%, transparent 60%),
        linear-gradient(125deg, var(--bg1), var(--bg2));
      min-height: 100vh;
    }

    .wrap {
      width: min(1100px, 92vw);
      margin: 2.2rem auto 3rem;
    }

    header {
      padding: 1.3rem 0 1.1rem;
      animation: rise 0.55s ease-out both;
    }

    h1 {
      margin: 0;
      font-size: clamp(1.85rem, 4vw, 2.75rem);
      font-family: "Rockwell", "Cambria", serif;
      letter-spacing: 0.02em;
    }

    .lead {
      margin: 0.55rem 0 0;
      color: var(--muted);
      font-size: 1rem;
    }

    .stats {
      margin-top: 0.8rem;
      color: #30415d;
      font-size: 0.95rem;
    }

    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(270px, 1fr));
      gap: 1rem;
    }

    .card {
      background: var(--card);
      border: 1px solid var(--line);
      border-radius: 16px;
      padding: 0.95rem 0.95rem 0.8rem;
      box-shadow: var(--shadow);
      backdrop-filter: blur(2px);
      animation: rise 0.4s ease-out both;
    }

    .card-head {
      display: flex;
      align-items: baseline;
      justify-content: space-between;
      gap: 0.7rem;
      margin-bottom: 0.5rem;
    }

    h2 {
      margin: 0;
      font-size: 1.08rem;
      line-height: 1.3;
      color: #163a58;
      word-break: break-word;
    }

    .pill {
      font-size: 0.78rem;
      color: #355779;
      background: var(--pill);
      border: 1px solid #ccdaea;
      border-radius: 999px;
      padding: 0.14rem 0.5rem;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      white-space: nowrap;
    }

    .desc {
      margin: 0.35rem 0 0.6rem;
      color: #273147;
      min-height: 2.3rem;
    }

    .meta {
      font-size: 0.78rem;
      color: #52617a;
      margin-bottom: 0.55rem;
    }

    .meta span {
      color: #1f304d;
      font-weight: 600;
    }

    .aliases {
      margin-bottom: 0.55rem;
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: 0.35rem;
    }

    .aliases-label {
      font-size: 0.78rem;
      color: #4a5d7a;
      font-weight: 600;
    }

    .alias-chip {
      border: 1px solid #d4deec;
      background: #f2f7ff;
      color: #244d78;
      border-radius: 999px;
      padding: 0.1rem 0.45rem;
      font-size: 0.75rem;
      font-family: "Consolas", "Cascadia Code", monospace;
    }

    pre {
      margin: 0;
      border-radius: 10px;
      border: 1px solid #d2dae8;
      background: linear-gradient(160deg, #f6fbff, #eef3fb);
      padding: 0.6rem 0.7rem;
      overflow-x: auto;
      font-size: 0.84rem;
      color: #2a3850;
    }

    code {
      font-family: "Consolas", "Cascadia Code", monospace;
    }

    @keyframes rise {
      from {
        transform: translateY(10px);
        opacity: 0;
      }
      to {
        transform: translateY(0);
        opacity: 1;
      }
    }

    @media (max-width: 640px) {
      .wrap {
        width: min(1100px, 94vw);
        margin-top: 1.3rem;
      }

      .card {
        padding: 0.85rem;
      }
    }
  </style>
</head>
<body>
  <div class="wrap">
    <header>
      <h1>PowerShell Function Catalog</h1>
      <p class="lead">All discovered functions from src, sorted alphabetically with a short description, aliases, and a runnable example.</p>
      <div class="stats"><strong>$count</strong> functions generated on <strong>$generatedAt</strong></div>
    </header>
    <section class="grid">
$($cards -join "`n")
    </section>
  </div>
</body>
</html>
"@

$outDir = Split-Path -Parent $OutputPath
if (-not (Test-Path -Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$html | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "Generated $OutputPath with $count functions." -ForegroundColor Green