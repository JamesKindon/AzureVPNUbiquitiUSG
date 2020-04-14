<#	
	.NOTES
	 Created on:   	21/03/2015 18:28
	 Created by:   	Didier Van Hoye
	 Organization:  WorkingHardInIT
     Blogs: http://blog.workinghardinit.work & http:/workinghardinit.wordpress.com
	 Purpose:     	Azure Scheduled Runbook To Update
					Dynamic IP Address site-to-site VPN
     Update on:     23/08/2019
     Update by: Peter Bursky
     Blog: http://www.bursky.net/index.php/2019/08/azure-automation-rubook-s2s-vpn-dynamic-public-ip/
     
     Update on:     14/04/2020
     Updated by:    James Kindon
     Blog:          https://jkindon.wordpress.com
     Notes:
        - Managed Variable changes
        - Restructured Script and included some documentation links
#>

# ============================================================================
# Variables
# ============================================================================
$connectionName = "AzureRunAsConnection"  #Connect to subscription using a Run As account - https://docs.microsoft.com/en-us/azure/automation/shared-resources/credentials
$DynDNS = "yourname.ddns.net" #change to your Dynamic DNS provider
$ResourceGroupName = "ResourceGroup" #Set the resource group where the local network gateway is stored
$LocalNetworkGateway = "localgatewayname" #Local Network Gateway Name

# ============================================================================
# Execute
# ============================================================================

try {
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName

    write-output "Logging in to Azure..."
    Add-AzureRmAccount -ServicePrincipal -TenantId $servicePrincipalConnection.TenantId -ApplicationId $servicePrincipalConnection.ApplicationId -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection) {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    }
    else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

#Get IP based on the Domain Name
[string]$MyDynamicIP = ([System.Net.DNS]::GetHostAddresses($DynDNS)).IPAddressToString
write-output "Your current dynamic local VPN IP is: $MyDynamicIP"
            
#Read the current local network gateway configuration
$localGateway = Get-AzureRmLocalNetworkGateway -ResourceGroupName $ResourceGroupName -Name $LocalNetworkGateway

#Get the IP addres of the VPN gateway for the specified local network
$MyAzureVPNGatewayIP = $localGateway.GatewayIpAddress
write-output "Current Azure VPN Gateway Address IP for $LocalNetworkGateway is :  $MyAzureVPNGatewayIP"

#Check if you need to update your Azure VPN Gateway IP address
if ($MyDynamicIP -ne $MyAzureVPNGatewayIP) {
    #You have a new dynamic IP address so you'll update the local network VPN gateway in Azure
    Write-Output "Updating your Local Network $LocalNetworkGateway VPN Gateway Address ..."
        
    #Update your loacl network gateway settings
    $localGateway.GatewayIpAddress = $MyDynamicIP
                    
    $ReturnValue = Set-AzureRmLocalNetworkGateway -LocalNetworkGateway $localGateway
    Write-Output "Operation Return Value: $ReturnValue.OperationStatus"

    if ($ReturnValue.ProvisioningState -eq "Succeeded") {
        Write-Output "SUCCESS! Your Local Network $LocalNetworkGateway VPN Gateway Address was updated ."
        Write-Output "$LocalNetworkGateway VPN Gateway Address was updated from $MyAzureVPNGatewayIP to $MyDynamicIP"
    }
    else {
        Write-Output "FAILURE! Your Local Network $LocalNetworkGateway VPN Gateway Address was NOT updated."
    }
        
}
else {
    #You did not get a new dynamic IP yet, nothing to do
    Write-Output "Nothing to do! Your Local Network $LocalNetworkGateway VPN Gateway Address is already up to date."
}
