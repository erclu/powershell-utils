# TODO find way to move each class to a dedicated file without triggering typenotfound errors
class Login {
  [Uri[]] $uris
  [System.String] $username
  [System.String] $password
  [System.Object] $totp
  [System.Nullable[System.DateTime]] $passwordRevisionDate
}

class Uri {
  [System.UInt16] $matchType
  [System.String] $uri
}

class PasswordHistory {
  [System.DateTime] $lastUsedDate
  [System.String] $password
}

class Item {
  [System.String] $object
  [System.String] $id
  [System.Object] $organizationId
  [System.String] $folderId
  [System.Int64] $type
  [System.String] $name
  [System.String] $notes
  [System.Boolean] $favorite
  [Login] $login
  [System.String[]] $collectionIds
  [System.DateTime] $revisionDate
  [PasswordHistory[]] $passwordHistory
}
