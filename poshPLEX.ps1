Enum OperatingSystem
{
   Windows
   Mac
   Linux
   FreeBSD
}
Enum ServerClass 
{
    Computer
    Nas
}

$IDs  ='@{id: 1,
typeString: "movie",
title: "Movie",
element: "video"
id: 2,
typeString: "show",
title: "Show",
element: "directory",
related: [3, 4]
id: 3,
typeString: "season",
title: "Season",
element: "directory",
related: [2, 4]
id: 4,
typeString: "episode",
title: "Episode",
element: "video",
related: [2, 3]
id: 5,
typeString: "trailer",
title: "Trailer",
element: "video"        
id: 6,
typeString: "comic",
title: "Comic",
element: "photo" 
id: 7,
typeString: "person",
title: "Person",
element: "directory"
id: 8,
typeString: "artist",
title: "Artist",
element: "directory",
related: [9, 10]
id: 9,
typeString: "album",
title: "Album",
element: "directory",
related: [8, 10]
id: 10,
typeString: "track",
title: "Track",
element: "audio",
related: [8, 9]
id: 11,
typeString: "photoAlbum",
title: "Photo Album",
element: "directory",
related: [12, 13]
id: 12,
typeString: "picture",
title: "Picture",
element: "photo",
related: [11]
id: 13,
typeString: "photo",
title: "Photo",
element: "photo",
related: [11]
id: 14,
typeString: "clip",
title: "Clip",
element: "video"
id: 15,
typeString: "playlistItem",
title: "Clip",
element: "video"@'
Class Plex_MediaContainer {
[string]$key


}
Class Plex_Movie : Plex_MediaContainer {




}

############NOT USED CURRENTLY
Class PlexUserState {
[array]$reqHeads
[string]$plexUser
[securestring]$plexPass
$adjectives = "an enormous","the world's first","that's a spicy","the least bit","a grotesquely deformed","a gravidly immense","a scantily clad","an eerily familiar"
$nouns = "chud shelter","arboretum","xylophone","laser-rapper","moose","paranormal investigator"
#############
##CONSTRUCTOR
#############
PlexUserState($plexUser,$plexPass){`
$guid = [guid]::NewGuid()
$this.plexUser = $plexUser
$this.plexPass = ConvertTo-SecureString -AsPlainText -String $plexPass
$this.reqHeads = @{}
$this.reqHeads['X-Plex-Platform'] = 'Powershell';
$this.reqHeads['X-Plex-Platform-Version'] = 5.1;
$this.reqHeads['X-Plex-Provides'] = 'controller';
$this.reqHeads['X-Plex-Client-Identifier'] = $guid.Guid;
$this.reqHeads['X-Plex-Product'] = 'thing of stuff';
$this.reqHeads['X-Plex-Version'] = '6.66';
$this.reqHeads['X-Plex-Device'] = 'Batmobile';
$this.reqHeads['X-Plex-Device-Name'] = "$($this.adjectives|get-random) $($this.nouns|getrandom)"
$this.reqHeads['X-Plex-Token'] = $null}
}



Class PlexServer {
######FROM API
[string]$accessToken
[string]$hostname
[ipaddress]$address
[int]$port
$lastresponse
$version
$scheme
$host
$localAddresses
$machineIdentifier
$createdAt
$updatedAt
$owned
$synced
$localIP
##############################
###############################
[System.Net.IPHostEntry]$ipHostEntry
[bool]$isAlive = $false
[bool]$isCloudServer = $false
[bool]$upToDate = $true
[int]$daysSinceUpdate
[datetime]$createdAtTime
[datetime]$updatedAtTime
[string]$urlBase
[hashtable]$pages
[hashtable]$reqheads
[operatingsystem]$platform
[serverclass]$serverclass
[string]$friendlyname
[string]$countryCode
$url_update
###############################
########CONSTRUCTOR
PlexServer ([System.Xml.XmlElement]$theServer,[hashtable]$reqheads){
Write-Verbose 'constructing new PlexServer'
###basics from api
$this.accessToken = $theServer.accessToken
$this.port = $theServer.port
$this.version = $theServer.version
$this.scheme = $theServer.scheme
$this.host = $theServer.host
$this.localAddresses = $theServer.localAddresses
$this.machineIdentifier = $theServer.machineIdentifier
$this.createdAt = $theServer.createdAt
$this.updatedAt = $theServer.updatedAt
$this.accessToken = $theServer.accessToken
$this.owned = $theServer.owned
$this.synced = $theServer.synced
$this.reqheads = $reqheads
Write-Verbose 'constructing new PlexServer'
Write-Verbose "accesstoken =  $($this.accessToken), port = $($this.port)"
##isCloudServer
if(!$this.localAddresses){$this.isCloudServer = $true}else{$this.isCloudServer = $false}
####################################
if(!($this.isCloudServer)){$this.localIP = ($this.localAddresses | Select-Object -First 1)}
if(!($this.isCloudServer)){$this.setRootInfo()}
if(!($this.isCloudServer)){$this.hostname = ([system.net.dns]::GetHostByAddress($this.localIP)).hostname }
Write-Verbose "IP ADDRESS: $($this.localIP)"
Write-Verbose '$this is'
Write-Verbose $this
###defining some useful pages
Write-Verbose 'defining some useful pages'
$this.pages = @{}
$this.pages.Add('status-sess','/status/sessions')
$this.pages.Add('status-sess-hist','/status/sessions/history/all')
$this.pages.Add('search','/search?query=') #?query=stringtoquery
$this.pages.Add('lib-sects','/library/sections')
$this.pages.Add('myplexaccount','/myplex/account')
$this.pages.Add('system','/system')
$this.pages.Add('servers','/servers')
$this.pages.Add('prefs','/:/prefs')
$this.pages.Add('identity','/identity')
$this.pages.Add('lib-ondeck','/library/onDeck')
Write-Verbose $this.pages
#$this.pages['system'] = '/system'
####################################
###UNFUCK DATES
$this.createdAtTime = $this.unixToDateTime($this.createdAt)
$this.updatedAtTime = $this.unixToDateTime($this.updatedAt)
$this.daysSinceUpdate = ((get-date) - $this.updatedAtTime).totalHours
}
########CONSTRUCTOR-END###############
#######################################
#######################################

###############METHODS
######REQUEST URL - NEED TO CONSOLIDATE
[object] requestPage([string]$path){
$URI = "$($this.scheme):`/`/$($this.localIP):$($this.port)" + $path
$this.lastResponse = Invoke-RestMethod -Uri $uri -Method Get
if(!$this.lastResponse.MediaContainer){$freshpage = $this.lastResponse}
else{$freshpage = ($this.lastResponse).MediaContainer}
return $freshpage;}
###root server info ( '/')
[System.Xml.XmlElement] setRootInfo(){
$rootInfo = $this.requestPage('/')
$this.platform = $rootInfo.platform
$this.serverclass = [serverclass]::Computer
$this.countryCode = $rootInfo.countrycode
$this.friendlyname = $rootInfo.friendlyname
return $rootInfo
} 
###UNFUCK DATES
[datetime] unixToDateTime ([int]$unixtime){
$yearzero = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0;
$poshtime = $yearzero.AddSeconds($unixtime)
return $poshtime
}
#[object] requestPage([string]$path){
#$URI = "$($this.defaultServer.scheme):`/`/$($this.defaultServer.localIP):$($this.defaultServer.port)" + $path
#$this.lastResponse = Invoke-RestMethod -Uri $uri -Method Get
##if(!$this.lastResponse.MediaContainer){$freshpage = $this.lastResponse}
#else{$freshpage = ($this.lastResponse).MediaContainer}
#return $freshpage;}
#updateLibrary([string]$key){$this.requestPage("/library/sections/$key/refresh")}
isAliveTest() {
$response = $null
#######
$this.urlBase = "$($this.scheme):`/`/$($this.localAddresses | Select-Object -First 1):$($this.port)" + '/'
try{
$response = Invoke-WebRequest -Uri $this.urlBase -Method Get -Headers $this.reqHeads
Write-Verbose $response
if($response.length -gt 0){$this.isAlive = $true}
}
catch{Write-Verbose 'eerrooorrrs ... boo';$this.isAlive = $false}
}
}





Class poshPLEX {
[string]$authToken
[string]$url_GetToken = 'https://plex.tv/users/sign_in.json'
$lastResponse
[PlexServer[]]$knownPlexServers
[PlexServer]$defaultServer
[hashtable]$reqHeads
[string]$credsencoded
[hashtable]$index_root
[hashtable]$index_library
[hashtable]$library
[bool]$hasPlexPass
$adjectives = "an enormous","the world's first","that's a spicy","the least bit","a grotesquely deformed","a pale but gravidly immense","C'orr blimey! It's "
$nouns = "chud shelter","arboretum","xylophone","laser-rapper","moose","lobster","suppressive person","nightmare zone,gross." 
$LatestVer_Windows
$LatestVer_Mac
$LatestVer_linux
$LatestVer_FreeBSD
[bool]$autoUpdate = $false
###############
####Constructor
###############
poshPLEX ([string]$username,[string]$password) {
Write-Verbose 'constructing new PlexSnitch'
$this.index_root = @{}
$this.index_library = @{}
$this.library = @{}
$guid = [guid]::NewGuid()
Write-Verbose 'Making request headers'
$this.reqHeads = @{};
$this.reqHeads['X-Plex-Platform'] = 'Powershell';
$this.reqHeads['X-Plex-Platform-Version'] = 5.1;
$this.reqHeads['X-Plex-Provides'] = 'controller';
$this.reqHeads['X-Plex-Client-Identifier'] = $guid.guid;
$this.reqHeads['X-Plex-Product'] = 'thing of stuff'
$this.reqHeads['X-Plex-Version'] = 6.66;
$this.reqHeads['X-Plex-Device'] = 'Batmobile';
Write-Verbose 'making silly name, hahaha'
$this.reqHeads['X-Plex-Device-Name'] = "$($this.adjectives|get-random) $($this.nouns|get-random)";
$this.reqHeads['X-Plex-Container-Size'] = 1;
$this.reqHeads['X-Plex-Container-Start'] = 0;
$this.reqHeads['Accept'] = 'application/json' 
##get a token if null
if(!($this.authToken)){`
Write-Verbose 'no token, making now'
$this.requestToken($username,$password)}
#$this.reqHeaders.Add('X-Plex-Token',$($this.authToken))
###timetofuckshitup
$global:reqheaders = $this.reqHeads
Write-Verbose 'looking at servers'
$this.GetPlexServers();
Write-Verbose 'picking a winner'
$this.pickDefServer();
Write-Verbose 'get update status'
$this.isPlexUpToDate()
Write-Verbose 'getting  library index'
$this.getLibraryIndex()
}
poshPLEX ([string]$username,[string]$password,[bool]$autoUpdate) {
Write-Verbose 'constructing new PlexSnitch'
$this.index_root = @{}
$this.index_library = @{}
$this.library = @{}
#$this.username = $username
#$this.password = $password
$guid = [guid]::NewGuid()
#$this.username = $username
#$this.password = ConvertTo-SecureString -AsPlainText -String $password -Force
Write-Verbose 'Making request headers'
$this.reqHeads = @{};
$this.reqHeads['X-Plex-Platform'] = 'Powershell';
$this.reqHeads['X-Plex-Platform-Version'] = 5.1;
$this.reqHeads['X-Plex-Provides'] = 'controller';
$this.reqHeads['X-Plex-Client-Identifier'] = $guid.guid;
$this.reqHeads['X-Plex-Product'] = 'thing of stuff'
$this.reqHeads['X-Plex-Version'] = 6.66;
$this.reqHeads['X-Plex-Device'] = 'Batmobile';
Write-Verbose 'making silly name, hahaha'
$this.reqHeads['X-Plex-Device-Name'] = "$($this.adjectives|get-random) $($this.nouns|get-random)";
$this.reqHeads['X-Plex-Container-Size'] = 1;
$this.reqHeads['X-Plex-Container-Start'] = 0;
$this.reqHeads['Accept'] = 'application/json' 
##get a token if null
if(!($this.authToken)){`
Write-Verbose 'no token, making now'
$this.requestToken($username,$password)}
#$this.reqHeaders.Add('X-Plex-Token',$($this.authToken))
###timetofuckshitup
$global:reqheaders = $this.reqHeads
Write-Verbose 'looking at servers'
$this.GetPlexServers();
Write-Verbose 'picking a winner'
$this.pickDefServer();
Write-Verbose 'get update status'
$this.isPlexUpToDate()
Write-Verbose 'getting  library index'
$this.getLibraryIndex()
if($autoUpdate -eq $true -and $this.defaultServer.upToDate -eq $false){$this.BeginUpdate()}
}

#####METHODS
[object] requestToken($username,$password){
$this.credsEncoded = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("$($username):$($password)"))
if(!($this.reqHeads['Authorization'])){$this.reqHeads.Add('Authorization',"Basic $($this.credsEncoded)")}
$this.reqHeads.GetEnumerator()
$response = Invoke-RestMethod -Headers $this.reqHeads -Uri $this.url_GetToken -Method Post
$this.authToken = $response.user.authtoken
##Add token to headers
$this.reqHeads['X-Plex-Token'] = $this.authToken
##While we're here - set hasPlexPass
$this.hasPlexPass = $response.user.subscription.active
return $response
}
[object] getPlexServers(){
$servers = Invoke-RestMethod -Uri 'https://plex.tv/pms/servers.xml' -Headers $this.reqHeads -Method Get
$global:servers = $servers
if(($servers.MediaContainer.Server).count -gt 0)
    {($servers.MediaContainer.Server).foreach({$this.knownPlexServers += ([PlexServer]::new($_,$this.reqHeads))})}
else
    {$this.knownPlexServers += ([PlexServer]::new($_,$this.reqHeads))}
return $servers
}
pickDefServer(){
$mostrecent = $null;
$this.defaultServer = (($this.knownPlexServers).Where({$_.isCloudServer -eq $false})) | Sort-Object -Descending -Property daysSinceUpdate | Select-Object -last 1
$this.defaultServer.isAliveTest()
}
[object] requestPage([string]$path){
$URI = "$($this.defaultServer.scheme):`/`/$($this.defaultServer.localIP):$($this.defaultServer.port)" + $path
$this.lastResponse = Invoke-RestMethod -Uri $uri -Method Get
if(!$this.lastResponse.MediaContainer){$freshpage = $this.lastResponse}
else{$freshpage = ($this.lastResponse).MediaContainer}
return $freshpage;}
[object] requestPlexTVpage([string]$path){
$URI = "https://plex.tv" + $path
$this.lastResponse = Invoke-RestMethod -Uri $uri -Method Get
$freshpage = ($this.lastResponse)
return $freshpage;}
[object] requestPlexTVdownloads(){
if($this.hasplexpass -eq $true){$URI = "https://plex.tv/api/downloads/1.json?channel=plexpass"}
else{$URI = "https://plex.tv/api/downloads/1.json"}
$this.lastResponse = Invoke-RestMethod -Uri $uri -Method Get -Headers $this.reqHeads
$freshpage = ($this.lastResponse)
return $freshpage;}
[object] requestPlexTVdownloads([bool]$plexpass){
if($plexpass -eq $true){$URI = "https://plex.tv/api/downloads/1.json?channel=plexpass"}
else{$URI = "https://plex.tv/api/downloads/1.json"}
$this.lastResponse = Invoke-RestMethod -Uri $uri -Method Get -Headers $this.reqHeads
$freshpage = ($this.lastResponse)
return $freshpage;}
#############
[object] requestPageRaw([string]$path){
$URI = "$($this.defaultServer.scheme):`/`/$($this.defaultServer.localIP):$($this.defaultServer.port)" + $path
$this.lastResponse = Invoke-RestMethod -Verbose -Uri $uri -Method Get
$freshpage = $this.lastResponse
return $freshpage;
}
getLibraryIndex(){
$libraryinfo = $this.requestPage('/library/sections')
$libraryinfo.childnodes.Where({$_.agent}).foreach({$this.index_root.Add($_.title,$_)})
$this.index_root.GetEnumerator().ForEach({`
$libraryType = $_.value.type;
$libraryName = $_.value.title;
$libraryKey = $_.value.key;
$this.index_library["$($_.name)"] = $libraryKey;
switch ($libraryType)
{
    'show' {$this.library.Add($libraryName,[Plex_SectionTV]::new($this.requestPage("/library/sections/$libraryKey/all")))}
    'movie' {$this.library.Add($libraryName,[Plex_SectionMovies]::new($this.requestPage("/library/sections/$libraryKey/all")))}
    'artist' {$this.library.Add($libraryName,[Plex_SectionMusic]::new($this.requestPage("/library/sections/$libraryKey/all")))}
     Default {Write-Verbose "COULDNT MATCH TYPE : $librarytype"}
}
})

}
[int] returnSectionKey([string]$name){
try{[int]$key = $this.index_library.GetEnumerator().where({$_.name -like $name}).value}
catch{write-verbose 'No match for that name';$key = 0}
return $key
}
getSectionAll([string]$sectionName){
$key = $this.returnSectionKey($sectionName)
$this.requestPage("/library/sections/$key/all").directory
}
getItemDetails([string]$key){
$details = $this.requestPage($key)
}
setLatestVersions()
{
$allVersionInfo = ($this.requestPlexTVdownloads()).computer
$this.LatestVer_FreeBSD = $allVersionInfo.FreeBSD
$this.LatestVer_Mac = $allVersionInfo.Mac
$this.LatestVer_Linux = $allVersionInfo.Linux
$this.LatestVer_Windows = $allVersionInfo.Windows
}
####Update check - default server
[object] isPlexUpToDate(){
$regexVersion = "(?<first>\d+).(?<second>\d+).(?<third>\d+).(?<fourth>\d+)-.+"
[pscustomobject]$thisInstalled = $null
[pscustomobject]$thisLatest = $null
#get latest info from plex.tv
$this.setLatestVersions()
if($this.defaultServer.version -match $regexVersion){`
    $thisInstalled = [pscustomobject] @{first = $matches.first;`
    second = $matches.second;third = $matches.third;fourth = $matches.fourth}}
else{write-verbose 'error matching installed'}
    $thisLatest = [pscustomobject] 
switch ([operatingsystem]$this.defaultServer.platform)
{
    'Windows' {
        if($this.LatestVer_Windows.version -match $regexVersion){
            $thisLatest = [pscustomobject] @{first = $matches.first;`
            second = $matches.second;third = $matches.third;fourth = $matches.fourth;`
            url = ($this.LatestVer_Windows.releases.url);checksum = ($this.LatestVer_Windows.releases.checksum)}
            }
    }
    'Mac' {
    ####CODE ME    
    }
    'Linux' {
    if($this.LatestVer_Linux.version -match $regexVersion){
            $thisLatest = [pscustomobject] @{first = $matches.first;`
            second = $matches.second;third = $matches.third;fourth = $matches.fourth;`
            url = ($this.LatestVer_Linux.releases.url);checksum = ($this.LatestVer_Linux.releases.checksum)}  
    }
    }
    'FreeBSD' {
    ####CODE ME    
    }
    Default {Write-Verbose 'ERROR - no logic for this platform'}
}
####TESTONLY
#$GLOBAL:installed = $thisInstalled
#$GLOBAL:latest = $thisLatest
if($thisInstalled.first -lt $thisLatest.first){
###installed.first is newer
Write-Verbose "installed.first is newer: $($thisInstalled.first) vs $($thisLatest.first)"
$returnOBJ = ($false,'first',$thisLatest)
$this.defaultServer.upToDate = $returnOBJ[0]
$this.defaultServer.url_update = $returnOBJ[2]
return $returnOBJ
}
else{Write-Verbose "latest.first is GE: $($thisInstalled.first) vs $($thisLatest.first)"}
if($thisInstalled.second -lt $thisLatest.second){
###installed.second is newer
Write-Verbose "installed.second is newer: $($thisInstalled.second) vs $($thisLatest.second)"
$returnOBJ = ($false,'second',$thisLatest) 
$this.defaultServer.upToDate = $returnOBJ[0]
$this.defaultServer.url_update = $returnOBJ[2]
return $returnOBJ
}
else{Write-Verbose "latest.second is GE: $($thisInstalled.second) vs $($thisLatest.second)"}
if($thisInstalled.third -lt $thisLatest.third){
###installed.third is newer
Write-Verbose "installed.third is newer: $($thisInstalled.third) vs $($thisLatest.third)"
$returnOBJ = ($false,'third',$thisLatest)
$this.defaultServer.upToDate = $returnOBJ[0]
$this.defaultServer.url_update = $returnOBJ[2]
return $returnOBJ
}
else{Write-Verbose "latest.third is GE: $($thisInstalled.third) vs $($thisLatest.third)"}
if($thisInstalled.fourth -lt $thisLatest.fourth){
###installed.fourth is newer
Write-Verbose "installed.fourth is newer: $($thisInstalled.fourth) vs $($thisLatest.fourth)"
$returnOBJ = ($false,'fourth',$thisLatest)
$this.defaultServer.upToDate = $returnOBJ[0]
$this.defaultServer.url_update = $returnOBJ[2]
return $returnOBJ
}
else{Write-Verbose "latest.fourth is GE: $($thisInstalled.fourth) vs $($thisLatest.fourth)"}
$returnOBJ = ($true,'all',$thisinstalled)
$this.defaultServer.upToDate = $returnOBJ[0]
$this.defaultServer.url_update = $null
return $returnOBJ
}
[void]BeginUpdate () {
if((Get-NetIPAddress).ipaddress -contains $this.defaultServer.localIP){$serverIsLocal = $true}
else{$serverIsLocal = $false;$this.updateWindowsRemote()}
}
updateWindowsLocal () {
$plexservice = $null
$ComputerName = (([system.net.dns]::GetHostByAddress($this.defaultServer.localIP)).hostname)
$plexSession = New-PSSession -ComputerName $ComputerName
$plextemp = 'C:\PlexTemp'
$filename = $this.LatestVer_Windows.releases[0].url.split('/').where({$_},'Last',1)
$updateDownloadPath = "$plextemp\$filename"
$checksum = $this.LatestVer_Windows.releases[0].checksum.toUpper()
$plexservice = Get-Service -Name 'PlexService' -ComputerName $ComputerName
if(($plexservice = Get-Service -Name 'PlexService' -ComputerName $ComputerName) -ne $null){
############RUNNING AS SERVICE
####CREATE FOLDER IF MISSING, DOWNLOAD LATEST INSTALLER
Invoke-Command -Session $plexSession -ScriptBlock {param($URL)if(![System.IO.Directory]::Exists('C:\PlexTemp')){New-Item -ItemType Directory -Path 'C:\PlexTemp' };Invoke-WebRequest -Uri $URL -OutFile "C:\PlexTemp\$($URL.split('/') | Select-Object -Last 1)" } -ArgumentList $this.LatestVer_Windows.releases.url
###CHECK FILE HASH
if(invoke-command -session $plexSession -scriptblock {param($CHECKSUM,$FILE) $hash = (Get-FileHash -Path $FILE -Algorithm SHA1).hash;$CHECKSUM -match $hash } -ArgumentList $checksum,$updateDownloadPath){
           ###HASH OKAY - STOP SERVICE,INSTALL,START
      $waitTime = 8
      while (($plexservice = Get-Service -Name 'PlexService' -ComputerName $ComputerName).where({$_.status -ne 'Stopped'}).count -gt 0)
      {
        $plexservice.Stop();
        Start-Sleep -Seconds $waitTime
        if(get-process -ComputerName $computername -Name 'Plex Media Server'){invoke-command -session $plexSession -scriptblock {Get-Process -Name 'Plex Media Server' | Stop-Process -Force}  }
      }
      ####SERVICE DOWN, INSTALL
      $installer = invoke-command -session $plexSession -scriptblock {param($path) Start-Process -FilePath $path -ArgumentList '/quiet' -Wait } -ArgumentList $updateDownloadPath
      $plexservice.start();
      Start-Sleep -Seconds 7
        }
else{Write-Verbose 'checksum didnt match expected,deleting,try again';invoke-command -session $plexSession -scriptblock {param($path) Remove-Item -Path $path -Force -Confirm:$false} -ArgumentList $updateDownloadPath}



}
}
##########UPDATE METHOD INCOMPLETE, ASSUMES RUNNING AS SERVICE
updateWindowsRemote () {
$plexservice = $null
$ComputerName = (([system.net.dns]::GetHostByAddress($this.defaultServer.localIP)).hostname)
$plexSession = New-PSSession -ComputerName $ComputerName
$plextemp = 'C:\PlexTemp'
$filename = $this.LatestVer_Windows.releases[0].url.split('/').where({$_},'Last',1)
Write-Verbose "filename $($filename)"
Write-Verbose "URL $($this.LatestVer_Windows.releases.url)"
$updateDownloadPath = "$plextemp\$filename"
Write-Verbose $updateDownloadPath
$checksum = $this.LatestVer_Windows.releases[0].checksum.toUpper()
$plexservice = Get-Service -Name 'PlexService' -ComputerName $ComputerName
if(($plexservice = Get-Service -Name 'PlexService' -ComputerName $ComputerName) -ne $null){
############RUNNING AS SERVICE
####CREATE FOLDER IF MISSING, DOWNLOAD LATEST INSTALLER
Invoke-Command -Session $plexSession -ScriptBlock {param($URL)if(![System.IO.Directory]::Exists('C:\PlexTemp')){Write-Verbose "Missing dir"|New-Item -ItemType Directory -Path 'C:\PlexTemp' };Invoke-WebRequest -Uri $URL -OutFile "C:\PlexTemp\$($URL.split('/')  | Select-Object -Last 1)" } -ArgumentList $this.LatestVer_Windows.releases.url
###CHECK FILE HASH
if(invoke-command -session $plexSession -scriptblock {param($CHECKSUM,$FILE) $hash = (Get-FileHash -Path $FILE -Algorithm SHA1).hash;$CHECKSUM -match $hash } -ArgumentList $checksum,$updateDownloadPath){
           ###HASH OKAY - STOP SERVICE,INSTALL,START
      $waitTime = 8
      while (($plexservice = Get-Service -Name 'PlexService' -ComputerName $ComputerName).where({$_.status -ne 'Stopped'}).count -gt 0)
      {
        $plexservice.Stop();
        Start-Sleep -Seconds $waitTime
        if(get-process -ComputerName $computername -Name 'Plex Media Server'){invoke-command -session $plexSession -scriptblock {Get-Process -Name 'Plex Media Server' | Stop-Process -Force}  }
      }
      ####SERVICE DOWN, INSTALL
      Write-Verbose "Starting Install";
      $installer = invoke-command -session $plexSession -scriptblock {param($path) Start-Process -FilePath $path -ArgumentList '/quiet' -Wait } -ArgumentList $updateDownloadPath
      Write-Verbose "Installer; $installer"
      $plexservice.start();
      Start-Sleep -Seconds 7
        }
else{Write-Verbose 'checksum didnt match expected,deleting,try again';invoke-command -session $plexSession -scriptblock {param($path) Remove-Item -Path $path -Force -Confirm:$false} -ArgumentList $updateDownloadPath}
}



}
updateLibrary([string]$libraryName){
$libraryKEY = $this.index_library["$libraryName"]
$this.requestPage("/library/sections/$libraryKEY/refresh")
Write-Verbose "Refresh of $libraryName triggered"
} 

}


$verRegex = "(?<first>\d+).(?<second>\d+).(?<third>\d+).(?<fourth>\d+)-.+"


###############PLAYER-CONTROLS
#####get players via /clients
#####set header X-Plex-Target-Client-Identifier = Pl;ayer's ID
####then eg Invoke-RestMethod -Method Get -Uri "http://Decepticon.ashurtech.net:32468/player/navigation/music" -Headers $newheads










###############FUNCTIONS


<#
.Synopsis
   Creates an instance of poshPLEX vis PLEX API
.DESCRIPTION
   Creates an instance of poshPLEX vis PLEX API. Resulting object can interact with clients and servers, perform updates etc.
.EXAMPLE
   $myPLEX = Connect-poshPLEX -username 'bleh' -password 'bluh'
.EXAMPLE
   Once created, try $myPLEX.isPlexUpToDate()
#>
function Connect-poshPLEX
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([poshPLEX])]
    Param
    (
        # Plex user account username. Required to obtain token from PLEX API
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $plexUsername,

        # Plex user account password. Required to obtain token from PLEX API
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $plexPassword
    )

    Begin
    {
    if(!($plexUsername)){$plexUsername = Read-Host -Prompt 'Plex Username'}
    if(!($plexPassword)){$plexPassword = Read-Host -Prompt 'Plex Password'}
    }
    Process
    {
    [poshPLEX]$poshPLEX = [poshPLEX]::new($plexUsername,$plexPassword)
    }
    End
    {
    Return $poshPLEX
    }
}


Function randomShow ($Plex) {
Write-Verbose 'RANDOM SHOW!!!!!'
$show = $plex.library['tv shows'].shows_All | get-random
Write-Verbose -Message "SHOW: $($show.title)" 
#$show
$show_meta = $plex.requestPage($show.key)
Write-Verbose 'SHOW_META:'
#$show_meta
$show_seasons = $show_meta.Directory
Write-Verbose 'SHOW_SEASONS:'
#$show_seasons
$show_season = $show_meta.Directory[1] ##with index
Write-Verbose '1x SHOW_SEASON:'
#$show_season 
$show_season_meta = $plex.requestPage($show_season.key)
Write-Verbose 'SHOW_SEASON_META:'
#$show_season_meta
$episode = $show_season_meta.video[2]
Write-Verbose 'EPISODE:'
#$episode
$episode_more = $plex.requestPage($episode.key)
Write-Verbose 'EPISODE_MORE:'
#$episode_more
return $episode_more}



Function randomMusic ($Plex) {
Write-Verbose 'RANDOM MUSIC!!!!!'
$music = $plex.library['music'].artists_All | get-random
Write-Verbose -Message "MUSIC: $($music.title)" 
Write-Host -ForegroundColor Red -BackgroundColor White
#$music
$music_meta = $plex.requestPage($music.key)
Write-Verbose 'MUSIC_META:'
#$music_meta
return $music_meta
}


Function randomMovie ($Plex) {
Write-Verbose 'RANDOM MOVIE!!!!!'
$movie = $plex.library['movies'].movies_All | get-random
Write-Debug "MOVIE: $($movie.title)"
#$movie
Write-Debug "'Smovie.genre.count': $($movie.genre.count)"

if($movie.genre.count -gt 1){[array]$genres = @{};($movie.genre).foreach({$genres +=  $_.tag});
Write-Debug 'GENRES:';
}
if($movie.role.count -gt 1){[array]$roles = @{};Write-Debug 'ROLES:';($movie.role).foreach({$roles +=  $_.tag});Write-Verbose 'ROLES:';$roles}

if($movie.writer.count -gt 1){[array]$writers = @{};Write-Debug 'WRITERS:';($movie.writer).foreach({$writers +=  $_.tag});Write-Verbose 'WRITERS:';$writers}
$movie_meta = $plex.requestPage($movie.key)
Write-Debug 'MOVIE_META:'
$movie_out = $movie,$movie_meta
return $movie_out
}

function goPoshPlex ([poshPLEX]$poshPLEX){
[System.Collections.ArrayList]$Out = @()
$out.Add((randomMovie -Plex $poshPLEX))
$out.Add((randomMusic -Plex $poshPLEX))
$out.Add((randomShow -Plex $poshPLEX))
return $out
}
$myPLEX = Connect-poshPLEX
$done = goPoshPlex -poshPLEX $myPLEX
$done




















#############################PLEX content classes
###################Work in Progress

Class Plex_show {
[string]$title
[string]$addedAt                                                                                                                                  
[string]$childCount                                                                                                                           
[string]$contentRating                                                                                                                       
[string]$duration                                                                                                                              
[object]$Genre                                                                                                                              
[string]$index                                                                                                                                       
[string]$key                                                                                                                                            
[string]$lastViewedAt                                                                                                                         
[string]$leafCount                                                                                                                               
[string]$originallyAvailableAt                                                                                                       
[string]$rating                                                                                                                                      
[string]$ratingKey                                                                                                                               
[object]$Role                                                                                                                                    
[string]$studio                                                                                                                                    
[string]$summary                                                                                                                                  
[string]$theme                                                                                                                                                                                                                                                                         
[string]$titleSort                                                                                                                               
[string]$type                                                                                                                                        
[string]$updatedAt                                                                                                                              
[string]$viewCount                                                                                                                              
[string]$viewedLeafCount                                                                                                             
[string]$year            

###CONSTRUCTOR
Plex_show([System.Xml.XmlElement]$xmlL){
[string]$this.title = $xmlL.title
[string]$this.addedAt = $xmlL.addedAt                                                                                                                                  
[string]$this.childCount = $xmlL.childCount                                                                                                                           
[string]$this.contentRating = $xmlL.contentRating                                                                                                                       
[string]$this.duration = $xmlL.duration                                                                                                                              
[object]$this.Genre = $xmlL.Genre                                                                                                                              
[string]$this.index = $xmlL.index                                                                                                                                       
[string]$this.key = $xmlL.key                                                                                                                                            
[string]$this.lastViewedAt = $xmlL.lastViewedAt                                                                                                                         
[string]$this.leafCount = $xmlL.leafCount                                                                                                                               
[string]$this.originallyAvailableAt = $xmlL.originallyAvailableAt                                                                                                       
[string]$this.rating = $xmlL.rating                                                                                                                                      
[string]$this.ratingKey = $xmlL.ratingKey                                                                                                                               
[object]$this.Role = $xmlL.Role                                                                                                                                    
[string]$this.studio = $xmlL.studio                                                                                                                                    
[string]$this.summary = $xmlL.summary                                                                                                                                  
[string]$this.theme = $xmlL.theme                                                                                                                                       
[string]$this.title = $xmlL.title                                                                                                                                       
[string]$this.titleSort = $xmlL.titleSort                                                                                                                               
[string]$this.type = $xmlL.type                                                                                                                                        
[string]$this.updatedAt = $xmlL.updatedAt                                                                                                                              
[string]$this.viewCount = $xmlL.viewCount                                                                                                                              
[string]$this.viewedLeafCount = $xmlL.viewedLeafCount                                                                                                             
[string]$this.year = $xmlL.year
}

}
###########################################
###########################################

Class Plex_SectionTV {
[System.Xml.XmlElement]$xmlResponse;
[string]$librarySectionUUID;
[string]$librarySectionTitle;
[string]$librarySectionID;
[string]$kind
$shows_All
##CONSTRUCTOR
Plex_SectionTV ([System.Xml.XmlElement]$xmlResponse){
#$xmlResponse = $this.requestPage("/library/sections/$key/all")
$this.librarySectionID = $xmlResponse.librarySectionID;
$this.librarySectiontitle = $xmlResponse.librarysectionTitle;
$this.kind = "show";
$this.shows_All = $xmlResponse.directory;
$this.librarySectionUUID = $xmlResponse.librarySectionUUID;
}


}
Class Plex_SectionMusic {
[System.Xml.XmlElement]$xmlResponse;
[string]$librarySectionUUID;
[string]$librarySectionTitle;
[string]$librarySectionID;
[string]$kind
$artists_All

Plex_SectionMusic([System.Xml.XmlElement]$xmlResponse){
$this.librarySectionID = $xmlResponse.librarySectionID;
$this.librarySectiontitle = $xmlResponse.librarysectionTitle;
$this.kind = "artist";
$this.artists_All = $xmlResponse.directory;
$this.librarySectionUUID = $xmlResponse.librarySectionUUID;
}


}

Class Plex_SectionMovies {
[System.Xml.XmlElement]$xmlResponse;
[string]$librarySectionUUID;
[string]$librarySectionTitle;
[string]$librarySectionID;
[string]$kind
$movies_ALL
Plex_SectionMovies([System.Xml.XmlElement]$xmlResponse){
$this.librarySectionID = $xmlResponse.librarySectionID;
$this.librarySectiontitle = $xmlResponse.librarysectionTitle;
$this.kind = "video";
$this.movies_ALL = $xmlResponse.video;
$this.librarySectionUUID = $xmlResponse.librarySectionUUID;
}

}

Class Plex_Artist {





}