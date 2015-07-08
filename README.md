# find_fastest_vpn

## Short description

Shell script to determine the fastest OpenVPN connection out of a list of VPN servers, from which the authentication credentials, keys and other specific settings are know. This might be free servers but commercial servers as well. Every server which might be addressed directly via OpenVPN could be integrated.

## Requirements/Preparatory work

To use the script, there are some requirements:

- the service "openvpn" has to be installed and ready to use (will be needed for the perfomace measurement)
- then entry **<AUTOSTART="current">** in the **"/etc/defaults/openvpn"** file must exists (to automatically load the configuration)
- as default, the script expects a tree structure under the folder */etc/openvpn*:
![Alt text](resources/tree.png?raw=true "Expected file tree (example)")

The following dirctories are expected:
- */etc/openvpn/providers/<myProvider>* - form here all provider specific data is stored
- */etc/openvpn/providers/<myProvider>/configs* - any *.ovpn* configuration files you received from you provider go here
There has to be the following files:
- */etc/openvpn/providers/<myProvider>/additional.txt* - provider global conifguration settings and options
- */etc/openvpn/providers/<myProvider>/vpnhosts* - list of all .ovpn files (basename) which will be included in the scan

## Let's do the hard work!

To prepare the data, you need at first a bunch of .ovpn files from your desired VPN provider. These must be copied into the directory /etc/openvpn/providers/<myProvider>/configs. Then you identify all the dasta in the .ovpn file which is provider or user specific, e.g. the user credentials and the key and certificate file provided by the VPN hoster.

An example, in a .ovpn file you fin the following lines:
  
  ca ca.crt
  auth-user-pass auth.txt
  verb 3
  
you copy these lines to the file /etc/openvpn/providers/<myProvider>/additional.txt and you change the entries to absolute path names:

  ca /etc/openvpn/providers/<myProvider>/ca.crt
  auth-user-pass /etc/openvpn/providers/<myProvider>/auth.txt
  verb 3
  
You see that all the files - which later will be commonly used in connection to the .ovpn file - should be found under the  /etc/openvpn/providers/<myProvider>/ directory. The names may differ and there might be also other files referenced in the .ovpn file - all these commonly used files go to the <myProvider> directory. Normally, this will be a key file, a certificate file and the user credentail file. So be sure all common files references of the .ovpn files are found in "additional.txt" with their appropritate absolute file names as shown above.

If you like to globally change some settings of the bunch of .ovpn files, you may add other entries in "additional.txt" as well. E.g. you need some logging, you may put these lines in the file:

  log-append /var/log/openvpn/client.log
  verb 3

as you would add in the "normal" configuration.

After these preparation, you may start the script like

  ./find_fastest_vpn.sh -p <myProvider>
  
1. Preparation of the configuration files
=========================================

Now the script will scan all .ovpn files found under /etc/openvpn/providers/<myProvider>/configs/ and replace all entries found in "additional.txt" in the .ovpn file. If an entry is not found, it will be attached to the current entries. The resulting file will be copied under /etc/openvpn/providers/<myProvider>/preps/, so we are sure, no original .ovpn file will be changed. If a corresponding .ovpn file exists already under the "preps" directory, it will be skipped. So if you want to renew these "prepared" configuration files, for example because of some changes you made in "additional.txt", you just delete all :ovpn files under /etc/openvpn/providers/<myProvider>/preps/, and after the next start of the script, the configuration files wil be newly generated.

2. Find the fastest server
==========================

For the determination of the fastest server connection, you need at first a file with a list, where all servers are listed which you need to include in the performance test. The file name will be /etc/openvpn/providers/<myProvider>/vpnhosts, and the .opvn configurations are listed linewise in the file with their basename like:

  myProvider-DE-Frankfurt.ovpn
  #myProvider-UK-London.ovpn  -> will be skipped
  myProvider-US-NewYork.ovpn
  #myProvider-US-LasVegas.ovpn -> will be skipped
  myProvider-US-LosAngeles.ovpn
  
You may generate this file with "ls -1 > vpnhosts" in the directory /etc/openvpn/providers/<myProvider>/configs, and move the "vpnhosts" file one level up after this. As you may comment out single entries with the hash sign "#" at the beginning of the line, you may add all servers and disable only those you don't want to check. It's convenient to have a list of perhaps 10 or 15 servers, because the bandwidth measurement needs it's time.

After these preparation works, the environment ist ready for the action which is the purpose of the script: check the servers bandwidtch an select the fastest asl current OpenVPN configuration.

So now the script will step through all active entries in "vpnhosts" and tries to establish a connection with the VPN server configured in the appropriate .ovpn file. On success, it tries to establish a connection to an public server which provides some "iperf" functionalities, the server may be set in the script configuration file. Over the "iperf" test it neasures the bandwidth - routed over the OpenVPN server, so this will be a good value to compare between the different OpenVPN tunnels. If there are errors - no connection, or no bandwidth determined - the entry will be skipped.

> After all entries are scanned, the script picks the entry which caused the best bandwidth value and creates a symbolic link named "/etc/openvpn/current.conf". This link points to the actually determined, fastest VPN connection. So you have to be sure that openvpn is configured to automatically load the configuration found under the "current.conf" link. Therefore you need an entry <AUTOSTART="current"> in the "/etc/defaults/openvpn" file, then openvpn will load the file "/etc/openvpn/current.conf" when started as service. (Debian)

ToDo
====

- add an option "force" to newly generate the "preparated" configurations even if they already exists
- add an option to check, if openvpn ist correctly configured to autoload the "current.conf" settings
- add a function to generate the "vpnhosts" file with the list of all available configurations

If you have feedback, ideas or found a bug, feel free to contact me.

July 2015 - Manfred Mueller-Spaeth - fms1961@gmail.com



