# Run F5 before usage
# Test avec le ticket 218
# Get-GlpiComputerFromTicket -TicketId 218 | Out-NagiosFile

# Si l'on veut tous les ordinateurs du lieu attribué au ticket:
# Get-GlpiComputerFromTicketLocation -TicketId 218 | Out-NagiosFile

function Show-ComputerLocationStatus {
    Get-GLPIType -Type Location |
        ?{$_.entities_id -eq 1} |
        Select id, completename, name |
        ogv -PassThru |
        select -ExpandProperty id |
        Get-GlpiComputerFromLocation |
        Out-NagiosFile
}

function Get-GlpiComputerFromTicket{
    param($TicketId)

    Get-GLPITicketDevices -Id $TicketId | ?{
        $_.Type -eq 'Computer'} | %{
            GLPIComputer -Id $_.Id}
}

function Get-GlpiComputerFromTicketLocation {
    param($TicketId)

    Get-GLPIType -Type Ticket -Id $TicketId | Select-Object -ExpandProperty locations_id | Get-GlpiComputerFromLocation
}

function Get-GlpiComputerFromLocation {
    param (
        [Parameter(ValueFromPipeline=$true, Mandatory=$true)]
        [int]$LocationId
    )

    $allSites = @($LocationId) + (Get-ChildLocations -ParentId $LocationId | Select-Object -ExpandProperty id)

    $computers = Get-GLPIType -Type Computer | Where-Object { $allSites -contains $_.locations_id }

    return $computers
}

# Utilisez la fonction avec l'ID du site parent
#Get-ChildLocations -ParentId 83
function Get-ChildLocations {
    param (
        [int]$ParentId
    )

    $childLocations = Get-GlPIType -Type Location | Where-Object { $_.locations_id -eq $ParentId }
    
    foreach ($location in $childLocations) {
        $location
        Get-ChildLocations -ParentId $location.id
    }
}

# Utilisez la fonction avec l'ID du site parent
#Get-ChildLocations -ParentId 83

function TextDevice{
    param (
        $Device,
        $Parent = "localhost"
    )

    $name = $Device.name

@"
define host {
    use                     generic-computer
    host_name               $name
    alias                   $name
    parents                 $Parent
}

"@

}

function Out-FileDevice{
    param($TicketId)

    $Devices = Search-GlpiComputerFromTicket -TicketId $TicketId
    $text = ""
    $Devices | %{$text += (TextDevice -Device $_)}
}

function Out-NagiosFile {
    param(
        [Parameter(ValueFromPipeline)]
        $Computers
    )
    Begin{
        $str = ""
    }
    Process{
        #$Computers | %{$str += $_.Name + " "}
        $Computers | %{$str += (TextDevice -Device $_)}
    }
    End{
        $str > devices.cfg
        Restart-DockerSupervision
    }
}

function Stop-DockerSupervision {
    docker stop supervision
}

function Start-DockerSupervision {
#    docker run --name supervision -v $(pwd)/cfg:/opt/nagios/etc/objects -d -p 80:80 -t naglpi -v ./cfg:/opt/nagios/etc/objects
    docker run --name supervision --rm  -d -p 80:80 -t naglpi 
}

function Restart-DockerSupervision {
    if(Test-DockerSupervision){
        Stop-DockerSupervision
    }
    Remove-DockerSupervisionImage
    New-DockerSupervisionImage
    Start-DockerSupervision
}

function Test-DockerSupervision {
    return (docker ps --format "table {{.Names}}" | ?{$_ -eq "supervision"}) -eq 'supervision'
}

function Remove-DockerSupervisionImage {
    $images = docker images --format "table {{.Repository}}"
    $images | % {
        if($_ -eq 'naglpi'){
            docker rmi $_
        }
    }
}

function New-DockerSupervisionImage {
    docker build -t naglpi .
}
