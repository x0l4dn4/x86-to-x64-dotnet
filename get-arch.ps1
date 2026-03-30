$results = @()

$files = Get-ChildItem -Recurse -File | Where-Object {
    $_.Extension -in '.dll', '.exe', '.ocx'
}
