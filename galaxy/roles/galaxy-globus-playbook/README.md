##### The TCP ports that must be open for the default Globus Connect Server installation, together with brief descriptions of each, are listed here:

- Port 2811 inbound from 184.73.189.163 and 174.129.226.69
    - Used for GridFTP control channel traffic.

- Ports 50000—51000 inbound and outbound to/from Any
    - Used for GridFTP data channel traffic.
    - The use of the default port range is strongly recommended (you can read why [here](https://docs.globus.org/resource-provider-guide/#data_channel_traffic)).
    - Data channel traffic is sent directly between endpoints—it is not relayed by the Globus service.

- Port 2223 outbound to 184.73.255.160
    - Used to pull certificate information from the Globus service.

- Port 443 outbound to 174.129.226.69 and nexus.api.globusonline.org
    - Used to communicate with the Globus service via its REST API.
    - nexus.api.globusonline.org is a CNAME for an Amazon [ELB](http://aws.amazon.com/elasticloadbalancing/); IP addresses in the ELB are subject to change.

- Port 80 outbound to 192.5.186.47
    - Used to pull Globus Connect Server install packages from the Globus repository.

- Port 7512 inbound from 174.129.226.69
    - Used for MyProxy traffic.
    - Needed if your server will run MyProxy service.

- Port 443 inbound from Any
    - Used for OAuth traffic.
    - Needed if your server will run OAuth service.
    - OAuth traffic comes directly from clients using your OAuth service—it is not relayed by the Globus service.
