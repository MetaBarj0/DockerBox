$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isElevated = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (!$isElevated)
{
  Write-Output "This script can only be executed with administrator privileges. Aborting."
  Exit 1
}

$hyperVFeatures = $(Get-WindowsOptionalFeature -Online -FeatureName '*Hyper*' | Select-Object -ExpandProperty FeatureName)

foreach ($feature in $hyperVFeatures)
{
  $featureStatus = $(Get-WindowsOptionalFeature -Online -FeatureName $feature | Select-Object -ExpandProperty State)
  if ($featureStatus -eq "Enabled")
  {
    $displayName = $(Get-WindowsOptionalFeature -Online -FeatureName $feature | Select-Object -ExpandProperty DisplayName)

    Write-Output "The feature $displayName is enabled. Disabling it. You may have to restart your computer."

    Disable-WindowsOptionalFeature -Online -FeatureName $feature

    if (!$?)
    {
      Write-Output "Fatal error. Could not disable $displayName optional feature. Aborting."
      Exit 1
    }
  }
}