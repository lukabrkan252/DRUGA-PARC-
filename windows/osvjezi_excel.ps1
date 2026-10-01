# Otvara Excel u pozadini, osvjezava sve Power Query veze (SAP) i zatvara fajl.
param([Parameter(Mandatory=$true)][string]$Path)
$ErrorActionPreference = 'Stop'
$xl = New-Object -ComObject Excel.Application
try {
  $xl.Visible = $false; $xl.DisplayAlerts = $false
  $wb = $xl.Workbooks.Open((Resolve-Path $Path).Path, 0)
  foreach ($c in $wb.Connections) { try { $c.OLEDBConnection.BackgroundQuery = $false } catch {} }
  foreach ($ws in $wb.Worksheets) { foreach ($lo in $ws.ListObjects) { try { $lo.QueryTable.BackgroundQuery = $false } catch {} } }
  $wb.RefreshAll()
  $xl.CalculateUntilAsyncQueriesDone()
  $wb.Save(); $wb.Close($false)
} finally {
  $xl.Quit()
  [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($xl)
}
