class WordInstanceData {
    [object]$Application
    [object]$Document
    [hashtable]$DocumentProperties
    [hashtable]$CustomProperties
    [object]$PC
    [ImageHandler]$ImageHandler
    [TableHandler]$TableHandler

    WordInstanceData([string]$filePath, [object]$pc) {
        $this.PC = $pc
        if (-not $this.PC.IsLibraryConfigured) {
            Write-Error "Microsoft.Office.Interop.Word ライブラリが設定されていません。"
            return
        }

        $this.Application = New-Object -ComObject Word.Application
        $this.Application.Visible = $true
        $this.Document = $this.Application.Documents.Open($filePath)
        $this.DocumentProperties = $this.GetDocumentProperties()
        # $this.CustomProperties = $this.GetCustomProperties()
        $this.ImageHandler = [ImageHandler]::new($this.Document)
        $this.TableHandler = [TableHandler]::new($this.Document)
    }

    [void]Close() {
        $this.Document.Close()
        $this.Application.Quit()
    }

    # ドキュメントを保存閉じる
    [void]Save() {
        [ref]$SaveOption = "Microsoft.Office.Interop.Word.WdSaveOptions" -as [type]
        $this.document.Close([ref]$SaveOption::wdDoNotSaveChanges)
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($this.builtinProperties) | Out-Null
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($this.document) | Out-Null
        Remove-Variable -Name document, BuiltinProperties
    }

    [hashtable]GetDocumentProperties() {
        $properties = @{}
        $binding = "System.Reflection.BindingFlags" -as [type]
        $iniFilePath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "config_Change_Properties_Word.ini"
        $iniContent = Get-IniContent -Path $iniFilePath

        $AryProperties = @(
            $iniContent["Basic_Information_Properties"].Keys,
            $iniContent["Detailed_Information_Properties"].Keys,
            $iniContent["Contents_Properties"].Keys,
            $iniContent["FileSystem_Infromation"].Keys
        ) -join ','

        try {
            $builtinProperties = $this.Document.BuiltInDocumentProperties
            foreach ($p in $AryProperties) {
                try {
                    $pn = [System.__ComObject].InvokeMember("Item", $binding::GetProperty, $null, $builtinProperties, $p)
                    $value = [System.__ComObject].InvokeMember("Value", $binding::GetProperty, $null, $pn, $null)
                    $properties[$p] = $value
                } catch [System.Exception] {
                    Write-Host -ForegroundColor Blue "Value not found for $p"
                }
            }
        } catch {
            Write-Error "ビルトインプロパティの取得に失敗しました: $_"
        }
        return $properties
    }

    [PSCustomObject] GetCustomObject() {
        $iniFilePath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "config_Change_Properties_Word.ini"
        $iniContent = Get-IniContent -Path $iniFilePath

        $objHash = @{}
        foreach ($section in $iniContent.Keys) {
            foreach ($key in $iniContent[$section].Keys) {
                $objHash[$key] = $iniContent[$section][$key]
            }
        }

        return [PSCustomObject]$objHash
    }
}

class ImageHandler {
    [object]$Document

    ImageHandler([object]$document) {
        $this.Document = $document
    }

    [void]ProcessImage([string]$imagePath) {
        # 1つ目のセルを取得
        Write-Host "1つ目のセルを取得中..."
        $cell = $this.Document.Tables.Item(1).Cell(2, 6)
        Write-Host "Cell (2, 6) retrieved."

        # セルの座標とサイズを取得
        $left = $cell.Range.Information(1) # 1 corresponds to wdHorizontalPositionRelativeToPage
        $top = $cell.Range.Information(2) # 2 corresponds to wdVerticalPositionRelativeToPage
        $width = $cell.Width
        $height = $cell.Height
        Write-Host "Cell coordinates and size retrieved: Left=$left, Top=$top, Width=$width, Height=$height"

        # 画像のサイズを設定
        $imageWidth = 50
        $imageHeight = 50

        # 画像の中央位置を計算
        $imageLeft = $left + ($width - $imageWidth) / 2
        $imageTop = $top + ($height - $imageHeight) / 2

        # 既存の画像を削除（もしあれば）
        Write-Host "既存の画像を削除中..."
        foreach ($shape in $this.Document.Shapes) {
            if ($shape.Type -eq 13) { # 13 corresponds to msoPicture
                $shape.Delete()
            }
        }
        Write-Host "Existing images deleted."

        # 新しい画像を挿入
        Write-Host "新しい画像を挿入中..."
        $shape = $this.Document.Shapes.AddPicture($imagePath, $false, $true, $imageLeft, $imageTop, $imageWidth, $imageHeight)
        Write-Host "New image inserted."

        # 画像のプロパティを変更
        Write-Host "画像のプロパティを変更中..."
        $shape.LockAspectRatio = $false
        $shape.Width = 50
        $shape.Height = 50
        Write-Host "Image properties modified."
    }
}

class TableHandler {
    [object]$Document

    TableHandler([object]$document) {
        $this.Document = $document
    }

    [void]ProcessTable() {
        Write-Host "1つ目のテーブルを取得中..."
        try {
            $table = $this.Document.Tables.Item(1)
            Write-Host "First table retrieved."
        } catch {
            Write-Error "テーブルの取得に失敗しました: $_"
            return
        }

        # テーブルのプロパティを取得
        $rows = $table.Rows.Count
        $columns = $table.Columns.Count
        Write-Host "Table properties retrieved: Rows=$rows, Columns=$columns"

        # 各セルの情報を取得
        foreach ($row in 1..$rows) {
            foreach ($column in 1..$columns) {
                $cell = $table.Cell($row, $column)
                Write-Host "Cell ($row, $column): $($cell.Range.Text)"
            }
        }
    }
}

function Get-IniContent {
    param (
        [string]$Path
    )

    $iniContent = @{}
    $currentSection = ""

    foreach ($line in Get-Content -Path $Path) {
        if ($line -match "^\[(.+)\]$") {
            $currentSection = $matches[1]
            $iniContent[$currentSection] = @{}
        } elseif ($line -match "^(.+?)=(.*)$") {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            $iniContent[$currentSection][$key] = $value
        }
    }

    return $iniContent
}