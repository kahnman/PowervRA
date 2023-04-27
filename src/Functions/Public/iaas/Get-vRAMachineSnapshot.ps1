function Get-vRAMachineSnapshot {
    <#
        .SYNOPSIS
        Retrieve a vRA Machine's Snapshots
    
        .DESCRIPTION
        Retrieve the snapshots for a vRA Machine
    
        .PARAMETER Id
        The ID of the vRA Machine

        .PARAMETER Name
        The Name of the vRA Machine
    
        .PARAMETER SnapshotId
        The Id of one or more snapshots to retrieve
    
        .OUTPUTS
        System.Management.Automation.PSObject
    
        .EXAMPLE
        Get-vRAMachineSnapshot -Id 'b1dd48e71d74267559bb930934470'
        Returns all snapshots for the machine with Id 'b1dd48e71d74267559bb930934470'
    
        .EXAMPLE
        Get-vRAMachineSnapshot -Name 'iaas01'
        Returns all snapshots for the machine with name 'iaas01'
    
        .EXAMPLE
        Get-vRAMachineSnapshot -Name 'iaas01' -SnapshotId 'b1dd48e71d74267559bb930919aa8','b1dd48e71d74267559bb930915840'
        Returns snapshots with IDs b1dd48e71d74267559bb930919aa8 and b1dd48e71d74267559bb930915840 from the machine with name 'iaas01'
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    [OutputType('System.Management.Automation.PSObject')]
    param (

        [Parameter(Mandatory = $true, ParameterSetName = 'ById', ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$Id,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByName')]
        [ValidateNotNullOrEmpty()]
        [String]$Name,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String[]]$SnapshotId
    )

    begin {

        $APIUrl = '/iaas/api/machines'
    }

    process {

        try {

            # We need need to retrieve the machine ID first using the name provided and then use that machine ID to get the snapshot information
            if ($PsCmdlet.ParameterSetName -eq 'ByName') {

                try {

                    $machineResponse = Invoke-vRARestMethod -URI "$APIUrl`?`$filter=name eq '$Name'`&`$select=id" -Method GET
                    $Id = $machineResponse.content[0].id
                } catch {

                    throw "Failed to get a machine ID for a machine with name `"$Name`": $_"
                }

                if ([string]::IsNullOrEmpty($Id)) {

                    throw "No machine was found with name `"$Name`""
                }
            }

            $uriList = [System.Collections.ArrayList]@()

            if ([string]::IsNullOrEmpty($SnapshotId)) {
                # Since no Snapshot ID was provided, we only have one URI in the array and it is the one that lists all snapshots for the machine
                $null = $uriList.Add("$APIUrl/$MachineId/snapshots")
            } else {

                # Since at least one Snapshot IT was provided, we put the full URI with the snapshot ID into the array
                foreach ($snapId in $SnapshotId) {

                    $null = $uriList.Add("$APIUrl/$MachineId/snapshots/$snapId")
                }
            }

            # Use Invoke-vRARestMethod to run each of the URIs in the array and output the returned data
            foreach ($uri in $uriList) {

                $response = Invoke-vRARestMethod -Uri $uri -Method GET

                # Output the returned data
                foreach ($record in $response) {

                    [PSCustomObject]@{
                        Id             = $record.id
                        Name           = $record.name
                        Description    = $record.description
                        IsCurrent      = $record.isCurrent
                        DateCreated    = $record.createdAt
                        LastUpdated    = $record.updatedAt
                        Owner          = $record.owner
                        OrganizationId = $record.orgId
                    }
                } # End foreach response
            } # End foreach uriList

        } catch [Exception] {

            throw $_
        }
    }

    end {

    }
}