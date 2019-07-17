<#
    .SYNOPSIS
        Deploys a logic app to Azure, with connections, defition and arm template segregation

    .PARAMETER groupId
        The value used to construct resources within the resource group. Should identify the group of resources that are used together for the given solution

    .PARAMETER location
        Region used for the resource group and the region for resources contained within it

    .PARAMETER environment
        The environment letter provided will be used within every resource created within the resource group. Example values include d = development; t = test; s = staging; p = production

    .PARAMETER identifier
        Value appended to the end of the resource group and the logic app within the resource group

    .PARAMETER abbrevLocationName
        An abbreviated version of the region name. Used within the resource names and should be used to compress the names to account for the character limitations placed on some resource types. Defaults to the location")]

    .PARAMETER deploymentName
        Name given to the deployment. If not provided a GUID is assigned to the deployment

    .PARAMETER connectorsParametersFilePath
        Path to the connectors parameter file. Defaults to the file contained within the local directory
    
    .PARAMETER connectorsTemplateFilePath
        Path to the connectors template file. Defaults to the file contained within the local directory

    .PARAMETER logicAppArmParametersFilePath
        Path to the logic app arm parameters parameter file. Defaults to the file contained within the local directory

    .PARAMETER logicAppTemplateFilePath
        Path to the logic app arm template file. Defaults to the file contained within the local directory

    .PARAMETER logicAppDefinitionParametersFilePath
        Path to the logic app definition parameters file file. Defaults to the file contained within the local directory

    .PARAMETER logicAppDefinitionPath
        Path to the logic app definition file. Defaults to the file contained within the local directory

    .PARAMETER instanceCount
        The number of instances of the resource group to create

    .PARAMETER overrideExisting
        Tells the script to execute the ARM template deployment for the logic app even when the logic app already exists

    .EXAMPLE
        Will deploy the logic apps to the westus region using default values.

        ./logic-app-deploy.ps1 -groupId cse01 -location westus -environment d -identifier sample-sb-conn

    .EXAMPLE
        Will deploy the 6 instances of the logic apps to the westus region.
        ./logic-app-deploy.ps1 -groupId cse02 -location westus -environment d -identifier sample-sb-conn -instanceCount 6

    .EXAMPLE
        Will deploy the 6 instances of the logic apps to the northcentralus region with the shortened region name of ncus.
        ./logic-app-deploy.ps1 -groupId cse03 -location northcentralus -environment d -identifier sample-sb-conn -instanceCount 6 -abbrevLocationName ncus
#>

param(
    [Parameter(Mandatory = $True)]
    [string]
    $groupId,

    [Parameter(Mandatory = $True)]
    [string]
    $location,

    [Parameter(Mandatory = $True)]
    [string]
    $environment,

    [Parameter(Mandatory = $True)]
    [string]
    $identifier,

    [Parameter(Mandatory = $False)]
    [string]
    $abbrevLocationName = $location,

    [Parameter(Mandatory = $False)]
    [string]
    $deploymentName = [guid]::NewGuid(),

    [Parameter(Mandatory = $False)]
    [string]
    $connectorsParametersFilePath = "../templates/connectors-parameters.json",

    [Parameter(Mandatory = $False)]
    [string]
    $connectorsTemplateFilePath = "../templates/connectors-template.json",

    [Parameter(Mandatory = $False)]
    [string]
    $logicAppArmParametersFilePath = "../templates/logic-app-arm-parameters.json",

    [Parameter(Mandatory = $False)]
    [string]
    $logicAppTemplateFilePath = "../templates/logic-app-template.json",

    [Parameter(Mandatory = $False)]
    [string]
    $logicAppDefinitionParametersFilePath = "../templates/logic-app-definition-parameters.json",

    [Parameter(Mandatory = $False)]
    [string]
    $logicAppDefinitionPath = "../templates/logic-app-definition.json",

    [Parameter(Mandatory = $False)]
    [int]
    $instanceCount = 1,

    [Parameter(Mandatory = $False)]
    [bool]
    $overrideExisting = $True
)

Function Set-RelativeFilePaths {
    <#
        .SYNOPSIS
            Fixes relative paths that cannot be evaluated as is
        .DESCRIPTION
            Validates that the file paths can be evaluated as passed in. 
            In the event the paths are relitive and can't be found, 
            will attempt to fix by prepending the scripts execution root path to the path given
    #>
    Param()
    $connectorsParametersFilePath = Set-RelativeFilePath -filePath $connectorsParametersFilePath
    $connectorsTemplateFilePath = Set-RelativeFilePath -filePath $connectorsTemplateFilePath
    $logicAppArmParametersFilePath = Set-RelativeFilePath -filePath $logicAppArmParametersFilePath
    $logicAppDefinitionParametersFilePath = Set-RelativeFilePath -filePath $logicAppDefinitionParametersFilePath
    $logicAppTemplateFilePath = Set-RelativeFilePath -filePath $logicAppTemplateFilePath
    $logicAppDefinitionPath = Set-RelativeFilePath -filePath $logicAppDefinitionPath
}

Function Set-RelativeFilePath {
    <#
        .SYNOPSIS
            Validate an individual file path and prepends script execution root path when the path fails
    #>
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "The path of the file to test to see if it exists.")]
        [string]$filePath
    )

    if (Test-Path $filePath) {
        return $filePath;
    }
    else {
        return "{0}\{1}" -f $PSScriptRoot, $filePath;
    }
}

Function RegisterRP {
    <#
        .SYNOPSIS
            Registers the azure resource provider
    #>
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "The name of the resource provider to register")]
        [string]$ResourceProviderNamespace
    )
    Write-Host "Registering resource provider '$ResourceProviderNamespace'";
    Register-AzResourceProvider -ProviderNamespace $ResourceProviderNamespace;
}

Function Set-LogicAppDeployment {
    <#
        .SYNOPSIS
            Creates/Updates the instance of the logic logic app deployment
    #>
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "The instance number to deploy")]
        [int]$instance
    )

    $resourceGroupName = Get-ResourceGroupName -instance $instance

    Set-ResourceGroup -resourceGroupName $resourceGroupName;

    $armParameters = @{
        groupId      = $groupId
        environment  = $environment
        locationName = $abbrevLocationName
        identifier   = $identifier
        instance     = $instance
    };
    
    Write-Host "Deploying connectors arm template"
    $connectorsOutput = New-ArmTemplateDeployment -parametersFilePath $connectorsParametersFilePath `
        -templateFilePath $connectorsTemplateFilePath `
        -resourceGroupName $resourceGroupName `
        -armParameters $armParameters;

    $logicAppResource = Set-LogicAppResource `
        -resourceGroupName $resourceGroupName `
        -logicAppName $connectorsOutput.Outputs.logicAppName.Value`
        -armParameters $armParameters;
    
    Write-Host "Updating token values with output values"
    $definitionParameters = Set-DynamicParameters -sourceFilePath $logicAppDefinitionParametersFilePath -sourceParameters $connectorsOutput.Outputs;
    $definition = Set-DynamicParameters -sourceFilePath $logicAppDefinitionPath -sourceParameters $connectorsOutput.Outputs;
    
    Set-LogicAppDefinition -definitionParameters $definitionParameters -definition $definition -logicAppResource $logicAppResource
}

Function Get-ResourceGroupName{
    <#
        .SYNOPSIS
            Returns the resource group name based on the instance number passed in
    #>
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "The instance number to deploy")]
        [int]$instance
    )

    # Let's make the resource group names zero based indexes. 
    # Doing so makes it so a single instance deployment doesn't have an extra -1 appended and add confusion
    if($instance -eq 1){
        return "{0}{1}rgp{2}-{3}" -f $groupId, $environment, $location, $identifier
    } else {
        return "{0}{1}rgp{2}-{3}-{4}" -f $groupId, $environment, $location, $identifier, ($instance - 1)
    }
}

Function Set-ResourceGroup {
    <#
        .SYNOPSIS
            Checks if the resource group exists, if not will create the resource group
    #>
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "The name of the resource group to create if it doesn't exist")]
        [string]$resourceGroupName
    )
    
    Write-Host "Working with Resource group name '$resourceGroupName'"

    Write-Host "Checking if resource group exists"
    $resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
    if (!$resourceGroup) {
        Write-Host "Resource group '$resourceGroupName' does not exist. Creating new resource group";
        
        Write-Host "Creating resource group '$resourceGroupName' in location '$location'";
        New-AzResourceGroup -Name $resourceGroupName -Location $location
    }
    else {
        Write-Host "Using existing resource group '$resourceGroupName'";
    }
}

Function New-ArmTemplateDeployment {
    <#
        .SYNOPSIS
            Create a new ARM template deployment 
        .OUTPUTS
            The results of the ARM template deployment
    #>
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "The path to the parameter file to use for the deployment")]
        [string]$parametersFilePath,
        [Parameter(Mandatory = $True, HelpMessage = "The name of the resource group to deploy to")]
        [string]$resourceGroupName,
        [Parameter(Mandatory = $True, HelpMessage = "The path to the template file to use for the deployment")]
        [string]$templateFilePath,
        [Parameter(Mandatory = $True, HelpMessage = "Values to append to the parameters prior to deployment")]
        [hashtable]$armParameters
    )
    if (Test-Path $parametersFilePath) {
        Write-Host "Loading parameters from file";
        $parametersFromFile = Get-Content -Raw -Encoding UTF8 -Path $parametersFilePath | ConvertFrom-Json
        
        Write-Host "Adding script parameters";
        foreach ($key in $armParameters.Keys) {
            New-Parameter -parameters $parametersFromFile -name $key -value $armParameters[$key]   
        }

        Write-Host "Starting deployment...";
        return New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name $deploymentName -TemplateFile $templateFilePath -TemplateParameterObject $parametersFromFile;
    }
    else {
        Write-Host "Starting deployment...";
        return New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name $deploymentName -TemplateFile $templateFilePath -TemplateParameterObject $armParameters;
    }
}

Function New-Parameter {
    <#
        .SYNOPSIS
            Appends a parameter to the hashtable of parameters passed in
    #>
    Param (
        [Parameter(Mandatory = $True, HelpMessage = "Hashtable to add the parameter to")]
        [hashtable]$parameters,
        [Parameter(Mandatory = $True, HelpMessage = "Name of the parameter to add")]
        [string]$name,
        [Parameter(Mandatory = $True, HelpMessage = "Value of the parameter to add")]
        [string]$value
    )
    $parameters | Add-Member -MemberType NoteProperty -Name $name -Value @{value = $value }
}

Function Set-LogicAppResource {
    <#
        .SYNOPSIS
            Creates/Updates the logic app ARM resource
        .DESCRIPTION
            Checks if the logic app resource exists. 
            If it does not or the overrideExisting parameter is true, 
            will create a new ARM template deployment for the logic app.
        .OUTPUTS
            The logic app resource as it exists in Azure at the end of the execution
    #>
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "Name of the resource group to deploy the Logic App resource to")]
        [string]$resourceGroupName,
        [Parameter(Mandatory = $True, HelpMessage = "Name of the logic app resource to create")]
        [string]$logicAppName,
        [Parameter(Mandatory = $True, HelpMessage = "Script parameters to append to the deployment")]
        [hashtable]$armParameters
    )

    # If the overrideExisting is set to true, we always want to create a new deployment, 
    # whether the Logic app exists of not
    if($overrideExisting -eq $True){
        Write-Host "Deploying Logic App ARM Template"
        $outputs = New-ArmTemplateDeployment -parametersFilePath $logicAppArmParametersFilePath `
            -templateFilePath $logicAppTemplateFilePath `
            -resourceGroupName $resourceGroupName `
            -armParameters $armParameters;
    }

    Write-Host "Checking if logic app exists '$logicAppName'"
    $logicAppResource = Get-LogicAppResource `
        -resourceGroupName $resourceGroupName `
        -logicAppName $logicAppName;    

    # If the logic app has never been deployed & the overrideExisting was false
    # We still need to create the resource
    if ($null -eq $logicAppResource) {
        Write-Host "Deploying Logic App ARM Template"
        $outputs = New-ArmTemplateDeployment -parametersFilePath $logicAppArmParametersFilePath `
            -templateFilePath $logicAppTemplateFilePath `
            -resourceGroupName $resourceGroupName `
            -armParameters $armParameters;

        $logicAppResource = Get-LogicAppResource `
            -resourceGroupName $resourceGroupName `
            -logicAppName $logicAppName;  
    }
  
    return $logicAppResource
}

Function Get-LogicAppResource {
    <#
        .SYNOPSIS
            Gets the logic app resource as it exists in Azure
        .OUTPUTS
            The logic app resource as it exists in Azure at the end of the execution
    #>
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "Name of the resource group to look for the logic app in")]
        [string]$resourceGroupName,
        [Parameter(Mandatory = $True, HelpMessage = "Name of the logic app to get")]
        [string]$logicAppName
    )

    return Get-AzResource `
        -ResourceGroupName $resourceGroupName `
        -ResourceName $logicAppName `
        -ResourceType Microsoft.Logic/workflows `
        -ErrorAction SilentlyContinue;    
}

Function Set-DynamicParameters {
    <#
        .SYNOPSIS
            Reads in the json from file path provided, replaces tokens and return the result as an object
        .OUTPUTS
            The result of the updates as an object
    #>
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "Path of the file that will be read from and have the tokens replaced in")]
        [string]$sourceFilePath,
        [Parameter(Mandatory = $True, HelpMessage = "Hashtable of tparameters to iterate through and replace the token with")]
        [hashtable]$sourceParameters
    )
    $result = (Get-Content $sourceFilePath -Encoding UTF8 -Raw) 
    $result = Set-TokenValue -InputObject $result -parameters $sourceParameters;
    $result = ConvertFrom-Json -InputObject $result;

    return $result;
}

Function Set-TokenValue {
    <#
        .SYNOPSIS
            Replaces Token values found in the string passed in with the values of the parameters passed in
        .DESCRIPTION
            Will iterate through each of the parameters passed in and will replace 
            all instances of the "{parameter.key}" with the parameter.value found in the string passed in
        .OUTPUTS
            The result of the updates
    #>
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "Value to search for tokens to replace")]
        [string] $InputObject,
        [Parameter(Mandatory = $True, HelpMessage = "Hashtable of parameters to replace the tokens with")]
        [hashtable] $parameters
    )

    foreach ($key in $parameters.Keys) {
        $InputObject = $InputObject -replace "{$($key)}", $parameters[$key].Value;
    }
    return $InputObject;
}

Function Set-LogicAppDefinition {
    <#
        .SYNOPSIS
            Updates the defition of the logic app in Azure
    #>
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "Parameters to pass into the update")]
        [object]$definitionParameters,
        [Parameter(Mandatory = $True, HelpMessage = "logic app definition to update to")]
        [object]$definition,
        [Parameter(Mandatory = $True, HelpMessage = "logic app to update")]
        [object]$logicAppResource
    )
    Write-Host "Updating Logic App Definition"
    $logicAppResource.Properties.parameters = $definitionParameters;
    $logicAppResource.Properties.definition = $definition;
    $logicAppResource | Set-AzResource -Force;
}

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************

# Fix the PSScriptRoot value for older versions of PowerShell 
if (!$PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

# Fix file paths when working directory differs from the script directory and relative paths are used
Set-RelativeFilePaths

# Register resource providers used by the deployment
$resourceProviders = @("microsoft.logic");
if ($resourceProviders.length) {
    Write-Host "Registering resource providers"
    foreach ($resourceProvider in $resourceProviders) {
        RegisterRP($resourceProvider);
    }
}

# Create the logic apps
For ($i = 1; $i -le $instanceCount; $i++) {
    Set-LogicAppDeployment -instance $i;
}
