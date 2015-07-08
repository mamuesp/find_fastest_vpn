# find_fastest_vpn

A script to use on a openvpn gateway - one may automatically activate the fastest connection of the available server, even with different providers, if user credentials and correct connection parameters are in place.

## 1. About
Shell script to use on a router which provides access as gateway to an OpenVPN server tunnel. The script will determine the fastest OpenVPN connection out of a list of VPN servers, from which the authentication credentials, keys and other specific settings are known. This might be free servers but commercial servers as well. Every server which might be addressed directly via OpenVPN could be integrated.

##2. License
This script is under the MIT License. See LICENSE file.

##3. Dependencies
This scripts needs openvpn and iperf clients installed

##4. Requirements/Preparatory work
To use the script, there are some requirements:

- the service "openvpn" has to be installed and ready to use (will be needed for the perfomace measurement)
- then entry **<AUTOSTART="current">** in the **"/etc/defaults/openvpn"** file must exists (to automatically load the configuration)
- as default, the script expects a tree structure under the folder */etc/openvpn*:

![Alt text](resources/tree.png?raw=true "Expected file tree (example)")

The following directories are expected:
- */etc/openvpn/providers/<myProvider>* - from here all provider specific data is stored
- */etc/openvpn/providers/<myProvider>/configs* - any *.ovpn* configuration files you received from you provider go here

The following files are expected:
- */etc/openvpn/providers/<myProvider>/additional.txt* - provider global conifguration settings and options
- */etc/openvpn/providers/<myProvider>/vpnhosts* - list of all .ovpn files (basename) which will be included in the scan

##3. Now let's do the hard work!
To prepare the data, you need at first a bunch of *.ovpn* files from your desired VPN provider, normally send to you via e-mail as zipped file. These must be copied into the directory */etc/openvpn/providers/<myProvider>/configs*. Then you open a *.ovpn* fiel representatively for all files. Now we have to identify all the data in the file which is provider or user specific, e.g. the user credentials, the filename of the RSA key, the certificate file - all provided by your VPN hoster.

An example, in configuration file you'll find the following lines:

```bash
ca ca.crt
auth-user-pass auth.txt
verb 3
```
you want to copy these lines into the (newly created) file */etc/openvpn/providers/<myProvider>/additional.txt* and change the entries now to absolute path names:

```bash
ca /etc/openvpn/providers/<myProvider>/ca.crt
auth-user-pass /etc/openvpn/providers/<myProvider>/auth.txt
verb 3
```
You see that all the global files - which later will be commonly used in connection to the selected *.ovpn* file - should be found under the */etc/openvpn/providers/<myProvider>/* directory. The names of the files may differ from provider to provider and there might be also other and more files referenced in the *.ovpn* file - all these commonly used files go to the <myProvider> directory. Normally, the base will be a key file, a certificate file and the user credential file. So be sure all common files references of the *.ovpn* files are found in **"additional.txt"** with their appropritate absolute file names as shown above.

If you like to globally change some settings of the OpenVPN connections, you may add other entries in **"additional.txt"** as well. E.g. you need some logging, you may put these lines in the file:

```bash
  log-append /var/log/openvpn/client.log
  verb 3
```
as you would add in a standard *.ovpn* configuration file.

Now if the all these points are done and chekced, you may start the script like

```bash
  ./find_fastest_vpn.sh -p <myProvider>
```
  
##4. Preparation of the configuration files
Now the script will scan all .ovpn files found under */etc/openvpn/providers/<myProvider>/configs/* and replace all entries found in **"additional.txt"** in the *.ovpn* file. If an entry is not found, it will be attached to the current entries. The resulting file will be copied under */etc/openvpn/providers/<myProvider>/preps/*, so we are sure, no original *.ovpn* file will be changed. If a corresponding *.ovpn* file already exists in the **"preps"** directory, it will be skipped. So if you want to renew these generated configuration files, for example because of some changes you made in **"additional.txt"**, you just empty the *../preps/* directory, and after the next start of the script, the configuration files wil be newly generated.

##5. Find the fastest server
For the determination of the fastest server connection, you need at first a file with a list configuration files. There all server configurations are listed which you need to include in the performance test. The file name expected is */etc/openvpn/providers/<myProvider>/vpnhosts*, and the *.opvn* configurations are listed linewise in the file with their basename like:

  ```bash
   myProvider-DE-Frankfurt.ovpn
   #myProvider-UK-London.ovpn  -> will be skipped
   myProvider-US-NewYork.ovpn
   #myProvider-US-LasVegas.ovpn -> will be skipped
   myProvider-US-LosAngeles.ovpn
   ```
You may generate this file with *"ls -1 > vpnhosts"* in a shell, if you changed the directory to */etc/openvpn/providers/<myProvider>/configs*. Move the "vpnhosts" file one level up after this to *../<myProvider>*. As you may comment out single entries with the hash sign **"#"** at the beginning of the line, you may add all servers and disable only those you don't want to check. It's convenient to have a list of perhaps 10 or 15 servers, because the bandwidth measurement needs it's time.

After these preparation works, the environment ist ready for the action which is the basic purpose of the script: check the servers bandwidtch and use the fastest as current OpenVPN configuration.

So now the script will step through all active entries in "vpnhosts" and tries to establish a connection with the VPN server configured in the appropriate *.ovpn* file. On success, it tries to establish a connection to an public server which provides some **"iperf"** functionalities, the server may be set in the scripts configuration file. Over the **"iperf"** test it measures the bandwidth - routed over the OpenVPN server, so this will be a good value to compare the bandwidth between the different OpenVPN tunnels. If there are errors - as no connection, or no bandwidth determined - the entry will be skipped.

> After all entries are scanned, the script picks the entry which caused the best bandwidth value and creates a symbolic link named "/etc/openvpn/current.conf". This link points to the actually determined, fastest VPN connection. So you have to be sure that openvpn is configured to automatically load the configuration found under the "current.conf" link. Therefore you need an entry **<AUTOSTART="current">** in the *"/etc/defaults/openvpn"* file, then openvpn will load this file when started as service. (Debian)

##6. ToDo

- add an option "force" to newly create the generated configurations even if they already exists
- add an option to check, if openvpn ist correctly configured to autoload the "current.conf" settings
- add a function to generate the **"vpnhosts"** file with the list of all available configurations

If you have some feedback, ideas or found a bug, feel free to contact me.

Copyright July 2015 by Manfred Mueller-Spaeth - fms1961@gmail.com



