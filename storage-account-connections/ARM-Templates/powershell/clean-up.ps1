<#
 .SYNOPSIS
    Deletes all resource groups where their names start with the "groupId" that's passed as input.

 .PARAMETER groupId
    The value that identifies the resource group to delete
#>

param(
    [Parameter(Mandatory = $True)]
    [string]
    $groupId
)

$resourceGroups = Get-AzResourceGroup;

foreach ($resourceGroup in $resourceGroups) {
    if ($resourceGroup.ResourceGroupName.StartsWith($groupId, 'CurrentCultureIgnoreCase')) {
        Remove-AzResourceGroup -Name $resourceGroup.ResourceGroupName -Force -AsJob
        Write-Host "Deleted resource group $($resourceGroup.ResourceGroupName)"
    }
}
