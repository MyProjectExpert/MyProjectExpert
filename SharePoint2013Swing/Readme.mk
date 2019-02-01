SharePoint Swing method is a method to move SharePoint front-end or app tier over to a new version of windows server.

General Steps to swing:
Install two Windows Server 2012 R2 servers and install SharePoint 2013 on each node
Join the new SharePoint servers to the SharePoint 2013 Farm. One as front-end tier and the other as app tier
Using Central Admin add services to the new app and front-end SharePoint Servers
Verify servers are working properly
Shutdown old SharePoint front-end and app server. The SharePoint farm should continue to work without the redundant server.
Optional after it is proven that the SharePoint has swung to the new SharePoint servers, the old servers can be remove and decommissioned.

