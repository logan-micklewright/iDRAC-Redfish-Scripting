<#
_author_ = Texas Roemer <Texas_Roemer@Dell.com>
_version_ = 7.0

Copyright (c) 2017, Dell, Inc.

This software is licensed to you under the GNU General Public License,
version 2 (GPLv2). There is NO WARRANTY for this software, express or
implied, including the implied warranties of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. You should have received a copy of GPLv2
along with this software; if not, see
http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt
#>

<#
.Synopsis
   Cmdlet used to get storage inventory using Redfish API.
.DESCRIPTION
   Cmdlet used to get storage inventory using Redfish API. It will return storage information for controllers, disks or backplanes.
   - idrac_ip: Pass in iDRAC IP address
   - idrac_username: Pass in iDRAC username
   - idrac_password: Pass in iDRAC username password
   - get_storage_controllers: Pass in "y" to get current storage controller FQDDs for the server. Pass in "yy" to get detailed information for each storage controller
   - get_virtual_disks: Pass in the controller FQDD to get current virtual disks. Example, pass in "RAID.Integrated.1-1" to get current virtual disks for integrated storage controller
   - get_virtual_disks_details: Pass in the virtual disk FQDD to get detailed information for a specific VD. Example, pass in "Disk.Virtual.0:RAID.Slot.6-1" to get detailed virtual disk information
   - get_all_virtual_disks_details: Pass in the controller FQDD to get detailed information for all VDs detected behind this controller.
   - get_physical_disks: Pass in the controller FQDD to get physical disks. Example, pass in "RAID.Slot.6-1" to get physical disks. 
   - get_physical_disks_details: Pass in the controller FQDD to get detailed information for physical disks.
   - get_server_vds: Pass in "y" to get all VDs detected for the server. 
.EXAMPLE
   Get-StorageInventoryREDFISH -idrac_ip 192.168.0.120 -username root -password calvin -get_storage_controllers y 
   This example will return all storage controller FQDDs detected.
.EXAMPLE
   Get-StorageInventoryREDFISH -idrac_ip 192.168.0.120 -username root -password calvin -get_virtual_disks_details Disk.Virtual.0:RAID.Slot.6-1
   This example will return detailed information for VD Disk.Virtual.0:RAID.Slot.6-1
.EXAMPLE
   Get-StorageInventoryREDFISH -idrac_ip 192.168.0.120 -username root -password calvin -get_server_vds
   This example will return all VDs detected for all controllers in the server.
#>

function Get-StorageInventoryREDFISH {


param(
    [Parameter(Mandatory=$True)]
    [string]$idrac_ip,
    [Parameter(Mandatory=$True)]
    [string]$idrac_username,
    [Parameter(Mandatory=$True)]
    [string]$idrac_password,
    [Parameter(Mandatory=$False)]
    [string]$get_storage_controllers,
    [Parameter(Mandatory=$False)]
    [string]$get_virtual_disks,
    [Parameter(Mandatory=$False)]
    [string]$get_virtual_disk_details,
    [Parameter(Mandatory=$False)]
    [string]$get_all_virtual_disks_details,
    [Parameter(Mandatory=$False)]
    [string]$get_physical_disks,
    [Parameter(Mandatory=$False)]
    [string]$get_physical_disks_details,
    [Parameter(Mandatory=$False)]
    [string]$get_server_vds
    )


function Ignore-SSLCertificates
{
    $Provider = New-Object Microsoft.CSharp.CSharpCodeProvider
    $Compiler = $Provider.CreateCompiler()
    $Params = New-Object System.CodeDom.Compiler.CompilerParameters
    $Params.GenerateExecutable = $false
    $Params.GenerateInMemory = $true
    $Params.IncludeDebugInformation = $false
    $Params.ReferencedAssemblies.Add("System.DLL") > $null
    $TASource=@'
        namespace Local.ToolkitExtensions.Net.CertificatePolicy
        {
            public class TrustAll : System.Net.ICertificatePolicy
            {
                public bool CheckValidationResult(System.Net.ServicePoint sp,System.Security.Cryptography.X509Certificates.X509Certificate cert, System.Net.WebRequest req, int problem)
                {
                    return true;
                }
            }
        }
'@ 
    $TAResults=$Provider.CompileAssemblyFromSource($Params,$TASource)
    $TAAssembly=$TAResults.CompiledAssembly
    ## We create an instance of TrustAll and attach it to the ServicePointManager
    $TrustAll = $TAAssembly.CreateInstance("Local.ToolkitExtensions.Net.CertificatePolicy.TrustAll")
    [System.Net.ServicePointManager]::CertificatePolicy = $TrustAll
}

$global:get_powershell_version = $null

function get_powershell_version 
{
$get_host_info = Get-Host
$major_number = $get_host_info.Version.Major
$global:get_powershell_version = $major_number
}
get_powershell_version


[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12
$user = $idrac_username
$pass= $idrac_password
$secpasswd = ConvertTo-SecureString $pass -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($user, $secpasswd)

$uri = "https://$idrac_ip/redfish/v1/Systems/System.Embedded.1/Storage"
    try
    {
    if ($global:get_powershell_version -gt 5)
    {
    $result = Invoke-WebRequest -SkipCertificateCheck -SkipHeaderValidation -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    else
    {
    Ignore-SSLCertificates
    $result = Invoke-WebRequest -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    }
    catch
    {
    Write-Host
    $RespErr
    return
    }
	    if ($result.StatusCode -ne 200)
	    {
        Write-Host "`n- WARNING, iDRAC version detected does not support this feature using Redfish API"
	    return
	    }
        elseif ($result.StatusCode -eq 401)
        {
        Write-Host "`n- WARNING, invalid iDRAC username or password detected, status code 401 returned."
        return
        }
	    else
	    {
	    }



if ($get_server_vds.ToLower() -eq "y")
{

$uri = "https://$idrac_ip/redfish/v1/Systems/System.Embedded.1/Storage"
try
    {
    if ($global:get_powershell_version -gt 5)
    {
    $result = Invoke-WebRequest -SkipCertificateCheck -SkipHeaderValidation -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    else
    {
    Ignore-SSLCertificates
    $result = Invoke-WebRequest -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    }
    catch
    {
    Write-Host
    $RespErr
    return
    }

if ($result.StatusCode -eq 200)
{
}
else
{
    [String]::Format("`n- FAIL, GET request failed to get storage controllers, statuscode {0} returned",$result.StatusCode)
    return
}

$get_content = $result.Content | ConvertFrom-Json
$odata_id = '@odata.id'
#$get_content.Members.$s
foreach ($item in $get_content.Members.$odata_id)
{
$uri = "https://$idrac_ip$item/Volumes"
try
    {
    if ($global:get_powershell_version -gt 5)
    {
    $result = Invoke-WebRequest -SkipCertificateCheck -SkipHeaderValidation -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    else
    {
    Ignore-SSLCertificates
    $result = Invoke-WebRequest -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    }
    catch
    {
    Write-Host
    $RespErr
    return
    } 
$get_content = $result.Content | ConvertFrom-Json
if ($get_content.Members.count -eq 0)
{
$controller_fqdd = $item.Split("/")[-1]
Write-Host "`n- INFO, no VD(s) detected for controller $controller_fqdd"
}
else
{
$odata_id = '@odata.id'
foreach ($item in $get_content.Members.$odata_id)
{
$uri = "https://$idrac_ip$item"
try
    {
    if ($global:get_powershell_version -gt 5)
    {
    $result = Invoke-WebRequest -SkipCertificateCheck -SkipHeaderValidation -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    else
    {
    Ignore-SSLCertificates
    $result = Invoke-WebRequest -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    }
    catch
    {
    Write-Host
    $RespErr
    return
    } 
$get_content = $result.Content | ConvertFrom-Json
Write-Host
$get_content
}
}

}


}


if ($get_all_virtual_disks_details)
{

$query_parameter = '?$expand=*($levels=1)'
$uri = "https://$idrac_ip/redfish/v1/Systems/System.Embedded.1/Storage/$get_all_virtual_disks_details/Volumes$query_parameter"
try
    {
    if ($global:get_powershell_version -gt 5)
    {
    $result = Invoke-WebRequest -SkipCertificateCheck -SkipHeaderValidation -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    else
    {
    Ignore-SSLCertificates
    $result = Invoke-WebRequest -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    }
    catch
    {
    Write-Host
    $RespErr
    return
    }

if ($result.StatusCode -eq 200)
{
    #[String]::Format("`n- PASS, statuscode {0} returned successfully to get virtual disks for {1} controller`n",$result.StatusCode,$get_virtual_disks)
}
else
{
    [String]::Format("`n- FAIL, GET request failed, statuscode {0} returned",$result.StatusCode)
    return
}

$get_result=$result.Content | ConvertFrom-Json
if ($get_result.Members.count -eq 0)
{
Write-Host "`n- INFO, no VD(s) detected for controller $get_all_virtual_disks_details"
}
else
{
$get_result.Members
}
}


if ($get_virtual_disks)
{
$uri = "https://$idrac_ip/redfish/v1/Systems/System.Embedded.1/Storage/$get_virtual_disks/Volumes"
try
    {
    if ($global:get_powershell_version -gt 5)
    {
    $result = Invoke-WebRequest -SkipCertificateCheck -SkipHeaderValidation -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    else
    {
    Ignore-SSLCertificates
    $result = Invoke-WebRequest -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    }
    catch
    {
    Write-Host
    $RespErr
    return
    }

if ($result.StatusCode -eq 200)
{
    [String]::Format("`n- PASS, statuscode {0} returned successfully to get virtual disks for {1} controller`n",$result.StatusCode,$get_virtual_disks)
}
else
{
    [String]::Format("`n- FAIL, statuscode {0} returned",$result.StatusCode)
    return
}

$get_result=$result.Content
try
{
$regex = [regex] '/Volumes/.+?"'
$allmatches = $regex.Matches($get_result)
$match_volumes=$allmatches.Value.Replace('/Volumes/',"")
$virtual_disks=$match_volumes.Replace('"',"")
[String]::Format("- WARNING, virtual disks detected for controller {0}:`n",$get_virtual_disks)
foreach ($i in $virtual_disks)
{
$uri = "https://$idrac_ip/redfish/v1/Systems/System.Embedded.1/Storage/Volumes/$i"
try
    {
    if ($global:get_powershell_version -gt 5)
    {
    $result = Invoke-WebRequest -SkipCertificateCheck -SkipHeaderValidation -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    else
    {
    Ignore-SSLCertificates
    $result = Invoke-WebRequest -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    }
    catch
    {
    Write-Host
    $RespErr
    return
    }

$get_result = $result.Content | ConvertFrom-Json

if ($get_result.VolumeType -ne "RawDevice")
{
try
{
"{0}, Volume Type: {1}, RAID type: {2}" -f $get_result.Id, $get_result.VolumeType, $get_result.RAIDType
}
catch
{
"{0}, Volume Type: {1}" -f $get_result.Id, $get_result.VolumeType
}

}
}
}
catch
{
Write-Host "- WARNING, no virtual disks detected for controller $get_virtual_disks"
}
Write-Host
return

}


if ($get_virtual_disk_details)
{
$uri = "https://$idrac_ip/redfish/v1/Systems/System.Embedded.1/Storage/Volumes/$get_virtual_disk_details"
try
    {
    if ($global:get_powershell_version -gt 5)
    {
    $result = Invoke-WebRequest -SkipCertificateCheck -SkipHeaderValidation -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    else
    {
    Ignore-SSLCertificates
    $result = Invoke-WebRequest -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    }
    catch
    {
    Write-Host
    $RespErr
    return
    }

if ($result.StatusCode -eq 200)
{
    [String]::Format("`n- PASS, statuscode {0} returned successfully to get virtual disk '{1}' details",$result.StatusCode,$get_virtual_disk_details)
}
else
{
    [String]::Format("`n- FAIL, statuscode {0} returned",$result.StatusCode)
    return
}
$result.Content | ConvertFrom-Json

return

}


if ($get_storage_controllers -eq "yy")
{
$uri = "https://$idrac_ip/redfish/v1/Systems/System.Embedded.1/Storage"
try
    {
    if ($global:get_powershell_version -gt 5)
    {
    $result = Invoke-WebRequest -SkipCertificateCheck -SkipHeaderValidation -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    else
    {
    Ignore-SSLCertificates
    $result = Invoke-WebRequest -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    }
    catch
    {
    Write-Host
    $RespErr
    return
    }
if ($result.StatusCode -eq 200)
{
    [String]::Format("`n- PASS, statuscode {0} returned successfully to get storage controller(s)",$result.StatusCode)
}
else
{
    [String]::Format("`n- FAIL, statuscode {0} returned",$result.StatusCode)
    return
}
$get_content = $result.Content | ConvertFrom-Json
$number_of_controller_entries = $get_content.Members.Count
$count = 0
Write-Host
while ($count -ne $number_of_controller_entries)
{
$uri = "https://$idrac_ip/redfish/v1/Systems/System.Embedded.1/Storage"
try
    {
    if ($global:get_powershell_version -gt 5)
    {
    $result = Invoke-WebRequest -SkipCertificateCheck -SkipHeaderValidation -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    else
    {
    Ignore-SSLCertificates
    $result = Invoke-WebRequest -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    }
    catch
    {
    Write-Host
    $RespErr
    return
    }
if ($result.StatusCode -ne 200)
{
    [String]::Format("`n- FAIL, statuscode {0} returned",$result.StatusCode)
    return
}
$get_content = $result.Content | ConvertFrom-Json
$get_content = $get_content.Members[$count]
$get_content = [string]$get_content
$get_content = $get_content.Replace("@{@odata.id=","")
$get_content = $get_content.Replace('}',"")
$uri = "https://$idrac_ip"+$get_content
try
    {
    if ($global:get_powershell_version -gt 5)
    {
    $result = Invoke-WebRequest -SkipCertificateCheck -SkipHeaderValidation -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    else
    {
    Ignore-SSLCertificates
    $result = Invoke-WebRequest -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    }
    catch
    {
    Write-Host
    $RespErr
    return
    }

$get_content = $result.Content | ConvertFrom-Json
[String]::Format("- Detailed information for controller {0} -`n", $get_content.Id)
$result.Content | ConvertFrom-Json
Write-Host
$count+=1

}
Write-Host
return
}


if ($get_storage_controllers -eq "y")
{
$uri = "https://$idrac_ip/redfish/v1/Systems/System.Embedded.1/Storage"
try
    {
    if ($global:get_powershell_version -gt 5)
    {
    $result = Invoke-WebRequest -SkipCertificateCheck -SkipHeaderValidation -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    else
    {
    Ignore-SSLCertificates
    $result = Invoke-WebRequest -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    }
    catch
    {
    Write-Host
    $RespErr
    return
    }

if ($result.StatusCode -eq 200)
{
    [String]::Format("`n- PASS, statuscode {0} returned successfully to get storage controller(s)",$result.StatusCode)
}
else
{
    [String]::Format("`n- FAIL, statuscode {0} returned",$result.StatusCode)
    return
}

$get_content = $result.Content

Write-Host
$regex = [regex] '/Storage/.+?"'
$allmatches = $regex.Matches($get_content)
$get_all_matches = $allmatches.Value.Replace('/Storage/',"")
$controllers = $get_all_matches.Replace('"',"")
Write-Host "- Server controllers detected -`n"
$controllers
Write-Host
return
}


if ($get_physical_disks)
{
$uri = "https://$idrac_ip/redfish/v1/Systems/System.Embedded.1/Storage/$get_physical_disks"
    try
    {
    if ($global:get_powershell_version -gt 5)
    {
    $result = Invoke-WebRequest -SkipCertificateCheck -SkipHeaderValidation -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    else
    {
    Ignore-SSLCertificates
    $result = Invoke-WebRequest -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    }
    catch
    {
    Write-Host
    $RespErr
    return
    }

$get_content = $result.Content | ConvertFrom-Json
$count = 0
Write-Host "`n- Drives detected for controller '$get_physical_disks' -`n"
$raw_device_count=0
    foreach ($item in $get_content.Drives)
    {
    $get_string = [string]$item
    $get_string = $get_string.Split("/")[-1]
    $drive = $get_string.Replace("}","")
    $uri = "https://$idrac_ip/redfish/v1/Systems/System.Embedded.1/Storage/Drives/$drive"
    try
    {
    if ($global:get_powershell_version -gt 5)
    {
    $result = Invoke-WebRequest -SkipCertificateCheck -SkipHeaderValidation -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    else
    {
    Ignore-SSLCertificates
    $result = Invoke-WebRequest -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    }
    catch
    {
    Write-Host
    $RespErr
    return
    }
    $get_result = $result.Content | ConvertFrom-Json
    $get_result.id
    }
Write-Host
return
}

if ($get_physical_disks_details)
{
$uri = "https://$idrac_ip/redfish/v1/Systems/System.Embedded.1/Storage/$get_physical_disks_details"
try
    {
    if ($global:get_powershell_version -gt 5)
    {
    $result = Invoke-WebRequest -SkipCertificateCheck -SkipHeaderValidation -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    else
    {
    Ignore-SSLCertificates
    $result = Invoke-WebRequest -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    }
    catch
    {
    Write-Host
    $RespErr
    return
    }
$get_result = $result.Content | ConvertFrom-Json
$count = 0

foreach ($item in $get_result.Drives)
{
$get_string = [string]$item
$get_string = $get_string.Split("/")[-1]
$drive = $get_string.Replace("}","")
Write-Host "`n- Detailed drive information for '$drive' -`n"
$uri = "https://$idrac_ip/redfish/v1/Systems/System.Embedded.1/Storage/Drives/$drive"
try
    {
    if ($global:get_powershell_version -gt 5)
    {
    $result = Invoke-WebRequest -SkipCertificateCheck -SkipHeaderValidation -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    else
    {
    Ignore-SSLCertificates
    $result = Invoke-WebRequest -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    }
    catch
    {
    Write-Host
    $RespErr
    return
    }
$get_result = $result.Content | ConvertFrom-Json
$get_result
$count++
}

if ($count -eq 0)
{
Write-Host "- WARNING, no drives detected for controller '$get_physical_disks_details'"
Return
}
Write-Host
Return
}



}


