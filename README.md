# poshPLEX
a powershell class using the PLEX api to automate updates, query the library etc

the 'Connect-poshPLEX' cmdlet will create an instance of the class, which then uses the PLEX API to implement a number of methods for interacting with PLEX servers and clients.

Project is still very work in progress, but currently it can:

-obtain an auth token from PLEX
-locate PLEX servers and clients
-query PLEX libraries
-trigger library update
-check if servers are up to date
-download and install required updates (including if run as a service)*
*WINDOWS ONLY AT THE MOMENT

-hope to implement control of playback on clients in the near future.
