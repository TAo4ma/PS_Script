#
# PowerShellコマンドレットを使用してMS Officeドキュメントのプロパティを読み書きするスクリプト
# rlv-danによってオンラインのさまざまなソースからコンパイルされました
#
# 関数:
# - Get-OfficeDocBuiltInProperties: ドキュメントの組み込みプロパティを取得します。
# - Get-OfficeDocBuiltInProperty: 指定された組み込みプロパティを取得します。
# - Set-OfficeDocBuiltInProperty: 指定された組み込みプロパティを設定します。
# - Get-OfficeDocCustomProperties: ドキュメントのカスタムプロパティを取得します。
# - Get-OfficeDocCustomProperty: 指定されたカスタムプロパティを取得します。
# - Set-OfficeDocCustomProperty: 指定されたカスタムプロパティを設定します。
#
# 使用例:
# 1. Wordアプリケーションを開始し、ドキュメントをロードします。
# 2. 組み込みプロパティをすべて取得します。
# 3. 組み込みの著者プロパティに書き込みます。
# 4. 組み込みの著者プロパティを再度読み取ります。
# 5. カスタムプロパティをすべて取得します（新しいドキュメントの場合はなし）。
# 6. カスタムプロパティに書き込みます。
# 7. カスタムプロパティを再度読み取ります。
# 8. ドキュメントを保存し、Wordを閉じます。
#
# 注意:
# - このスクリプトは、Wordドキュメントのプロパティを操作するためにCOMオブジェクトを使用します。
# - スクリプトの最後に、COMオブジェクトのリリースとガベージコレクションを行います。

# PowerShell cmdlets to read & write MS Office document properties
# Compiled by rlv-dan from various source online
 
function Get-OfficeDocBuiltInProperties {
    [OutputType([Hashtable])]
    Param
    (
         [Parameter(Mandatory=$true)]
         [System.__ComObject] $Document
    )
 
    $result = @{}
    $binding = "System.Reflection.BindingFlags" -as [type]
    $properties = $Document.BuiltInDocumentProperties
    
    foreach($property in $properties)
    {
        $pn = [System.__ComObject].invokemember("name",$binding::GetProperty,$null,$property,$null)
        trap [system.exception]
        {
            continue
        }
        $result.Add($pn, [System.__ComObject].invokemember("value",$binding::GetProperty,$null,$property,$null))
    }
 
    return $result
}
 
function Get-OfficeDocBuiltInProperty {
    [OutputType([string],$null)]
    Param
    (
         [Parameter(Mandatory=$true)]
         [string] $PropertyName,
         [Parameter(Mandatory=$true)]
         [System.__ComObject] $Document
    )
 
    try {
        $comObject = $Document.BuiltInDocumentProperties($PropertyName)
        $binding = "System.Reflection.BindingFlags" -as [type]
        $val = [System.__ComObject].invokemember("value",$binding::GetProperty,$null,$comObject,$null)
        return $val
    } catch {
        return $null
    }
}
 
function Set-OfficeDocBuiltInProperty {
    [OutputType([boolean])]
    Param
    (
         [Parameter(Mandatory=$true)]
         [string] $PropertyName,
         [Parameter(Mandatory=$true)]
         [string] $Value,
         [Parameter(Mandatory=$true)]
         [System.__ComObject] $Document
    )
 
    try {
        $comObject = $Document.BuiltInDocumentProperties($PropertyName)
        $binding = "System.Reflection.BindingFlags" -as [type]
        [System.__ComObject].invokemember("Value",$binding::SetProperty,$null,$comObject,$Value)
        return $true
    } catch {
        return $false
    }
}
 
 
function Get-OfficeDocCustomProperties {
    [OutputType([HashTable])]
    Param
    (
         [Parameter(Mandatory=$true, Position=2)]
         [System.__ComObject] $Document
    )
 
    $result = @{}
    $binding = "System.Reflection.BindingFlags" -as [type]
    $properties = $Document.CustomDocumentProperties
    foreach($property in $properties)
    {
        $pn = [System.__ComObject].invokemember("name",$binding::GetProperty,$null,$property,$null)
        trap [system.exception]
        {
            continue
        }
        $result.Add($pn, [System.__ComObject].invokemember("value",$binding::GetProperty,$null,$property,$null))
    }
 
    return $result
}
 
function Get-OfficeDocCustomProperty {
    [OutputType([string], $null)]
    Param
    (
         [Parameter(Mandatory=$true)]
         [string] $PropertyName,
         [Parameter(Mandatory=$true)]
         [System.__ComObject] $Document
    )
 
    try {
        $comObject = $Document.CustomDocumentProperties($PropertyName)
        $binding = "System.Reflection.BindingFlags" -as [type]
        $val = [System.__ComObject].invokemember("value",$binding::GetProperty,$null,$comObject,$null)
        return $val
    } catch {
        return $null
    }
}
 
function Set-OfficeDocCustomProperty {
    [OutputType([boolean])]
    Param
    (
         [Parameter(Mandatory=$true)]
         [string] $PropertyName,
         [Parameter(Mandatory=$true)]
         [string] $Value,
         [Parameter(Mandatory=$true)]
         [System.__ComObject] $Document
    )
 
    try
    {
        $customProperties = $Document.CustomDocumentProperties
        $binding = "System.Reflection.BindingFlags" -as [type]
        [array]$arrayArgs = $PropertyName,$false, 4, $Value
        try
        {
            [System.__ComObject].InvokeMember("add", $binding::InvokeMethod,$null,$customProperties,$arrayArgs) | out-null
        } 
        catch [system.exception] 
        {
            $propertyObject = [System.__ComObject].InvokeMember("Item", $binding::GetProperty, $null, $customProperties, $PropertyName)
            [System.__ComObject].InvokeMember("Delete", $binding::InvokeMethod, $null, $propertyObject, $null)
            [System.__ComObject].InvokeMember("add", $binding::InvokeMethod, $null, $customProperties, $arrayArgs) | Out-Null
        }
        return $true
    } 
    catch
    {
        return $false
    }
}


# . d:\OfficeProperties.ps1
 
write-host "Start Word and load a document..." -Foreground Yellow
$app = New-Object -ComObject Word.Application
$app.visible = $false
$doc = $app.Documents.Open("C:\Users\y0927\Documents\GitHub\PS_Script\技100-999.docx", $false, $false, $false)
 
write-host "`nAll BUILT IN Properties:" -Foreground Yellow
Get-OfficeDocBuiltInProperties $doc
 
write-host "`nWrite to BUILT IN author property:" -Foreground Yellow
$result = Set-OfficeDocBuiltInProperty "Author" "Mr. Robot" $doc
write-host "Result: $result"
 
write-host "`nRead BUILT IN author again:" -Foreground Yellow
Get-OfficeDocBuiltInProperty "Author" $doc
 
write-host "`nAll CUSTOM Properties (none if new document):" -Foreground Yellow
Get-OfficeDocCustomProperties $doc
 
write-host "`nWrite a CUSTOM property:" -Foreground Yellow
$result = Set-OfficeDocCustomProperty "Hacked by" "fsociety" $doc
write-host "Result: $result"
 
write-host "`nRead back the CUSTOM property:" -Foreground Yellow
Get-OfficeDocCustomProperty "Hacked by" $doc

write-host "`2 nAll CUSTOM Properties (none if new document):" -Foreground Yellow
Get-OfficeDocCustomProperties $doc

write-host "`nWrite a CUSTOM property:" -Foreground Yellow
$result = Set-OfficeDocCustomProperty "Batter" "Otani" $doc
write-host "Result: $result"
 
write-host "`2 nAll CUSTOM Properties (none if new document):" -Foreground Yellow
Get-OfficeDocCustomProperties $doc


write-host "`nAll CUSTOM Properties (none if new document):" -Foreground Yellow
Get-OfficeDocCustomProperties $doc




write-host "`nSave document and close Word..." -Foreground Yellow
$doc.Save()
$doc.Close()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($doc) | Out-Null
$app.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($app) | Out-Null
[gc]::collect()
[gc]::WaitForPendingFinalizers()
write-host "`nReady!" -Foreground Green


