param (
    [switch]$help,
    [switch]$backup,
    [switch]$download,
    [string]$file
)

# Set global variables
$sourceFolder = "C:\path\to\your\folder"
$bucketName = "your-s3-bucket-name"
$region = "your-aws-region"

if ($help) {
    Write-Host "Menu Help:"
    Write-Host "  -help: Display this help menu."
    Write-Host "  -backup: Perform backup operation to S3."
    Write-Host "  -download -file [file-name]: Download file from S3 with specified file name."
}
elseif ($backup) {
    # Check if AWS Tools for PowerShell is installed, if not, install it
    if (-not (Get-Module -Name AWSPowerShell -ListAvailable)) {
        Write-Host "AWS Tools for PowerShell is not installed. Installing..."
        Install-Module -Name AWSPowerShell -Force -AllowClobber
        Import-Module AWSPowerShell
        Write-Host "AWS Tools for PowerShell installed."
    }

    # Create zip file name with timestamp format
    $zipFileName = "backup_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".zip"
    $zipFilePath = Join-Path -Path $env:TEMP -ChildPath $zipFileName

    # Compress source folder into a zip file
    Write-Host "Compressing source folder into a zip file..."
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($sourceFolder, $zipFilePath)
    Write-Host "Source folder compressed into a zip file."

    # Backup the zip file to S3 bucket
    Write-Host "Backing up the zip file to S3 bucket..."
    try {
        Write-S3Object -BucketName $bucketName -File $zipFilePath -Key $zipFileName -Region $region
        Write-Host "Backup completed."
    }
    catch {
        Write-Host "Error occurred during backup: $_"
    }
    finally {
        # Delete the zip file after backup
        Remove-Item -Path $zipFilePath
        Write-Host "Temporary zip file deleted."
    }
}
elseif ($download) {
    if (-not $file) {
        Write-Host "Please provide a file name to download. Example: .\script.ps1 -download -file file-name.zip"
    }
    else {
        # Download file from S3 bucket
        Write-Host "Downloading file $file from S3 bucket..."
        try {
            Read-S3Object -BucketName $bucketName -Key $file -File $file -Region $region
            Write-Host "Download completed for file: $file."
        }
        catch {
            Write-Host "Error occurred during download: $_"
        }
    }
}
else {
    Write-Host "No option specified. Use -help for usage instructions."
}
