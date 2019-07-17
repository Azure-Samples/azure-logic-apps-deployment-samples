<#
 .SYNOPSIS
    Deletes all resources groups that have a name starts with the groupId passed in

 .PARAMETER groupId
    The value used to identify the resource group to delete
#>

param(
    [Parameter(Mandatory = $True)]
    [string]
    $groupId
)

$resourceGroups = Get-AzResourceGroup;

foreach ($resourceGroup in $resourceGroups) {
    if ($resourceGroup.ResourceGroupName.StartsWith($groupId), 'CurrentCultureIgnoreCase') {
        Remove-AzResourceGroup -Name $resourceGroup.ResourceGroupName -Force -AsJob
        Write-Host "Deleted resource group $($resourceGroup.ResourceGroupName)"
    }
}
