
Param(
    [string] $ResourceGroupLocation = 'West Europe',
    [string] $ResourceGroupName = 'MH-App-Resources',
    [string] $TemplateFile = '..\Templates\main.json',
	[string] $TemplateParametersFile = '..\Templates\main.parameters.json',
	[string] $ServiceBusName = 'MyAwesome-ServiceBus',
	[string] $StorageAccountName = "moimhpersonalstorage",
	[string] $ContainerName = "armtemplates" 
)

Clear
Write-Host " "
Write-Host "Provisioning Infrastructure in $ResourceGroupLocation started at" (Get-Date) -ForegroundColor DarkYellow
Write-Host "___________________________________________________________________________" -ForegroundColor DarkYellow
Write-Host " "
Write-Host " "
Write-Host "Parameters " -ForegroundColor White
Write-Host "------------------------------------------------" -ForegroundColor DarkYellow
Write-Host "Location: " -NoNewline
Write-Host "$ResourceGroupLocation " -ForegroundColor Green
Write-Host "Resource Group: " -NoNewline
Write-Host "$ResourceGroupName " -ForegroundColor Green
Write-Host "Service Bus: " -NoNewline
Write-Host "$ServiceBusName " -ForegroundColor Green
Write-Host " "
Write-Host " "

Invoke-Expression ".\Storage.ps1 -StorageAccountName $StorageAccountName -ContainerName $ContainerName -Directory ..\Templates" 

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


try {
    [Microsoft.Azure.Common.Authentication.AzureSession]::ClientFactory.AddUserAgent("VSAzureTools-$UI$($host.name)".replace(" ","_"), "2.8")
} catch { }

Set-StrictMode -Version 3

$OptionalParameters = New-Object -TypeName Hashtable
$TemplateFile = [System.IO.Path]::Combine($PSScriptRoot, $TemplateFile)



$serviceBusConnectionStrings = @{
									"Prod"=$(Create-AzureServiceBusQueue $ServiceBusName $ResourceGroupLocation);
									"Stage"=$(Create-AzureServiceBusQueue "$($ServiceBusName)-Stage" $ResourceGroupLocation);
								}


Write-Host " "
Write-Host " "								
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Force -ErrorAction Stop -Verbose

New-AzureRmResourceGroupDeployment -Name ((Get-ChildItem $TemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MM-dd-HH-mm')) `
                                   -ResourceGroupName $ResourceGroupName `
                                   -TemplateFile $TemplateFile `
								   -TemplateParameterFile $TemplateParametersFile `
								   -ServiceBusConnectionString $($serviceBusConnectionStrings.Prod) `
								   -ServiceBusConnectionStringStage $($serviceBusConnectionStrings.Stage) `
                                   @OptionalParameters `
                                   -Force -Verbose

Write-Host " "
Write-Host " "
Write-Host "Operation completed at" (Get-Date) -ForegroundColor DarkYellow
Write-Host "___________________________________________________________________________" -ForegroundColor DarkYellow
Write-Host " "




