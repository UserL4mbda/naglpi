# Run F5 before usage
# Test avec le ticket 218
# Get-GlpiComputerFromTicket -TicketId 218 | Out-NagiosFile

function Get-GlpiComputerFromTicket{
    param($TicketId)

    Get-GLPITicketDevices -Id $TicketId | ?{
        $_.Type -eq 'Computer'} | %{
            GLPIComputer -Id $_.Id}
}

function TextDevice{
    param ($Device)

    $name = $Device.name

@"
define host {
    use                     generic-computer
    host_name               $name
    alias                   $name
    parents                 localhost
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
    Docker stop supervision
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