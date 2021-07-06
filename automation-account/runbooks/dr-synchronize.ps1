param(
    [Parameter(Mandatory = $true)]
    [string] $PrimaryResourceGroupName
)

try {


    Write-Host "Primary Rg Name is $PrimaryResourceGroupName"


    Write-Output "DONE"
}
catch {
    throw $_.Exception

}