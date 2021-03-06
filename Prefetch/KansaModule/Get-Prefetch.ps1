<#
.SYNOPSIS
	Parses a small amount of data from prefetch files

.NOTES
	Author: David Howell
	Last Modified: 11/24/2015
	Info regarding Prefetch data structures was pulled from the following articles:
	Thanks to Yogesh Khatri for this info.
	http://www.swiftforensics.com/2010/04/the-windows-prefetchfile.html
	http://www.swiftforensics.com/2013/10/windows-prefetch-pf-files.html

OUTPUT csv
#>

$ASCIIEncoding = New-Object System.Text.ASCIIEncoding
$UnicodeEncoding = New-Object System.Text.UnicodeEncoding

$PrefetchArray = @()

Get-ChildItem -Path "$($Env:windir)\Prefetch" -Filter *.pf -Force | Select-Object -ExpandProperty FullName | ForEach-Object {
	# Open a FileStream to read the file, and a BinaryReader so we can read chunks and parse the data
	$FileStream = New-Object System.IO.FileStream -ArgumentList ($_, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
	$BinReader = New-Object System.IO.BinaryReader $FileStream
	
	# First 4 Bytes - Version Indicator
	$Version = [System.BitConverter]::ToString($BinReader.ReadBytes(4)) -replace "-",""
	
	# Next 8 Bytes are "SCCA" Signature, and 4 Bytes for unknown purpose either 0x0F000000 for WinXP or 0x11000000 for Win7/8
	[System.BitConverter]::ToString($BinReader.ReadBytes(8)) -replace "-","" | Out-Null
	
	switch ($Version) {
		# Windows XP Structure
		"11000000" {
			# Create a Custom Object to store prefetch info
			$TempObject = "" | Select-Object -Property Name, Hash, LastExecutionTime
			
			$TempObject | Add-Member -MemberType NoteProperty -Name "PrefetchSize" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
			$TempObject.Name = $UnicodeEncoding.GetString($BinReader.ReadBytes(60))
			$TempObject.Hash = [System.BitConverter]::ToString($BinReader.ReadBytes(4)) -replace "-",""
			$FileStream.Position = 128
			$TempObject.LastExecutionTime = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
		}
		
		# Windows 7 Structure
		"17000000" {
			# Create a Custom Object to store prefetch info
			$TempObject = "" | Select-Object -Property Name, Hash, LastExecutionTime
			
			$TempObject | Add-Member -MemberType NoteProperty -Name "PrefetchSize" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
			$TempObject.Name = $UnicodeEncoding.GetString($BinReader.ReadBytes(60))
			$TempObject.Hash = [System.BitConverter]::ToString($BinReader.ReadBytes(4)) -replace "-",""
			$FileStream.Position = 120
			$TempObject.LastExecutionTime = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
			$BinReader.ReadBytes(16) | Out-Null
			$TempObject | Add-Member -MemberType NoteProperty -Name "NumberOfExecutions" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
		}
		
		# Windows 8 Structure
		"1A000000" {
			# Create a Custom Object to store prefetch info
			$TempObject = "" | Select-Object -Property Name, Hash, LastExecutionTime_1, LastExecutionTime_2, LastExecutionTime_3, LastExecutionTime_4, LastExecutionTime_5, LastExecutionTime_6, LastExecutionTime_7, LastExecutionTime_8
			
			$TempObject | Add-Member -MemberType NoteProperty -Name "PrefetchSize" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
			$TempObject.Name = $UnicodeEncoding.GetString($BinReader.ReadBytes(60))
			$TempObject.Hash = [System.BitConverter]::ToString($BinReader.ReadBytes(4)) -replace "-",""
			$BinReader.ReadBytes(48) | Out-Null
			$TempObject.LastExecutionTime_1 = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
			$TempObject.LastExecutionTime_2 = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
			$TempObject.LastExecutionTime_3 = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
			$TempObject.LastExecutionTime_4 = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
			$TempObject.LastExecutionTime_5 = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
			$TempObject.LastExecutionTime_6 = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
			$TempObject.LastExecutionTime_7 = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
			$TempObject.LastExecutionTime_8 = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
			$BinReader.ReadBytes(16) | Out-Null
			$TempObject | Add-Member -MemberType NoteProperty -Name "NumberOfExecutions" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
		}
		
		# Windows 10 Structure
		"1E000000" {
		
		}
		
		
	}
	$PrefetchArray += $TempObject
}
return $PrefetchArray