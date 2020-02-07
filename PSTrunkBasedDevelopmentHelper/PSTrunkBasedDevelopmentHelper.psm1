function Rebase-FeatureBranchesOnTrunk {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
  param ()

  begin {
    $REMOTE = 'origin'
    $TRUNK_NAME = 'master'
    $FEATURES_NAMESPACE = 'feature/'
  }

  process {
    throw "NOT IMPLEMENTED"

    Write-Verbose "ensure $TRUNK_NAME is up to date for $REMOTE"
    git.exe remote update

    # FIXME this lists remote branches!!
    $branches = git.exe for-each-ref --format '%(refname:short)' "refs/heads/$FEATURES_NAMESPACE"

    $branches | ForEach-Object {
      $branch = $_

      Write-Verbose "pushing $branch to $REMOTE"
      git.exe push -u $REMOTE $branch
    }
  }

  end {

  }
}
