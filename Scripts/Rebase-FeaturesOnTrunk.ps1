[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param ()

throw "NOT IMPLEMENTED"

$TRUNK_NAME = 'master'
$FEATURES_NAMESPACE = 'feature/'

git.exe branch -l "$FEATURES_NAMESPACE*"
