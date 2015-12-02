#  (Get-Content .\main.parameters.json) -join "`n" | ConvertFrom-Json
# foreach($p in  ($json.parameters.PSObject.Members | ?{ $_.MemberType -eq 'NoteProperty'})) {  $p.Name + "<----------------->" +  $p.Value.value }


Param(
    [string] $ResourceGroupLocation = 'West Europe',
    [string] $ResourceGroupName = 'MH-App-Resources',
    [string] $TemplateFile = '..\Templates\main.json',	
	[string] $ServiceBusName = 'MyAwesome-ServiceBus',
	[string] $StorageAccountName = "moimhpersonalstorage",
	[string] $ContainerName = "armtemplates",
	[string] $ParameterContainer = "armparameters",
	[string] $ParameterResourceName = "main.parameters.json"
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

Invoke-Expression ".\UploadRMTemplates.ps1 -StorageAccountName $StorageAccountName -ContainerName $ContainerName -Directory ..\Templates" 


$OptionalParameters = New-Object -TypeName System.Collections.Hashtable
$TemplateFile = [System.IO.Path]::Combine($PSScriptRoot, $TemplateFile)

# Download the parameters
Invoke-Expression ".\DownloadParameters.ps1 -StorageAccountName $StorageAccountName -ContainerName $ParameterContainer -ResourceName $ParameterResourceName -Directory ..\Templates" 
$TemplateParametersFile = '..\Templates\' + $ParameterResourceName
$JsonParameters = (Get-Content $TemplateParametersFile) -join "`n" | ConvertFrom-Json
foreach($parameterObject in  ($JsonParameters.parameters.PSObject.Members | ?{ $_.MemberType -eq 'NoteProperty'})) 
{  
	Write-Host $parameterObject.Name + ' ----- > ' + $parameterObject.Value.value
	$OptionalParameters[$parameterObject.Name] = $parameterObject.Value.value
}





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
								   @OptionalParameters `
								   -ServiceBusConnectionString $($serviceBusConnectionStrings.Prod) `
								   -ServiceBusConnectionStringStage $($serviceBusConnectionStrings.Stage) `                                   
                                   -Force -Verbose




Write-Host " "
Write-Host " "
Write-Host "Operation completed at" (Get-Date) -ForegroundColor DarkYellow
Write-Host "___________________________________________________________________________" -ForegroundColor DarkYellow
Write-Host " "


