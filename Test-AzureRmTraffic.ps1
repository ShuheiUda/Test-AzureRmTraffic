<#
.SYNOPSIS
Test traffic against NSG rules for a given set of traffic parameters.

.DESCRIPTION
This tool queries NSG rules to determine if the given simulated traffic would be allowed or blocked.

.PARAMETER VMName
VM Name which you want to check target 

.PARAMETER SourceIPv4Address
Source IP Address (do not use *)

.PARAMETER SourcePort
Sourt Port (do not use *)

.PARAMETER DestinationIPv4Address
Destination IP Address (do not use *)

.PARAMETER DestinationPort
Destination Port (do not use *)

.PARAMETER Protocol
Protocol (TCP or UDP)

.PARAMETER Direction
Direction (Inbound or Outbound)

.EXAMPLE
./Test-AzureRmTraffic.ps1 -VMName VMName -SourceIPv4Address 10.0.0.4 -SourcePort 500 -DestinationIPv4Address 10.0.0.5 -DestinationPort 500 -Protocol TCP -Direction Inbound

.NOTES
    Name    : Test-AzureRmTraffic.ps1
    GitHub  : https://github.com/ShuheiUda/Test-AzureRmTraffic
    Version : 0.9.0
    Author  : Syuhei Uda
#>
Param(
    [Parameter(Mandatory=$true)][string]$VMName,
    [Parameter(Mandatory=$true)][string]$SourceIPv4Address,
    [ValidateRange(0,65535)][Parameter(Mandatory=$true)][int]$SourcePort,
    [Parameter(Mandatory=$true)][string]$DestinationIPv4Address,
    [ValidateRange(0,65535)][Parameter(Mandatory=$true)][int]$DestinationPort,
    [ValidateSet("TCP", "UDP")][Parameter(Mandatory=$true)][string]$Protocol,
    [ValidateSet("Inbound", "Outbound")][Parameter(Mandatory=$true)][string]$Direction

)

function Validate-StringIPv4Address{
Param(
    [Parameter(Mandatory=$true)]$IPv4Address
)
    [int[]]$SplitIPv4Address = $IPv4Address.Split(".")
    if($SplitIPv4Address.Count -ne 4){
        Return $false
    }else{
        for($octet = 0; $octet -lt 4; $octet++){
            if(($SplitIPv4Address[$octet] -ge 0) -and ($SplitIPv4Address[$octet] -le 256)){
            }else{
                Return $false
            }
        }
    }
}

function ConvertTo-UInt32IPv4Address{
Param(
    [Parameter(Mandatory=$true)]$IPv4Address
)

    [uint32]$UInt32IPv4Address = 0
    [int[]]$SplitIPv4Address = $IPv4Address.Split(".")
    if($SplitIPv4Address.Count -ne 4){
        Return $false
    }else{
        for($octet = 0; $octet -lt 4; $octet++){
            if(($SplitIPv4Address[$octet] -ge 0) -and ($SplitIPv4Address[$octet] -le 256)){
                $UInt32IPv4Address += ($SplitIPv4Address[$octet]*([math]::Pow(256,3-$octet)))
            }else{
                Return $false
            }
        }
    }
    Return $UInt32IPv4Address
}

function ConvertTo-UInt32IPv4StartAddress{
Param(
    [Parameter(Mandatory=$true)]$IPv4AddressRange
)

    [uint32]$UInt32IPv4Address = 0
    $SplitIPv4AddressRange = $IPv4AddressRange.Split("/")
    [int]$SplitIPv4AddressPrefix = $SplitIPv4AddressRange[1]

    if(($SplitIPv4AddressPrefix -ge 0) -and ($SplitIPv4AddressPrefix -le 32)){
        Return (ConvertTo-UInt32IPv4Address $SplitIPv4AddressRange[0])
    }else{
        Write-Error "IPv4 Address Range is not correctly."
        Return -1
    }
}

function ConvertTo-UInt32IPv4EndAddress{
Param(
    [Parameter(Mandatory=$true)]$IPv4AddressRange
)

    [uint32]$UInt32IPv4Address = 0
    $SplitIPv4AddressRange = $IPv4AddressRange.Split("/")
    [int]$SplitIPv4AddressPrefix = $SplitIPv4AddressRange[1]

    if(($SplitIPv4AddressPrefix -ge 0) -and ($SplitIPv4AddressPrefix -le 32)){
        Return ((ConvertTo-UInt32IPv4Address $SplitIPv4AddressRange[0]) + [math]::Pow(2, 32 - $SplitIPv4AddressPrefix) - 1)
    }else{
        Write-Error "IPv4 Address Range is not correctly."
        Return -1
    }
}

function Check-UInt32IPv4AddressRange{
Param(
    [uint32][Parameter(Mandatory=$true)]$UInt32TargetIPv4Address,
    [uint32][Parameter(Mandatory=$true)]$UInt32StartIPv4Address,
    [uint32][Parameter(Mandatory=$true)]$UInt32EndIPv4Address
)
    if(($UInt32TargetIPv4Address -ge $UInt32StartIPv4Address) -and ($UInt32TargetIPv4Address -le $UInt32EndIPv4Address)){
        Return $true
    }else{
        Return $false
    }
}

### Main method

# Header
$Version = "0.9.0"
$LatestVersionUrl = "https://raw.githubusercontent.com/ShuheiUda/Test-AzureRmTraffic/master/LatestVersion.txt"

$LatestVersion = (Invoke-WebRequest $LatestVersionUrl -ErrorAction SilentlyContinue).Content
if($Version -lt $LatestVersion){
    Write-Warning "New version is available. ($LatestVersion)`nhttps://github.com/ShuheiUda/Test-AzureRmTraffic"
}

Write-Debug "$(Get-Date)
============================================================
Input Parameters
============================================================
VMName                 : $VMName
SourceIPv4Address      : $SourceIPv4Address
SourcePort             : $SourcePort
DestinationIPv4Address : $DestinationIPv4Address
DestinationPort        : $DestinationPort
Protocol               : $Protocol
Direction              : $Direction
============================================================"

# Address check
if((Validate-StringIPv4Address $SourceIPv4Address) -eq $false){
    Write-Error "Please input source address correctly. (Example: 192.168.0.0)"
    Return
}
if((Validate-StringIPv4Address $DestinationIPv4Address) -eq $false){
    Write-Error "Please input destination address correctly. (Example: 192.168.0.0)"
    Return
}

# Get NetworkInterface From VM name
$NetworkInterfaceIDs = (Get-AzureRmVM | where{$_.Name -eq $VMName}).NetworkProfile.NetworkInterfaces.Id
if($NetworkInterfaceIDs.Count -gt 1){
    $NetworkInterfaceID = $NetworkInterfaceIDs | Out-GridView -PassThru
}else{
    $NetworkInterfaceID = $NetworkInterfaceIDs
}

$NetworkInterface = Get-AzureRmNetworkInterface | where{$_.Id -eq "$NetworkInterfaceID"}

Write-Debug "$(Get-Date)
============================================================
Target NIC
============================================================
NetworkInterfaceIDs     : $NetworkInterfaceIDs
NetworkInterfaceID      : $NetworkInterfaceID
NetworkInterface        : $NetworkInterface
============================================================"

# Validate effective NSG
$AzureRmEffectiveNetworkSecurityGroup = Get-AzureRmEffectiveNetworkSecurityGroup -NetworkInterfaceName $NetworkInterface.Name -ResourceGroupName $NetworkInterface.ResourceGroupName
$AzureRmEffectiveNetworkSecurityGroup.EffectiveSecurityRules | Where {$_.Direction -eq $Direction} | Sort-Object Priority | foreach{
    $SourceAddressFlag = $false
    $SourcePortFlag = $false
    $DestinationAddressFlag = $false
    $DestinationPortFlag = $false
    $ProtocolFlag = $false
    $RuleMatchFlag = $false

    # Validate source address
    if(($_.SourceAddressPrefix -ne "Internet") -and ($_.SourceAddressPrefix -ne "VirtualNetwork") -and $_.SourceAddressPrefix -ne "AzureLoadBalancer"){
        if(Check-UInt32IPv4AddressRange -UInt32TargetIPv4Address (ConvertTo-UInt32IPv4Address $SourceIPv4Address) -UInt32StartIPv4Address (ConvertTo-UInt32IPv4StartAddress $_.SourceAddressPrefix) -UInt32EndIPv4Address (ConvertTo-UInt32IPv4EndAddress $_.SourceAddressPrefix)){
            $SourceAddressFlag = $true
        }
    }else{
        $_.ExpandedSourceAddressPrefix | foreach{
            if (Check-UInt32IPv4AddressRange -UInt32TargetIPv4Address (ConvertTo-UInt32IPv4Address $SourceIPv4Address) -UInt32StartIPv4Address (ConvertTo-UInt32IPv4StartAddress $_) -UInt32EndIPv4Address (ConvertTo-UInt32IPv4EndAddress $_)){
                $SourceAddressFlag = $true
            }
        }
    }
    
    # Validate source port
    if($_.SourcePortRange -like "*-*"){
        $SplitSourcePortRange = $_.SourcePortRange -split "-"
        $SourceStartPort = $SplitSourcePortRange[0]
        $SourceEndPort = $SplitSourcePortRange[1]
    }else{
        $SourceStartPort = $_.SourcePortRange
        $SourceEndPort = $_.SourcePortRange
    }
    if(($SourcePort -ge $SourceStartPort) -and ($SourcePort -le $SourceEndPort)){
        $SourcePortFlag = $true
    }
    
    # Validate destination address
    if(($_.DestinationAddressPrefix -ne "Internet") -and ($_.DestinationAddressPrefix -ne "VirtualNetwork") -and $_.DestinationAddressPrefix -ne "AzureLoadBalancer"){
        if(Check-UInt32IPv4AddressRange -UInt32TargetIPv4Address (ConvertTo-UInt32IPv4Address $DestinationIPv4Address) -UInt32StartIPv4Address (ConvertTo-UInt32IPv4StartAddress $_.DestinationAddressPrefix) -UInt32EndIPv4Address (ConvertTo-UInt32IPv4EndAddress $_.DestinationAddressPrefix)){
            $DestinationAddressFlag = $true
        }
    }else{
        $_.ExpandedDestinationAddressPrefix | foreach{
            if (Check-UInt32IPv4AddressRange -UInt32TargetIPv4Address (ConvertTo-UInt32IPv4Address $DestinationIPv4Address) -UInt32StartIPv4Address (ConvertTo-UInt32IPv4StartAddress $_) -UInt32EndIPv4Address (ConvertTo-UInt32IPv4EndAddress $_)){
                $DestinationAddressFlag = $true
            }
        }
    }

    # Validate destination port
    if($_.DestinationPortRange -like "*-*"){
        $SplitDestinationPortRange = $_.DestinationPortRange -split "-"
        $DestinationStartPort = $SplitDestinationPortRange[0]
        $DestinationEndPort = $SplitDestinationPortRange[1]
    }else{
        $DestinationStartPort = $_.DestinationPortRange
        $DestinationEndPort = $_.DestinationPortRange
    }
    if(($DestinationPort -ge $DestinationStartPort) -and ($DestinationPort -le $DestinationEndPort)){
        $DestinationPortFlag = $true
    }

    # Validate protocol
    if(($_.Protocol -eq "All") -or ($_.Protocol -eq $Protocol)){
        $ProtocolFlag = $true
    }

    # Result
    if($SourceAddressFlag -and $DestinationAddressFlag -and $SourcePortFlag -and $DestinationPortFlag -and $ProtocolFlag){
        $RuleMatchFlag = $true
    }

    Write-Debug "$(Get-Date)
============================================================
Rule matches? ($RuleMatchFlag)
============================================================
Direction                        : $Direction
Priority                         : $($_.Priority)
Name                             : $($_.name)
SourceAddressPrefix              : $($_.SourceAddressPrefix)
ExpandedSourceAddressPrefix      : $($_.ExpandedSourceAddressPrefix)
SourcePortRange                  : $($_.SourcePortRange)
DestinationAddressPrefix         : $($_.DestinationAddressPrefix)
ExpandedDestinationAddressPrefix : $($_.ExpandedDestinationAddressPrefix)
DestinationPortRange             : $($_.DestinationPortRange)
Protocol                         : $($_.Protocol)
------------------------------------------------------------
SourceIPv4Address                : $SourceIPv4Address
SourcePort                       : $SourcePort
DestinationIPv4Address           : $DestinationIPv4Address
DestinationPort                  : $DestinationPort
Protocol                         : $Protocol
------------------------------------------------------------
SourceAddressFlag                : $SourceAddressFlag
DestinationAddressFlag           : $DestinationAddressFlag
SourcePortFlag                   : $SourcePortFlag
DestinationPortFlag              : $DestinationPortFlag
ProtocolFlag                     : $ProtocolFlag
============================================================"

    if($RuleMatchFlag){
        if($_.Access -eq "Allow"){
            $Color = "Green"
        }else{
            $Color = "Red"
        }
        Write-Host "
Access                      : $($_.Access)
Priority                    : $($_.Priority)
Name                        : $($_.Name)
Protocol                    : $($_.Protocol)
SourceAddressPrefix         : $($_.SourceAddressPrefix)
SourcePortRange             : $($_.SourcePortRange)
DestinationAddressPrefix    : $($_.DestinationAddressPrefix)
DestinationPortRange        : $($_.DestinationPortRange)
Direction                   : $($_.Direction)" -ForegroundColor $Color
        Break
    }
}