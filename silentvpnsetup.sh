#!/bin/sh
####################################################################################################
#
# More information: http://macmule.com/2011/12/22/how-to-silently-setup-vpn-on-10-6-10-7/
#
# GitRepo: https://github.com/macmule/10.6SilentVPNSetup
#
# License: http://macmule.com/license/
#
####################################################################################################
#
###########################################################################
# VARIABLES
###########################################################################

# The random UUID for this config
vpnUuid=`uuidgen`

# Address of VPN server
serverName=""

# The group of usernames that is allowed in
groupName=""

# The name of connection type displayed in GUI
labelName=""

# The Shared Secret
sharedSecret=""

# The user this VPN config is for
userName=""

###########################################################################
# SCRIPT
###########################################################################

# CHECK TO SEE IF A VALUE WAS PASSED IN PARAMETER 4 AND, IF SO, ASSIGN TO “serverName”
if [ "$4" != "" ] && [ "$ranAtImaging" == "" ]; then
	ranAtImaging=$4
fi

# CHECK TO SEE IF A VALUE WAS PASSED IN PARAMETER 5 AND, IF SO, ASSIGN TO “serverName”
if [ "$5" != "" ] && [ "$serverName" == "" ]; then
	serverName=$5
fi

# CHECK TO SEE IF A VALUE WAS PASSED IN PARAMETER 6 AND, IF SO, ASSIGN TO “groupName”
if [ "$6" != "" ] && [ "$groupName" == "" ]; then
	groupName=$6
fi

# CHECK TO SEE IF A VALUE WAS PASSED IN PARAMETER 7 AND, IF SO, ASSIGN TO “labelName”
if [ "$7" != "" ] && [ "$labelName" == "" ]; then
	labelName=$7
fi

# CHECK TO SEE IF A VALUE WAS PASSED IN PARAMETER 8 AND, IF SO, ASSIGN TO “sharedSecret”
if [ "$8" != "" ] && [ "$sharedSecret" == "" ]; then
	sharedSecret=$8
fi

# CHECK TO SEE IF A VALUE WAS PASSED IN PARAMETER 9 AND, IF SO, ASSIGN TO “userName”
if [ "$9" != "" ] && [ "$userName" == "" ]; then
	userName=$9
fi

loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk ‘{ print $3 }’`
macModel=`system_profiler SPHardwareDataType | grep “Model Name:” | awk ‘{ print $3 }’`

if [ "$macModel" == "MacBook" ]; then

	# Setup Keychain shared secret granting appropriate access for the OS apps
	/usr/bin/security add-generic-password -a “$groupName” -l “$labelName” -D “IPSec Shared Secret” -w “$sharedSecret” -s “$vpnUuid”.SS -T /System/Library/Frameworks/SystemConfiguration.framework/Resources/SCHelper -T /Applications/System\ Preferences.app -T /System/Library/CoreServices/SystemUIServer.app -T /usr/sbin/pppd -T /usr/sbin/racoon /Library/Keychains/System.keychain
	
	# Write a Network Config containing this keychain item directly to System Config
	/usr/libexec/PlistBuddy -c “Add :NetworkServices:$vpnUuid:DNS dict” /Library/Preferences/SystemConfiguration/preferences.plist
	/usr/libexec/PlistBuddy -c “Add :NetworkServices:$vpnUuid:IPv4 dict” /Library/Preferences/SystemConfiguration/preferences.plist
	/usr/libexec/PlistBuddy -c “Add :NetworkServices:$vpnUuid:IPv4:ConfigMethod string Automatic” /Library/Preferences/SystemConfiguration/preferences.plist
	/usr/libexec/PlistBuddy -c “Add :NetworkServices:$vpnUuid:IPv6 dict” /Library/Preferences/SystemConfiguration/preferences.plist
	/usr/libexec/PlistBuddy -c “Add :NetworkServices:$vpnUuid:Proxies dict” /Library/Preferences/SystemConfiguration/preferences.plist
	/usr/libexec/PlistBuddy -c “Add :NetworkServices:$vpnUuid:Proxies:ExceptionList array” /Library/Preferences/SystemConfiguration/preferences.plist
	/usr/libexec/PlistBuddy -c “Add :NetworkServices:$vpnUuid:Proxies:ExceptionList:0 string \*\.local” /Library/Preferences/SystemConfiguration/preferences.plist
	/usr/libexec/PlistBuddy -c “Add :NetworkServices:$vpnUuid:Proxies:ExceptionList:1 string 169\.254\/16″ /Library/Preferences/SystemConfiguration/preferences.plist
	/usr/libexec/PlistBuddy -c “Add :NetworkServices:$vpnUuid:Proxies:FTPPassive integer 1″ /Library/Preferences/SystemConfiguration/preferences.plist
	/usr/libexec/PlistBuddy -c “Add :NetworkServices:$vpnUuid:SMB dict” /Library/Preferences/SystemConfiguration/preferences.plist
	/usr/libexec/PlistBuddy -c “Add :NetworkServices:$vpnUuid:UserDefinedName string $labelName” /Library/Preferences/SystemConfiguration/preferences.plist
	/usr/libexec/PlistBuddy -c “Add :NetworkServices:$vpnUuid:Interface dict” /Library/Preferences/SystemConfiguration/preferences.plist
	/usr/libexec/PlistBuddy -c “Add :NetworkServices:$vpnUuid:Interface:Type string IPSec” /Library/Preferences/SystemConfiguration/preferences.plist
	/usr/libexec/PlistBuddy -c “Add :NetworkServices:$vpnUuid:IPSec dict” /Library/Preferences/SystemConfiguration/preferences.plist
	/usr/libexec/PlistBuddy -c “Add :NetworkServices:$vpnUuid:IPSec:AuthenticationMethod string SharedSecret” /Library/Preferences/SystemConfiguration/preferences.plist
	/usr/libexec/PlistBuddy -c “Add :NetworkServices:$vpnUuid:IPSec:LocalIdentifier string $groupName” /Library/Preferences/SystemConfiguration/preferences.plist
	/usr/libexec/PlistBuddy -c “Add :NetworkServices:$vpnUuid:IPSec:LocalIdentifierType string KeyID” /Library/Preferences/SystemConfiguration/preferences.plist
	/usr/libexec/PlistBuddy -c “Add :NetworkServices:$vpnUuid:IPSec:RemoteAddress string $serverName” /Library/Preferences/SystemConfiguration/preferences.plist
	/usr/libexec/PlistBuddy -c “Add :NetworkServices:$vpnUuid:IPSec:SharedSecret string $vpnUuid\.SS” /Library/Preferences/SystemConfiguration/preferences.plist
	/usr/libexec/PlistBuddy -c “Add :NetworkServices:$vpnUuid:IPSec:SharedSecretEncryption string Keychain” /Library/Preferences/SystemConfiguration/preferences.plist
	/usr/libexec/PlistBuddy -c “Add :NetworkServices:$vpnUuid:IPSec:XAuthName string $userName” /Library/Preferences/SystemConfiguration/preferences.plist
	/usr/libexec/PlistBuddy -c “Add :NetworkServices:$vpnUuid:IPSec:XAuthPasswordEncryption string Prompt” /Library/Preferences/SystemConfiguration/preferences.plist
	
	# At this point, we should have only one Network Set (Automatic) so we find out its UUID — errr, messy
	autoUuid=`/usr/libexec/Plistbuddy -c “Print :Sets” /Library/Preferences/SystemConfiguration/preferences.plist | grep -B1 -m1 Automatic | grep Dict | awk ‘{ print $1 }’`
	
	# and we add our newly created config to the default set
	/usr/libexec/PlistBuddy -c “Add :Sets:$autoUuid:Network:Service:$vpnUuid dict” /Library/Preferences/SystemConfiguration/preferences.plist
	/usr/libexec/PlistBuddy -c “Add :Sets:$autoUuid:Network:Service:$vpnUuid:__LINK__ string \/NetworkServices\/$vpnUuid” /Library/Preferences/SystemConfiguration/preferences.plist
	/usr/libexec/PlistBuddy -c “Add :Sets:$autoUuid:Network:Global:IPv4:ServiceOrder: string $vpnUuid” /Library/Preferences/SystemConfiguration/preferences.plist

else
	echo “This mac is not a MacBook… so skipping…”
fi
