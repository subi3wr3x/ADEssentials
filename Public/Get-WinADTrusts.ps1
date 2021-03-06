﻿function Get-WinADTrusts {
    [CmdletBinding()]
    param(
        [string] $Forest,
        [alias('Domain')][string[]] $IncludeDomains,
        [string[]] $ExcludeDomains,
        [switch] $Display
    )

    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains
    <#
    Name                           Value
    ----                           -----
    Forest                         ad.evotec.xyz
    Domains                        {ad.evotec.xyz, ad.evotec.pl}
    ad.evotec.xyz                  {@{Domain=ad.evotec.xyz; HostName=AD1.ad.evotec.xyz; Name=AD1; Forest=ad.evotec.xyz; Site=KATOWICE-1; IPV4Address=192.168.240.189; IPV6Add...
    ad.evotec.pl                   {@{Domain=ad.evotec.pl; HostName=ADPreview2019.ad.evotec.pl; Name=ADPREVIEW2019; Forest=ad.evotec.xyz; Site=KATOWICE-2; IPV4Address=192.16...
    #>
    foreach ($Domain in $ForestInformation.Domains) {
        $Trusts = Get-ADTrust -Server $Domain -Filter * -Properties *
        $DomainPDC = $ForestInformation[$Domain] | Where-Object { $_.IsPDC -eq $true }

        $PropertiesTrustWMI = @(
            'FlatName',
            'SID',
            'TrustAttributes',
            'TrustDirection',
            'TrustedDCName',
            'TrustedDomain',
            'TrustIsOk',
            'TrustStatus',
            'TrustStatusString', # TrustIsOk/TrustStatus are covered by this
            'TrustType'
        )
        $TrustStatatuses = Get-CimInstance -ClassName Microsoft_DomainTrustStatus -Namespace root\MicrosoftActiveDirectory -ComputerName $DomainPDC.HostName -ErrorAction SilentlyContinue -Verbose:$false -Property $PropertiesTrustWMI

        $ReturnData = foreach ($Trust in $Trusts) {
            $TrustWMI = $TrustStatatuses | & { process { if ($_.TrustedDomain -eq $Trust.Target ) { $_ } } }
            if ($Display) {
                [PsCustomObject] @{
                    'Trust Source'               = $Domain
                    'Trust Target'               = $Trust.Target
                    'Trust Direction'            = $Trust.Direction
                    'Trust Attributes'           = if ($Trust.TrustAttributes -is [int]) { Get-ADTrustAttributes -Value $Trust.TrustAttributes } else { 'Error - needs fixing' }
                    'Trust Status'               = if ($null -ne $TrustWMI) { $TrustWMI.TrustStatusString } else { 'N/A' }
                    'Forest Transitive'          = $Trust.ForestTransitive
                    'Selective Authentication'   = $Trust.SelectiveAuthentication
                    'SID Filtering Forest Aware' = $Trust.SIDFilteringForestAware
                    'SID Filtering Quarantined'  = $Trust.SIDFilteringQuarantined
                    'Disallow Transivity'        = $Trust.DisallowTransivity
                    'Intra Forest'               = $Trust.IntraForest
                    'Is Tree Parent'             = $Trust.IsTreeParent
                    'Is Tree Root'               = $Trust.IsTreeRoot
                    'TGTDelegation'              = $Trust.TGTDelegation
                    'TrustedPolicy'              = $Trust.TrustedPolicy
                    'TrustingPolicy'             = $Trust.TrustingPolicy
                    'TrustType'                  = $Trust.TrustType
                    'UplevelOnly'                = $Trust.UplevelOnly
                    'UsesAESKeys'                = $Trust.UsesAESKeys
                    'UsesRC4Encryption'          = $Trust.UsesRC4Encryption
                    'Trust Source DC'            = if ($null -ne $TrustWMI) { $TrustWMI.PSComputerName } else { '' }
                    'Trust Target DC'            = if ($null -ne $TrustWMI) { $TrustWMI.TrustedDCName.Replace('\\', '') } else { '' }
                    'Trust Source DN'            = $Trust.Source
                    'ObjectGUID'                 = $Trust.ObjectGUID
                    'Created'                    = $Trust.Created
                    'Modified'                   = $Trust.Modified
                    'Deleted'                    = $Trust.Deleted
                    'SID'                        = $Trust.securityIdentifier
                    'TrustOK'                    = if ($null -ne $TrustWMI) { $TrustWMI.TrustIsOK } else { $false }
                    'TrustStatus'                = if ($null -ne $TrustWMI) { $TrustWMI.TrustStatus } else { -1 }
                }
            } else {
                [PsCustomObject] @{
                    'TrustSource'               = $Domain
                    'TrustTarget'               = $Trust.Target
                    'TrustDirection'            = $Trust.Direction
                    'TrustAttributes'           = if ($Trust.TrustAttributes -is [int]) { Get-ADTrustAttributes -Value $Trust.TrustAttributes } else { 'Error - needs fixing' }
                    'TrustStatus'               = if ($null -ne $TrustWMI) { $TrustWMI.TrustStatusString } else { 'N/A' }
                    'ForestTransitive'          = $Trust.ForestTransitive
                    'SelectiveAuthentication'   = $Trust.SelectiveAuthentication
                    'SIDFiltering Forest Aware' = $Trust.SIDFilteringForestAware
                    'SIDFiltering Quarantined'  = $Trust.SIDFilteringQuarantined
                    'DisallowTransivity'        = $Trust.DisallowTransivity
                    'IntraForest'               = $Trust.IntraForest
                    'IsTreeParent'              = $Trust.IsTreeParent
                    'IsTreeRoot'                = $Trust.IsTreeRoot
                    'TGTDelegation'             = $Trust.TGTDelegation
                    'TrustedPolicy'             = $Trust.TrustedPolicy
                    'TrustingPolicy'            = $Trust.TrustingPolicy
                    'TrustType'                 = $Trust.TrustType
                    'UplevelOnly'               = $Trust.UplevelOnly
                    'UsesAESKeys'               = $Trust.UsesAESKeys
                    'UsesRC4Encryption'         = $Trust.UsesRC4Encryption
                    'TrustSourceDC'             = if ($null -ne $TrustWMI) { $TrustWMI.PSComputerName } else { '' }
                    'TrustTargetDC'             = if ($null -ne $TrustWMI) { $TrustWMI.TrustedDCName.Replace('\\', '') } else { '' }
                    'TrustSourceDN'             = $Trust.Source
                    'ObjectGUID'                = $Trust.ObjectGUID
                    'Created'                   = $Trust.Created
                    'Modified'                  = $Trust.Modified
                    'Deleted'                   = $Trust.Deleted
                    'SID'                       = $Trust.securityIdentifier
                    'TrustOK'                   = if ($null -ne $TrustWMI) { $TrustWMI.TrustIsOK } else { $false }
                    'TrustStatusInt'            = if ($null -ne $TrustWMI) { $TrustWMI.TrustStatus } else { -1 }
                }
            }
        }
        $ReturnData
    }
}