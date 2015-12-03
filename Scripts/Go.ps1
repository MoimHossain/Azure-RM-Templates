
Param(
    [string] $ResourceGroupLocation = 'West Europe',
    [string] $ResourceGroupName = 'MH-App-Resources',
    [string] $TemplateFile = '..\Templates\main.json',	
	[string] $ServiceBusName = 'MyAwesome-ServiceBus',
	[string] $StorageAccountName = "moimhpersonalstorage",
	[string] $ContainerName = "armtemplates",
	[string] $ParameterContainer = "securecontainer",
	[string] $ParameterResourceName = "main.parameters.json"
)


Import-Module Azure -ErrorAction SilentlyContinue

Function Create-AzureServiceBusQueue($Namespace, $Location) { 
	 Write-Host "Deploying Service Bus [$Namespace] in the [$Location] region..." -ForegroundColor White;
	 $ConnectionString = ""
	 $CurrentNamespace = Get-AzureSBNamespace -Name $Namespace;
	 if ($CurrentNamespace)
	 {
		Write-Host "The namespace [$Namespace] already exists in the [$($CurrentNamespace.Region)] region." -ForegroundColor Cyan;
		$ConnectionString = $CurrentNamespace.ConnectionString.ToString();
	 }
	 else
	 {
		Write-Host "The [$Namespace] does not exist." -ForegroundColor Yellow;
		Write-Host "Creating the [$Namespace] in the [$Location] region..." -ForegroundColor Cyan;
		$CurrentNamespace = New-AzureSBNamespace -Name $Namespace -Location $Location -CreateACSNamespace $false -NamespaceType Messaging;		
		$ConnectionString = $CurrentNamespace.ConnectionString.ToString();
		Write-Host "The [$Namespace] in the [$Location] region has been successfully created." -ForegroundColor Green;
	 }
	 return $ConnectionString;
}

Function New-Line()
{
	Write-Host " "
	Write-Host " "
}


Clear
Write-Host " "
Write-Host "Provisioning Infrastructure in $ResourceGroupLocation started at" (Get-Date) -ForegroundColor DarkYellow
Write-Host "___________________________________________________________________________" -ForegroundColor DarkYellow
New-Line
Write-Host "Parameters " -ForegroundColor White
Write-Host "------------------------------------------------" -ForegroundColor DarkYellow
Write-Host "Location: " -NoNewline
Write-Host "$ResourceGroupLocation " -ForegroundColor Green
Write-Host "Resource Group: " -NoNewline
Write-Host "$ResourceGroupName " -ForegroundColor Green
Write-Host "Service Bus: " -NoNewline
Write-Host "$ServiceBusName " -ForegroundColor Green
New-Line



Invoke-Expression ".\UploadRMTemplates.ps1 -StorageAccountName $StorageAccountName -ContainerName $ContainerName -Directory ..\Templates" 
New-Line
Write-Host "Successfully uploaded template files into the Blob Storage." -ForegroundColor DarkYellow
New-Line


$OptionalParameters = New-Object -TypeName System.Collections.Hashtable
$TemplateFile = [System.IO.Path]::Combine($PSScriptRoot, $TemplateFile)

# Download the parameters
Invoke-Expression ".\DownloadParameters.ps1 -StorageAccountName $StorageAccountName -ContainerName $ParameterContainer -ResourceName $ParameterResourceName -Directory ..\Templates" 
$TemplateParametersFile = '..\Templates\' + $ParameterResourceName
$JsonParameters = (Get-Content $TemplateParametersFile) -join "`n" | ConvertFrom-Json
remove-item -path $TemplateParametersFile -force
foreach($parameterObject in  ($JsonParameters.parameters.PSObject.Members | ?{ $_.MemberType -eq 'NoteProperty'})) 
{  
	if($parameterObject.Name.ToLower().Contains("password".ToLower()) -eq $true)
	{
		$OptionalParameters[$parameterObject.Name] = $secure_string_pwd = convertto-securestring $parameterObject.Value.value -asplaintext -force		
	}
	else 
	{
		$OptionalParameters[$parameterObject.Name] = $parameterObject.Value.value
	}	
}
New-Line
Write-Host "Successfully loaded parameters for the template files." -ForegroundColor DarkYellow
New-Line



try {
    [Microsoft.Azure.Common.Authentication.AzureSession]::ClientFactory.AddUserAgent("VSAzureTools-$UI$($host.name)".replace(" ","_"), "2.8")
} catch { }

Set-StrictMode -Version 3


$serviceBusConnectionStrings = @{
									"Prod"=$(Create-AzureServiceBusQueue $ServiceBusName $ResourceGroupLocation);
									"Stage"=$(Create-AzureServiceBusQueue "$($ServiceBusName)-Stage" $ResourceGroupLocation);
								}


New-Line						
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Force -ErrorAction Stop -Verbose

New-AzureRmResourceGroupDeployment -Name ((Get-ChildItem $TemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MM-dd-HH-mm')) `
                                   -ResourceGroupName $ResourceGroupName `
                                   -TemplateFile $TemplateFile `
								   @OptionalParameters `
								   -ServiceBusConnectionString $($serviceBusConnectionStrings.Prod) `
								   -ServiceBusConnectionStringStage $($serviceBusConnectionStrings.Stage) `
								   -Force -Verbose

New-Line
Write-Host "Operation completed at" (Get-Date) -ForegroundColor DarkYellow
Write-Host "___________________________________________________________________________" -ForegroundColor DarkYellow
New-Line


