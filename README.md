# Test-AzureRmTraffic

## Description
Test traffic against NSG rules for a given set of traffic parameters.

## Usage
1. Run PowerShell console
2. Run Login-AzureRmAccount
3. Run Select-AzureRmSubscription
4. Run Test-AzureRmTraffic script (ex. Test-AzureRmTraffic.ps1 -VMName VMName -SourceIPv4Address 10.0.0.4 -SourcePort 500 -DestinationIPv4Address 10.0.0.5 -DestinationPort 500 -Protocol TCP -Direction Inbound)

## Parameter
* Required
    * VMName
    * SourceIPv4Address
    * SourcePort
    * DestinationIPv4Address
    * DestinationPort
    * Protocol
    * Direction
    
## Sample
.\Test-AzureRmTraffic.ps1 -VMName shudaVM -SourceIPv4Address 192.168.0.4 -SourcePort 80 -DestinationIPv4Address 10.0.0.5 -DestinationPort 80 -Protocol TCP -Direction Inbound  
***
<span style="color: green; ">Access                      : Allow  
Priority                    : 65000  
Name                        : defaultSecurityRules/AllowVnetInBound  
Protocol                    : All  
SourceAddressPrefix         : VirtualNetwork  
SourcePortRange             : 0-65535  
DestinationAddressPrefix    : VirtualNetwork  
DestinationPortRange        : 0-65535  
Direction                   : Inbound  </span>
***  
<span style="color: red; ">Access                      : Deny  
Priority                    : 65500  
Name                        : defaultSecurityRules/DenyAllInBound  
Protocol                    : All  
SourceAddressPrefix         : 0.0.0.0/0  
SourcePortRange             : 0-65535  
DestinationAddressPrefix    : 0.0.0.0/0  
DestinationPortRange        : 0-65535  
Direction                   : Inbound  </span>
***

## Requirements
This script need Latest version of [Azure PowerShell module](http://aka.ms/webpi-azps). 

How to install and configure Azure PowerShell (Doc: [English](https://azure.microsoft.com/en-us/documentation/articles/powershell-install-configure/) | [Japanese](https://azure.microsoft.com/ja-jp/documentation/articles/powershell-install-configure/))

## Lincense
Copyright (c) 2016-2017 Syuhei Uda
Released under the [MIT license](http://opensource.org/licenses/mit-license.php )

## Release Notes
* 2017/01/14 Ver.0.9.0 (Preview Release) : 1st Release