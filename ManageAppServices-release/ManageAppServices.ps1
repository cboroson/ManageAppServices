Trace-VstsEnteringInvocation $MyInvocation

$ResourceGroupName= Get-VstsInput -Name "resourceGroupName"
$Action= Get-VstsInput -Name "Action"
$IncludeWebjobs = Get-VstsInput -name "IncludeWebjobs"
$FailTask = Get-VstsInput -name "FailTask"
$ExcludeSites = Get-VstsInput -name "ExcludeSites"

################# Initialize Azure. #################
Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers_
Initialize-Azure

function Get-AppServices ($ResourceGroupName) {

    if ($ExcludeSites) {
        # Get all App Services and Function Apps
        $sites = Get-AzureRmWebApp -ResourceGroupName $ResourceGroupName | where {$_.name -notmatch $ExcludeSites} | sort-object Name
    }
    else{
       # Get all App Services and Function Apps
        $sites = Get-AzureRmWebApp -ResourceGroupName $ResourceGroupName | sort-object Name
    }

    Return $sites
}

function Get-WebJobs ($ResourceGroupName, $Sites) {

    # Check for webjobs
    $AllWebJobs = New-Object System.Collections.ArrayList

    foreach ($siteName in $sites.name) {
    $webjobs = Get-AzureRmResource `
        -ResourceGroup $ResourceGroupName `
        -ResourceType microsoft.web/sites/continuouswebjobs `
        -ResourceName $siteName `
        -ApiVersion 2016-08-01

        if ($webjobs) {
            foreach ($webjob in $webjobs) {

                $tempObj = New-Object System.Object
                $tempObj | Add-Member -MemberType NoteProperty -Name "SiteName" -Value $sitename
                $tempObj | Add-Member -MemberType NoteProperty -Name "WebJobName" -Value $webjob.properties.name
                $tempObj | Add-Member -MemberType NoteProperty -Name "WebJobStatus" -Value $webjob.properties.status

                $AllWebJobs.add($tempObj) | out-null

            }
        }
    }

    Return $AllWebJobs
}

################# Display Services #################

function Display-Status ($sites) {
    write-host "Current state of all Applications in resource group $ResourceGroupName"
    write-host $($sites | select name, state | out-string)

    if ($IncludeWebjobs -eq "true"){
        write-host "Current state of all webjobs in resource group $ResourceGroupName"
        write-host $($AllWebJobs | out-string)
    }
}


################# Get Status #################
$sites = Get-AppServices $ResourceGroupName
if ($IncludeWebjobs -eq "true"){ $AllWebJobs = Get-WebJobs $ResourceGroupName $Sites }


################# Verify Services #################
if ($action -eq "check") { Display-Status $Sites }


################# Stop Services #################
if ($action -eq "stop") {
     write-host "Request to stop services"

    # Stop web apps
    foreach ($site in ($sites | where {$_.state -ne "Stopped"})) {
        
        write-host "Stopping $($site.name)"
        $site | Stop-AzureRmWebApp -ResourceGroupName $ResourceGroupName | out-null

    }

    if ($IncludeWebjobs -eq "true"){

        # Stop webjobs
        foreach ($webjob in ($AllWebJobs | where {$_.WebJobstatus -ne "Stopped"})) {

            write-host "Stopping $($Webjob.WebJobName) on $($webjob.siteName)"

            Invoke-AzureRmResourceAction `
                -ResourceGroup $resourceGroupName `
                -ResourceType microsoft.web/sites/continuouswebjobs `
                -ResourceName "$($webjob.siteName)/$($Webjob.WebJobName)" `
                -Action stop `
                -ApiVersion 2016-08-01 `
                -Force | out-null
        }
    }

    # Validate that all services are stopped
    write-host "Waiting for services to stop..."

    for($i = 0; $i -lt 5; $i++) {
        $sites = Get-AppServices $ResourceGroupName
        $NotStoppedSites = $sites | where {$_.state -ne "Stopped"}
        if ($NotStoppedSites) {
            start-sleep 5
        }
        else {
            $i = 5
        }
    }

    if ($NotStoppedSites -and $FailTask -eq "true") {
        Display-Status $Sites
        write-Error "One or more services did not respond to the control function."
        Trace-VstsLeavingInvocation $MyInvocation
        $host.SetShouldExit(1)
    }

    if ($IncludeWebjobs -eq "true"){ 
        
        for($i = 0; $i -lt 5; $i++) {

            $AllWebJobs = Get-WebJobs $ResourceGroupName $Sites
            $NotStoppedWebJobs = $AllWebJobs | where {$_.WebJobstatus -ne "Stopped"}
            if ($NotStoppedWebJobs) {
                start-sleep 5
            }
            else {
                $i = 5
            }
        }

        if ($NotStoppedWebJobs -and $FailTask -eq "true") {
            Display-Status $Sites
            write-Error "One or more services did not respond to the control function."
            Trace-VstsLeavingInvocation $MyInvocation
            $host.SetShouldExit(1)
        }
    }

    Display-Status $Sites
}


################# Start Services #################
if ($action -eq "start") {
     write-host "Request to start services"

    # Start web apps
    foreach ($site in ($sites | where {$_.state -ne "Running"})) {
        
        write-host "Starting $($site.name)"
        $site | Start-AzureRmWebApp -ResourceGroupName $ResourceGroupName | out-null

    }

    if ($IncludeWebjobs -eq "true"){

        # Start webjobs
        foreach ($webjob in ($AllWebJobs | where {$_.WebJobstatus -ne "Running"})) {

            write-host "Starting $($Webjob.WebJobName) on $($webjob.siteName)"

            Invoke-AzureRmResourceAction `
                -ResourceGroup $resourceGroupName `
                -ResourceType microsoft.web/sites/continuouswebjobs `
                -ResourceName "$($webjob.siteName)/$($Webjob.WebJobName)" `
                -Action start `
                -ApiVersion 2016-08-01 `
                -Force | out-null
        }
    }

    # Validate that all services are started
    write-host "Waiting for services to start..."

    for($i = 0; $i -lt 5; $i++) {
        $sites = Get-AppServices $ResourceGroupName
        $NotStartedSites = $sites | where {$_.state -ne "Running"}
        if ($NotStartedSites) {
            start-sleep 5
        }
        else {
            $i = 5
        }
    }

    if ($NotStartedSites -and $FailTask -eq "true") {
        Display-Status $Sites
        write-Error "One or more services did not respond to the control function."
        Trace-VstsLeavingInvocation $MyInvocation
        $host.SetShouldExit(1)
    }

    if ($IncludeWebjobs -eq "true"){ 
        
        for($i = 0; $i -lt 5; $i++) {

            $AllWebJobs = Get-WebJobs $ResourceGroupName $Sites
            $NotStartedWebJobs = $AllWebJobs | where {$_.WebJobstatus -ne "Running"}
            if ($NotStartedWebJobs) {
                start-sleep 5
            }
            else {
                $i = 5
            }
        }

        if ($NotStartedWebJobs -and $FailTask -eq "true") {
            Display-Status $Sites
            write-Error "One or more services did not respond to the control function."
            Trace-VstsLeavingInvocation $MyInvocation
            $host.SetShouldExit(1)
        }
    }

    Display-Status $Sites
}

Trace-VstsLeavingInvocation $MyInvocation
