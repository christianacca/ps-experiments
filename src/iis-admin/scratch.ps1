Import-Module '.\src\IISSecurity\IISSecurity' -Force

# read (inherited)
Get-CaccaIISSiteDesiredAcl -SitePath 'C:\inetpub\wwwroot'

# this folder and files read (no inherit)
Get-CaccaIISSiteDesiredAcl -SitePath 'C:\inetpub\wwwroot' -SiteShellOnly

# read (inherited), modify (inherited)
Get-CaccaIISSiteDesiredAcl -SitePath 'C:\inetpub\wwwroot' -ModifyPaths 'App_Data'

# this folder and files read (no inherit), modify (inherited)
Get-CaccaIISSiteDesiredAcl -SitePath 'C:\inetpub\wwwroot' -ModifyPaths 'App_Data' -SiteShellOnly

# this folder and files read (no inherit), modify (inherited)
Get-CaccaIISSiteDesiredAcl -SitePath 'C:\inetpub\wwwroot' -ModifyPaths 'C:\inetpub\wwwroot' -SiteShellOnly

# this folder and files read (no inherit), read (inherit)
Get-CaccaIISSiteDesiredAcl -SitePath 'C:\inetpub\wwwroot' -AppPath 'MyWebApp1'

# this folder and files read (no inherit), read (inherit)
Get-CaccaIISSiteDesiredAcl -SitePath 'C:\inetpub\wwwroot' -AppPath 'C:\inetpub\myapp'

# this folder and files read (no inherit), read (inherit)
Get-CaccaIISSiteDesiredAcl -SitePath 'C:\inetpub\wwwroot' -AppPath 'C:\inetpub\wwwroot\MyWebApp1'

# read (inherited)
Get-CaccaIISSiteDesiredAcl -SitePath 'C:\inetpub\wwwroot' -AppPath 'C:\inetpub\wwwroot'

# read (inherited), modify (inherited)
Get-CaccaIISSiteDesiredAcl -SitePath 'C:\inetpub\wwwroot' -AppPath 'C:\inetpub\wwwroot' -ModifyPaths 'App_Data'

# read (inherited)
Get-CaccaIISSiteDesiredAcl -AppPath 'C:\Apps\MyWebApp1'

# read (inherited), modify (inherited)
Get-CaccaIISSiteDesiredAcl -AppPath 'C:\Apps\MyWebApp1' -ModifyPaths 'App_Data'

# read (inherited), read (inherited) 
Get-CaccaIISSiteDesiredAcl -SitePath 'C:\inetpub\wwwroot' -AppPath 'MyWebApp1' -SiteShellOnly:$false