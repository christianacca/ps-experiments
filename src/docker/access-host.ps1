<#
Access host by IP address
#>

# we can access the host by IP. The IP is the container's default gateway (at least for default container network)
$hostIpAddress = Get-NetRoute | Where DestinationPrefix -eq '0.0.0.0/0' | Select -Exp NextHop

# now we have the IP let's test we can connect to it
# * this works on container hosted in Azure
# * this does NOT work on local laptop (todo: find out why)
$hostIpAddress | % { Test-NetConnection -ComputerName $_ }

<#
Access host by host machine name
#>

# ping
Test-NetConnection -ComputerName w16-dk01 # (azure... doesn't work)
Test-NetConnection -ComputerName W10CCROWHURSTLT # (laptop... works)

# TCP Connect 
# - to port 3389 (RDP)
Test-NetConnection -ComputerName w16-dk01 -Port 3389 # (azure... doesn't work)
Test-NetConnection -ComputerName W10CCROWHURSTLT -Port 3389 # (laptop... doesn't work)
# - to port 80
Test-NetConnection -ComputerName w16-dk01 -Port 80 # (azure... doesn't work - todo: find out why )
Test-NetConnection -ComputerName W10CCROWHURSTLT -Port 80 # (laptop... works)
