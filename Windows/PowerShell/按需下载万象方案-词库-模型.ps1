############# �Զ�������������úú� AutoUpdate ����Ϊ true ���� #############
# $AutoUpdate = $true;
$AutoUpdate = $false;
####[0]-���; [1]-С��; [2]-����; [3]-�򵥺�; [4]-ī��; [5]-����; [6]-���; [7]-��Ȼ��"
####ע��������˫���ţ����磺$InputSchemaType = "0";
$InputSchemaType = "7";
# $SkipFiles = @(
#     "wanxiang_en.dict.yaml",
#     "chars.dict.yaml"
# ); # ��Ҫ�������ļ��б�
############# �Զ�������������úú� AutoUpdate ����Ϊ true ���� #############

# ���òֿ������ߺ�����
$SchemaOwner = "amzxyz"
$SchemaRepo = "rime_wanxiang_pro"
$GramRepo = "RIME-LMDG"
$GramReleaseTag = "LTS"
$GramModelFileName = "wanxiang-lts-zh-hans.gram"
$ReleaseTimeRecordFile = "release_time_record.json"
# ������ʱ�ļ�·��
$tempSchemaZip = Join-Path $env:TEMP "wanxiang_schema_temp.zip"
$tempDictZip = Join-Path $env:TEMP "wanxiang_dict_temp.zip"
$tempGram = Join-Path $env:TEMP "wanxiang-lts-zh-hans.gram"
$tempGramMd5 = Join-Path $env:TEMP "wanxiang-lts-zh-hans.gram.md5"
$SchemaExtractPath = Join-Path $env:TEMP "wanxiang_schema_extract"
$DictExtractPath = Join-Path $env:TEMP "wanxiang_dict_extract"

$Debug = $false;

$KeyTable = @{
    "0" = "cj";
    "1" = "flypy";
    "2" = "hanxin";
    "3" = "jdh";
    "4" = "moqi";
    "5" = "tiger";
    "6" = "wubi";
    "7" = "zrm"
}

$GramKeyTable = @{
    "0" = "zh-hans.gram";
    "1" = "md5sum";
}

$GramFileTableIndex = 0;
$GramMd5TableIndex = 1;

# ���ð�ȫЭ��ΪTLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ��ȡ Weasel �û�Ŀ¼·��
function Get-RegistryValue {
    param(
        [string]$regPath,
        [string]$regValue
    )
    
    try {
        # ��ȡע���ֵ
        $value = (Get-ItemProperty -Path $regPath -Name $regValue).$regValue
        # ���ؽ��
        return $value
    }
    catch {
        Write-Host "���棺ע���·�� $regPath �����ڣ��������뷨�Ƿ���ȷ��װ" -ForegroundColor Yellow
        return $null
    }
}

function Get-FileNameWithoutExtension {
    param(
        [string]$filePath
    )
    $fileName = Split-Path $filePath -Leaf
    return $fileName -replace '\.[^.]+$', ''
}

function Get-ExtractedFolderPath {
    param(
        [string]$extractPath,
        [string]$assetName
    )
    $folders = Get-ChildItem -Path $extractPath -Directory
    foreach ($folder in $folders) {
        if ($folder.Name -match $assetName) {
            return $folder.FullName
        }
    }
    return Join-Path $extractPath $(Get-FileNameWithoutExtension -filePath $assetName)
}

function Get-WeaselUserDir {
    try {
        $userDir = Get-RegistryValue -regPath "HKCU:\Software\Rime\Weasel" -regValue "RimeUserDir"
        if (-not $userDir) {
            # appdata Ŀ¼�µ� Rime Ŀ¼
            $userDir = Join-Path $env:APPDATA "Rime"
        }
        return $userDir
    }
    catch {
        Write-Host "���棺δ�ҵ�Weasel�û�Ŀ¼����ȷ������ȷ��װС�Ǻ����뷨" -ForegroundColor Yellow
    }
}

function Get-WeaselInstallDir {
    try {
        return Get-RegistryValue -regPath "HKLM:\SOFTWARE\WOW6432Node\Rime\Weasel" -regValue "WeaselRoot"
    }
    catch {
        Write-Host "���棺δ�ҵ�Weasel��װĿ¼����ȷ������ȷ��װС�Ǻ����뷨" -ForegroundColor Yellow
        return $null
    }
}

function Get-WeaselServerExecutable {
    try {
        return Get-RegistryValue -regPath "HKLM:\SOFTWARE\WOW6432Node\Rime\Weasel" -regValue "ServerExecutable"
    }
    catch {
        Write-Host "���棺δ�ҵ�Weasel����˿�ִ�г�����ȷ������ȷ��װС�Ǻ����뷨" -ForegroundColor Yellow
        return $null
    }
}

function Test-SkipFile {
    param(
        [string]$filePath
    )
    return $SkipFiles -contains $filePath
}

# ���ú�������ֵ������
$rimeUserDir = Get-WeaselUserDir
$rimeInstallDir = Get-WeaselInstallDir
$rimeServerExecutable = Get-WeaselServerExecutable

function Stop-WeaselServer {
    if (-not $rimeServerExecutable) {
        Write-Host "���棺δ�ҵ�Weasel����˿�ִ�г�����ȷ������ȷ��װС�Ǻ����뷨" -ForegroundColor Yellow
        exit 1
    }
    Start-Process -FilePath (Join-Path $rimeInstallDir $rimeServerExecutable) -ArgumentList '/q'
}

function Start-WeaselServer {
    if (-not $rimeServerExecutable) {
        Write-Host "���棺δ�ҵ�Weasel����˿�ִ�г�����ȷ������ȷ��װС�Ǻ����뷨" -ForegroundColor Yellow
        exit 1
    }
    Start-Process -FilePath (Join-Path $rimeInstallDir $rimeServerExecutable)
}

function Start-WeaselReDeploy{
    $defaultShortcutPath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\С�Ǻ����뷨\��С�Ǻ������²���.lnk"
    if (Test-Path -Path $defaultShortcutPath) {
        Write-Host "�ҵ�Ĭ�ϡ�С�Ǻ������²����ݷ�ʽ����ִ��" -ForegroundColor Green
        Invoke-Item -Path $defaultShortcutPath
    }
    else {
        Write-Host "δ�ҵ�Ĭ�ϵġ�С�Ǻ������²����ݷ�ʽ��������ִ��Ĭ�ϵ����²�������" -ForegroundColor Yellow
        Write-Host "�����������²���" -ForegroundColor Yellow
    }
}

# ����Ҫ·���Ƿ�Ϊ��
if (-not $rimeUserDir -or -not $rimeInstallDir -or -not $rimeServerExecutable) {
    Write-Host "�����޷���ȡWeasel��Ҫ·�����������뷨�Ƿ���ȷ��װ" -ForegroundColor Red
    exit 1
}
Write-Host "Weasel�û�Ŀ¼·��Ϊ: $rimeUserDir"
$targetDir = $rimeUserDir
$TimeRecordFile = Join-Path $targetDir $ReleaseTimeRecordFile

function Test-VersionSuffix {
    param(
        [string]$url
    )
    
    $pattern = '/v\d+\.\d+\.\d+$'
    return $url -match $pattern
}

function Test-DictSuffix {
    param(
        [string]$url
    )

    # https://github.com/amzxyz/rime_wanxiang_pro/releases/SchemaTag/dict-nightly
    $pattern = '/dict-nightly$'
    return $url -match $pattern
}

function Get-ReleaseInfo {
    param(
        [string]$owner,
        [string]$repo
    )
    # ����API����URL
    $apiUrl = "https://api.github.com/repos/$owner/$repo/releases"

    try {
        # ����API����
        $response = Invoke-RestMethod -Uri $apiUrl -Headers @{
            "User-Agent" = "PowerShell Release Downloader"
            "Accept" = "application/vnd.github.v3+json"
        }
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.Value__
        if ($statusCode -eq 404) {
            Write-Error "���󣺲ֿ� '$owner/$repo' �����ڻ�û�з����汾"
        }
        else {
            Write-Error "API����ʧ�� [$statusCode]��$_"
        }
        exit 1
    }

    # ����Ƿ��п�������Դ
    if ($response.assets.Count -eq 0) {
        Write-Error "�ð汾û�п�������Դ" -ForegroundColor Red
        exit 1
    }
    return $response
}

# ��ȡ���µİ汾��Ϣ
$SchemaResponse = Get-ReleaseInfo -owner $SchemaOwner -repo $SchemaRepo
$GramResponse = Get-ReleaseInfo -owner $SchemaOwner -repo $GramRepo

$SelectedDictRelease = $null
$SelectedSchemaRelease = $null
$SelectedGramRelease = $null

foreach ($release in $SchemaResponse) {
    if (Test-DictSuffix -url $release.html_url) {
        $SelectedDictRelease = $release
    }
    if (Test-VersionSuffix -url $release.html_url) {
        $SelectedSchemaRelease = $release
    }
    if ($SelectedDictRelease -and $SelectedSchemaRelease) {
        break
    }
}

foreach ($release in $GramResponse) {
    if ($Debug) {
        Write-Host "release.tag_name: $($release.tag_name)" -ForegroundColor Green
        Write-Host "GramReleaseTag: $GramReleaseTag" -ForegroundColor Green
    }
    if ($release.tag_name -eq $GramReleaseTag) {
        $SelectedGramRelease = $release
    }
}

if ($SelectedDictRelease -and $SelectedSchemaRelease -and $SelectedGramRelease) {
    Write-Host "���������µĴʿ�����Ϊ��$($SelectedDictRelease.html_url)" -ForegroundColor Green
    Write-Host "���������µİ汾����Ϊ��$($SelectedSchemaRelease.html_url)" -ForegroundColor Green
    Write-Host "���������µ�ģ������Ϊ��$($SelectedGramRelease.html_url)" -ForegroundColor Green
} else {
    Write-Error "δ�ҵ����������İ汾��ʿ�����"
    exit 1
}

# ��ȡ���µİ汾��tag_name
Write-Host "���µİ汾Ϊ��$($SelectedSchemaRelease.tag_name)"
$SchemaTag = $SelectedSchemaRelease.tag_name

$promptSchemaType = "��ѡ����Ҫ���صĸ����뷽�����͵ı��: `n[0]-���; [1]-С��; [2]-����; [3]-�򵥺�; [4]-ī��; [5]-����; [6]-���; [7]-��Ȼ��"
$promptAllUpdate = "�Ƿ�����������ݣ��������ʿ⡢ģ�ͣ�:`n[0]-��������; [1]-����������"
$promptSchemaDown = "�Ƿ����ط���:`n[0]-����; [1]-������"
$promptGramModel = "�Ƿ�����ģ��:`n[0]-����; [1]-������"
$promptDictDown = "�Ƿ����شʿ�:`n[0]-����; [1]-������"

if (-not $Debug) {
    if ($AutoUpdate) {
        Write-Host "�Զ�����ģʽ�����Զ��������µİ汾" -ForegroundColor Green
        Write-Host "�����õķ�����Ϊ��$InputSchemaType" -ForegroundColor Green
        # ������ֻ֧��0-7
        if ($InputSchemaType -lt 0 -or $InputSchemaType -gt 7) {
            Write-Error "���󣺷�����ֻ����0-7" -ForegroundColor Red
            exit 1
        }
        $InputAllUpdate = "0"
        $InputSchemaDown = "0"
        $InputGramModel = "0"
        $InputDictDown = "0"
    } else {
        $InputSchemaType = Read-Host $promptSchemaType
        $InputAllUpdate = Read-Host $promptAllUpdate
        if ($InputAllUpdate -eq "0") {
            $InputSchemaDown = "0"
            $InputGramModel = "0"
            $InputDictDown = "0"
        } else {
            $InputSchemaDown = Read-Host $promptSchemaDown
            $InputGramModel = Read-Host $promptGramModel
            $InputDictDown = Read-Host $promptDictDown
        }
    }
} else {
    $InputSchemaType = "7"
    $InputSchemaDown = "0"
    $InputGramModel = "0"
    $InputDictDown = "0"
}

# �����û�����ķ����Ż�ȡ��������
function Get-ExpectedAssetTypeInfo {
    param(
        [string]$index,
        [hashtable]$keyTable,
        [Object]$releaseObject
    )
    
    $info = $null
    
    foreach ($asset in $releaseObject.assets) {
        if ($Debug) {
            Write-Host "asset.name: $($asset.name)" -ForegroundColor Green
            Write-Host "keyTable[$index]: $($keyTable[$index])" -ForegroundColor Green
        }

        if ($asset.name -match $keyTable[$index]) {
            $info = $asset
            # ��ӡ
            if ($Debug) {
                Write-Host "ƥ��ɹ���asset.name: $($asset.name)" -ForegroundColor Green
                Write-Host "Ŀ����ϢΪ��$($info)"
            }
        }
    }

    return $info
}

$ExpectedSchemaTypeInfo = Get-ExpectedAssetTypeInfo -index $InputSchemaType -keyTable $KeyTable -releaseObject $SelectedSchemaRelease
$ExpectedDictTypeInfo = Get-ExpectedAssetTypeInfo -index $InputSchemaType -keyTable $KeyTable -releaseObject $SelectedDictRelease
$ExpectedGramTypeInfo = Get-ExpectedAssetTypeInfo -index $GramFileTableIndex -keyTable $GramKeyTable -releaseObject $SelectedGramRelease
$ExpectedGramMd5TypeInfo = Get-ExpectedAssetTypeInfo -index $GramMd5TableIndex -keyTable $GramKeyTable -releaseObject $SelectedGramRelease

if (-not $ExpectedSchemaTypeInfo -or -not $ExpectedDictTypeInfo -or -not $ExpectedGramTypeInfo -or -not $ExpectedGramMd5TypeInfo) {
    Write-Error "δ�ҵ�������������������" -ForegroundColor Red
    exit 1
}

# ��ӡ
if ($InputSchemaDown -eq "0") {
    Write-Host "���ط���" -ForegroundColor Green
    if ($Debug) {
        Write-Host "���µĸ����뷽��������ϢΪ��$($ExpectedSchemaTypeInfo)" -ForegroundColor Green
    }
}

if ($InputDictDown -eq "0") {
    Write-Host "���شʿ�" -ForegroundColor Green
    if ($Debug) {
        Write-Host "���µĸ�����ʿ�������ϢΪ��$($ExpectedDictTypeInfo)" -ForegroundColor Green
    }
}

if ($InputGramModel -eq "0") {
    Write-Host "����ģ��" -ForegroundColor Green
    if ($Debug) {
        Write-Host "���µĸ�����ģ��������ϢΪ��$($ExpectedGramTypeInfo)" -ForegroundColor Green
    }
}

function Save-TimeRecord {
    param(
        [string]$filePath,
        [string]$key,
        [string]$value
    )
    
    $timeData = @{}
    if (Test-Path $filePath) {
        try {
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                $timeData = Get-Content $filePath | ConvertFrom-Json -AsHashtable
            } else {
                $timeData = Get-Content $filePath | ConvertFrom-Json | ForEach-Object {
                    $ht = @{}
                    $_.PSObject.Properties | ForEach-Object { $ht[$_.Name] = $_.Value }
                    $ht
                }
            }
        }
        catch {
            Write-Host "���棺�޷���ȡʱ���¼�ļ����������µļ�¼" -ForegroundColor Yellow
        }
    }

    $timeData[$key] = $value
    
    try {
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $timeData | ConvertTo-Json | Set-Content $filePath
        } else {
            $timeData | ConvertTo-Json -Depth 100 | Set-Content $filePath
        }
    }
    catch {
        Write-Host "�����޷�����ʱ���¼" -ForegroundColor Red
    }
}

function Get-TimeRecord {
    param(
        [string]$filePath,
        [string]$key
    )
    
    if (Test-Path $filePath) {
        try {
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                $timeData = Get-Content $filePath | ConvertFrom-Json -AsHashtable
            } else {
                $json = Get-Content $filePath | ConvertFrom-Json
                $timeData = @{}
                $json.PSObject.Properties | ForEach-Object { $timeData[$_.Name] = $_.Value }
            }
            return $timeData[$key]
        }
        catch {
            Write-Host "���棺�޷���ȡʱ���¼�ļ�" -ForegroundColor Yellow
        }
    }
    return $null
}

# �Ƚϱ��غ�Զ�̸���ʱ��
function Compare-UpdateTime {
    param(
        [Object]$localTime,
        [datetime]$remoteTime
    )

    if ($localTime -eq $null) {
        Write-Host "����ʱ���¼�����ڣ��������µ�ʱ���¼" -ForegroundColor Yellow
        return $true
    }

    $localTime = [datetime]::Parse($localTime)

    if ($remoteTime -eq $null) {
        Write-Host "Զ��ʱ���¼�����ڣ��޷��Ƚ�" -ForegroundColor Red
        return $false
    }
    
    if ($remoteTime -gt $localTime) {
        Write-Host "�����°汾��׼������" -ForegroundColor Green
        return $true
    }
    Write-Host "��ǰ�������°汾" -ForegroundColor Yellow
    return $false
}

# ��JSON�ļ����ز�����UpdateTimeKey
function Load-UpdateTimeKey {
    param(
        [string]$filePath
    )
    
    if (-not (Test-Path $filePath)) {
        Write-Host "���棺ʱ���¼�ļ�������" -ForegroundColor Yellow
        return $null
    }
    
    try {
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $timeData = Get-Content $filePath | ConvertFrom-Json -AsHashtable
        } else {
            $json = Get-Content $filePath | ConvertFrom-Json
            $timeData = @{}
            $json.PSObject.Properties | ForEach-Object { $timeData[$_.Name] = $_.Value }
        }
        return $timeData
    }
    catch {
        Write-Host "�����޷�����JSON�ļ�" -ForegroundColor Red
        return $null
    }
}

# ���ʱ���¼�ļ�
$hasTimeRecord = Load-UpdateTimeKey -filePath $TimeRecordFile

if (-not $hasTimeRecord) {
    Write-Host "ʱ���¼�ļ������ڣ��������µ�ʱ���¼" -ForegroundColor Yellow
}

# ����Ŀ��Ŀ¼����������ڣ�
if (-not (Test-Path $targetDir)) {
    Write-Host "����Ŀ��Ŀ¼: $targetDir" -ForegroundColor Green
    New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
}

# ���غ���
function Download-Files {
    param(
        [Object]$assetInfo,
        [string]$outFilePath
    )
    
    try {
        $downloadUrl = $assetInfo.browser_download_url
        Write-Host "���������ļ�:$($assetInfo.name)..." -ForegroundColor Green
        Invoke-WebRequest -Uri $downloadUrl -OutFile $outFilePath -UseBasicParsing
        Write-Host "�������" -ForegroundColor Green
    }
    catch {
        Write-Host "����ʧ��: $_" -ForegroundColor Red
        exit 1
    }
}

# ��ѹ zip �ļ�
function Expand-ZipFile {
    param(
        [string]$zipFilePath,
        [string]$destinationPath
    )

    try {
        Write-Host "���ڽ�ѹ�ļ�: $zipFilePath" -ForegroundColor Green
        Write-Host "��ѹ��: $destinationPath" -ForegroundColor Green
        Expand-Archive -Path $zipFilePath -DestinationPath $destinationPath -Force
        Write-Host "��ѹ���" -ForegroundColor Green
    }
    catch {
        Write-Host "��ѹʧ��: $_" -ForegroundColor Red
        Remove-Item -Path $zipFilePath -Force -ErrorAction SilentlyContinue
        exit 1
    }
}

if ($InputSchemaDown -eq "0" -or $InputDictDown -eq "0" -or $InputGramModel -eq "0") {
    # ��ʼ���´ʿ⣬�����ڿ�ʼ��Ҫ�������̣�ֱ��������ɣ�����ᴥ��С�Ǻ��������ļ����¸澯�����¸���ʧ�ܣ�����ĸ�����ɺ���Զ�����С�Ǻ�
    Write-Host "���ڸ��´ʿ⣬�벻Ҫ�������̣�ֱ���������" -ForegroundColor Red
    Write-Host "������ɺ���Զ�����С�Ǻ�" -ForegroundColor Red
} else {
    exit 0
}

$UpdateFlag = $false

if ($InputSchemaDown -eq "0") {
    # ���ط���
    $SchemaUpdateTimeKey = $KeyTable[$InputSchemaType] + "_schema_update_time"
    $SchemaUpdateTime = Get-TimeRecord -filePath $TimeRecordFile -key $SchemaUpdateTimeKey
    $SchemaRemoteTime = [datetime]::Parse($ExpectedSchemaTypeInfo.updated_at)
    Write-Host "���ڼ�鷽���Ƿ���Ҫ����..." -ForegroundColor Green
    Write-Host "����ʱ��: $SchemaUpdateTime" -ForegroundColor Green
    Write-Host "Զ��ʱ��: $SchemaRemoteTime" -ForegroundColor Green
    if (Compare-UpdateTime -localTime $SchemaUpdateTime -remoteTime $SchemaRemoteTime) {
        $UpdateFlag = $true
        Write-Host "�������ط���..." -ForegroundColor Green
        Download-Files -assetInfo $ExpectedSchemaTypeInfo -outFilePath $tempSchemaZip
        Write-Host "���ڽ�ѹ����..." -ForegroundColor Green
        Expand-ZipFile -zipFilePath $tempSchemaZip -destinationPath $SchemaExtractPath
        Write-Host "���ڸ����ļ�..." -ForegroundColor Green
        $sourceDir = Get-ExtractedFolderPath -extractPath $SchemaExtractPath -assetName $KeyTable[$InputSchemaType]
        if (-not (Test-Path $sourceDir)) {
            Write-Host "����ѹ������δ�ҵ� $sourceDir Ŀ¼" -ForegroundColor Red
            Remove-Item -Path $tempSchemaZip -Force
            Remove-Item -Path $SchemaExtractPath -Recurse -Force
            exit 1
        }
        Stop-WeaselServer
        # �ȴ�1��
        Start-Sleep -Seconds 1
        Get-ChildItem -Path $sourceDir | ForEach-Object {
            if (Test-SkipFile -filePath $_.Name) {
                Write-Host "�����ļ�: $($_.Name)" -ForegroundColor Yellow
            } else {
                Copy-Item -Path $_.FullName -Destination $targetDir -Recurse -Force
            }
        }

        # �����ڵı���ʱ���¼��JSON�ļ�
        Save-TimeRecord -filePath $TimeRecordFile -key $SchemaUpdateTimeKey -value $SchemaRemoteTime
        # ������ʱ�ļ�
        Remove-Item -Path $tempSchemaZip -Force
        Remove-Item -Path $SchemaExtractPath -Recurse -Force
    }
}

if ($InputDictDown -eq "0") {
    # ���شʿ�
    $DictUpdateTimeKey = $KeyTable[$InputSchemaType] + "_dict_update_time"
    $DictUpdateTime = Get-TimeRecord -filePath $TimeRecordFile -key $DictUpdateTimeKey
    $DictRemoteTime = [datetime]::Parse($ExpectedDictTypeInfo.updated_at)
    Write-Host "���ڼ��ʿ��Ƿ���Ҫ����..." -ForegroundColor Green
    Write-Host "����ʱ��: $DictUpdateTime" -ForegroundColor Green
    Write-Host "Զ��ʱ��: $DictRemoteTime" -ForegroundColor Green
    if (Compare-UpdateTime -localTime $DictUpdateTime -remoteTime $DictRemoteTime) {
        $UpdateFlag = $true
        Write-Host "�������شʿ�..." -ForegroundColor Green
        Download-Files -assetInfo $ExpectedDictTypeInfo -outFilePath $tempDictZip
        Write-Host "���ڽ�ѹ�ʿ�..." -ForegroundColor Green
        Expand-ZipFile -zipFilePath $tempDictZip -destinationPath $DictExtractPath
        Write-Host "���ڸ����ļ�..." -ForegroundColor Green
        $sourceDir = Get-ExtractedFolderPath -extractPath $DictExtractPath -assetName $KeyTable[$InputSchemaType]
        if (-not (Test-Path $sourceDir)) {
            Write-Host "����ѹ������δ�ҵ� $sourceDir Ŀ¼" -ForegroundColor Red
            Remove-Item -Path $DictExtractPath -Force -Recurse
            exit 1
        }
        Stop-WeaselServer
        # �ȴ�1��
        Start-Sleep -Seconds 1
        Get-ChildItem -Path $sourceDir | ForEach-Object {
            if (Test-SkipFile -filePath $_.Name) {
                Write-Host "�����ļ�: $($_.Name)" -ForegroundColor Yellow
            }
        }

        # �����ڵı���ʱ���¼��JSON�ļ�
        Save-TimeRecord -filePath $TimeRecordFile -key $DictUpdateTimeKey -value $DictRemoteTime -isDict $true
        # ������ʱ�ļ�
        Remove-Item -Path $DictExtractPath -Recurse -Force
    }
}

function Update-GramModel {
    $UpdateFlag = $true
    Write-Host "��������ģ��..." -ForegroundColor Green
    Download-Files -assetInfo $ExpectedGramTypeInfo -outFilePath $tempGram
    Write-Host "��������ģ��MD5..." -ForegroundColor Green
    Download-Files -assetInfo $ExpectedGramMd5TypeInfo -outFilePath $tempGramMd5
    Write-Host "������֤ģ��MD5..." -ForegroundColor Green
    $remoteMd5 = (Get-Content -Raw $tempGramMd5).Split(' ')[0]
    $localMd5 = (Get-FileHash $tempGram -Algorithm MD5).Hash.ToLower()
    if ($remoteMd5 -ne $localMd5) {
        Write-Host "ģ��MD5��֤ʧ��" -ForegroundColor Red
        # Remove-Item -Path $tempGram -Force
        Remove-Item -Path $tempGramMd5 -Force
        exit 1
    }
    Write-Host "���ڸ����ļ�..." -ForegroundColor Green

    Stop-WeaselServer
    # �ȴ�1��
    Start-Sleep -Seconds 1
    Copy-Item -Path $tempGram -Destination $targetDir -Force
    # �����ڵı���ʱ���¼��JSON�ļ�
    Save-TimeRecord -filePath $TimeRecordFile -key $GramUpdateTimeKey -value $GramRemoteTime
    # ������ʱ�ļ�
    Remove-Item -Path $tempGram -Force
}

if ($InputGramModel -eq "0") {
    # ����ģ��
    $GramUpdateTimeKey = $GramReleaseTag + "_gram_update_time"
    $GramUpdateTime = Get-TimeRecord -filePath $TimeRecordFile -key $GramUpdateTimeKey
    $GramRemoteTime = [datetime]::Parse($ExpectedGramTypeInfo.updated_at)
    Write-Host "���ڼ��ģ���Ƿ���Ҫ����..." -ForegroundColor Green
    # ���Ŀ���ļ� $targetDir/$tempGram �Ƿ����
    $filePath = Join-Path $targetDir $GramModelFileName
    if ($Debug) {
        Write-Host "ģ���ļ�·��: $filePath" -ForegroundColor Green
    }
    Write-Host "����ʱ��: $GramUpdateTime" -ForegroundColor Green
    Write-Host "Զ��ʱ��: $GramRemoteTime" -ForegroundColor Green
    if (Compare-UpdateTime -localTime $GramUpdateTime -remoteTime $GramRemoteTime) {
        Update-GramModel
    }elseif (Test-Path -Path $filePath) {
        # ����Ŀ���ļ���MD5
        $localMd5 = (Get-FileHash $filePath -Algorithm MD5).Hash.ToLower()
        # ����Զ���ļ���MD5
        $remoteMd5 = (Get-Content -Raw $tempGramMd5).Split(' ')[0]
        # �Ƚ�MD5
        if ($localMd5 -ne $remoteMd5) {
            Write-Host "ģ��MD5��ƥ�䣬��Ҫ����" -ForegroundColor Red
            Update-GramModel
        }   
    } else {
        Write-Host "ģ�Ͳ����ڣ���Ҫ����" -ForegroundColor Red
        Update-GramModel
    }
}

Write-Host "��������ɣ��ļ��Ѳ��� Weasel ����Ŀ¼:$($targetDir)" -ForegroundColor Green

if ($UpdateFlag) {
    Start-WeaselServer
    # �ȴ�1��
    Start-Sleep -Seconds 1
    Write-Host "���ݸ��£�����С�Ǻ����²���..." -ForegroundColor Green
    Start-WeaselReDeploy
}
