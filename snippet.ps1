#download_s3_logs.ps1
#Author - Munishpal Makhija

#    ===========================================================================
#    Created by:    Munishpal Makhija
#    Release Date:  05/31/2023
#    Organization:  VMware
#    Version:       1.0
#    Blog:          https://www.munishpalmakhija.com/
#    Twitter:       @munishpal_singh
#    ===========================================================================

####################### Use Case #########################

######  Download log files from S3 and forward it to vRLI Cloud using PowervRLICloud 

####################### Pre-requisites #########################

######  1 - PowervRLICloud Version 1.1 
######  2 - Connected to vRLI Cloud using Connect-vRLI-Cloud -APIToken $APIToken
######  3 - AWSPowerShell Version 4.1.342 module Installed.


####################### Usage #########################

######  Download the script and save it to a Folder and execute ./download_s3_logs.ps1

$bucket = "BucketName"
$keyPrefix = "FolderPathInTheBucket"
$localPath = "LocalPath"
$region = "us-east-1"

$AWS_ACCESS_KEY_ID="AccessKey"
$AWS_SECRET_ACCESS_KEY="Secret Key"
$AWS_SESSION_TOKEN="#Optional if you are not using temporary credentials#"

$AccessKeyName="AccessKeyName"

####################### Dont Modify anything below this line #########################

######## Downloading from S3 bucket. ########

$objects = Get-S3Object -BucketName $bucket -KeyPrefix $keyPrefix -AccessKey $AWS_ACCESS_KEY_ID -SecretKey $AWS_SECRET_ACCESS_KEY -SessionToken $AWS_SESSION_TOKEN -Region $region

foreach($object in $objects) {
    $localFileName = $object.Key -replace $keyPrefix, ''
    if ($localFileName -ne '') {
        $localFilePath = Join-Path $localPath $localFileName
        Copy-S3Object -BucketName $bucket -Key $object.Key -LocalFile $localFilePath -AccessKey $AWS_ACCESS_KEY_ID -SecretKey $AWS_SECRET_ACCESS_KEY -SessionToken $AWS_SESSION_TOKEN -Region $region
        gunzip $localFilePath
    }
}
######## Reading from the log files and posting to vRLI Cloud. ########

Get-ChildItem -Path $localPath -Filter "*.log" | 
Foreach-Object {
	$filename = ($_.BaseName + '.log')
    $file = Join-Path $localPath $filename
    Write-Host "Reading from: " $file
    $original = Get-Content $file -Raw
    $log = $original | ConvertFrom-Json
    foreach ($l in $log){
    $r = Post-LogsTovRLICloud -AccessKeyName $AccessKeyName -LogMessage $l
    if($r){
    Write-Host "Success"
    }
    }
}
