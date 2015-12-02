

	Param(
		[string] $StorageAccountName,
		[string] $ContainerName,
		[string] $ResourceName,
		[string] $Directory
	)
 
	$storageAccountKey = Get-AzureStorageKey $storageAccountName | %{ $_.Primary }
	Write-Host "Dir:" -ForegroundColor DarkGray -NoNewline
	Write-Host "[$Directory]" -ForegroundColor Cyan
	Write-Host "Storage:" -ForegroundColor DarkGray -NoNewline
	Write-Host "[$StorageAccountName\$ContainerName]" -ForegroundColor Cyan
	$context = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageAccountKey 

	$ContainerExists = $false

	try 
	{
		$ContainerRef = Get-AzureStorageContainer -Name $ContainerName -Context $context -ErrorAction stop
		$ContainerExists = $true
	}
	Catch [Microsoft.WindowsAzure.Commands.Storage.Common.ResourceNotFoundException]
	{
		$ContainerExists = $false
	}

	If ($ContainerExists -eq $false) 
	{
		Write-Host "Creating the Blob Container $ContainerName" -ForegroundColor Green
		New-AzureStorageContainer $ContainerName -Permission Container -Context $context	
	}
	 
	Get-AzureStorageBlobContent -Blob $ResourceName -Container $ContainerName -Destination $Directory -Context $context -Force