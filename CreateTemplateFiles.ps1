#Get the source JSON to test against
$SourceURL = Invoke-RestMethod -Method Get -Uri "https://status.ox.ac.uk/api/services.json"
$DestinationPath = "C:\Temp\PRTG"

#Set the group ID to 0 which is used in json paths
$groupid = 0

#Build the layout that PRTG wants at the start and end
$Pre = '{
    "prtg": {
      "result": 
'

$Post = '    }
}
'

foreach($group in $SourceURL.groups){
    #Just get a dump of how the service group looks
    $group | ConvertTo-Json | Out-File $DestinationPath\_$($group.name).txt

    #Build an array to store the services of the group in
    [System.Collections.ArrayList]$GroupArray = @()
    
    #Set the service ID to 0 which is used in json paths
    $serviceid = 0

    #Add the group to the list of awesome
    $row = New-Object -TypeName PSCustomObject
    $row | Add-Member -MemberType NoteProperty -Name "channel" -Value "$($group.name)"
    $row | Add-Member -MemberType NoteProperty -Name "ValueLookup" -Value "OxfordStatusLookup"
    $row | Add-Member -MemberType NoteProperty -Name "value" -Value "$.groups[$groupid].status_code"
    $GroupArray.Add($row) | Out-Null

    #Get all the services and add them to the array
    foreach($service in $group.services){
        $row = New-Object -TypeName PSCustomObject
        
        #Get the Channel
        $row | Add-Member -MemberType NoteProperty -Name "channel" -Value "$($service.name)"

        #Get the Value Lookup
        $row | Add-Member -MemberType NoteProperty -Name "ValueLookup" -Value "OxfordStatusLookup"

        #Get the value
        $row | Add-Member -MemberType NoteProperty -Name "value" -Value "$.groups[$groupid].services[$serviceid].status_code" 

        $GroupArray.Add($row) | Out-Null
        $serviceid++
    }

    $GroupJSON = $GroupArray | ConvertTo-Json
    $Pre + $GroupJSON + $Post | Out-File $DestinationPath\oxford_$($group.name).temp -Encoding utf8

    #The painful bit to remove double quotes in the JSON Path bits

    $ImportFile = Get-Content $DestinationPath\oxford_$($group.name).temp

    $PrintOutput = foreach($line in $ImportFile){
        if($line -like '        "value":  *'){
            $templine = $line.Split(" ")[10]
            $newtempline = $templine.Replace("`"","")
            "        `"value`":  " + $newtempline
        }
        else{
            $line
        }
    } 

    $PrintOutput | Out-File $DestinationPath\oxford_$($group.name).template -Encoding utf8

    #Incriment the group number
    $groupid++
}