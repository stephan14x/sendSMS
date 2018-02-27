# Powershell Script to send SMS via COM Port AT Commands for Paessler Network Monitor
# 
# How to use it:
#
# Detailed description:
# https://www.paessler.com/manuals/prtg/notifications_settings#program
#
# Copy the script to /Notifications/EXE sub-directory of your PRTG core server system.
#
# Create a exe-notification on PRTG under Setup -> Account Settings -> Notifications
# select 'sendSMS.ps1' as program
#
# The parameter section consists of the following named parameters:
# 
# - $phoneNumber   e.g. +49XXXYYYYYYY
# - $deviceName    e.g. %device
# - $deviceStatus  e.g. %status
# - $deviceLink    e.g. %linkdevice
# - $sensorName    e.g. %sensor
# 
# Example
# 
# All parameters except the SMS Receiving phone number are placeholders and will be filled with info from PRTG
# I'm using triple double-quotes around the placeholders to prevent issues with spaces in the placeholder values
# Most special chars have worked but these ' ` ´ in the placeholder values might kill the script
# 
#    -phoneNumber +49XXXYYYYYYYY -deviceName """%device""" -deviceStatus """%status""" -deviceLink """%linkdevice""" -sensorName """%sensor"""
#
# There are other placeholders available, see https://kb.paessler.com/en/topic/373-what-placeholders-can-i-use-with-prtg
# But not all of them work for Notifications, if the are not available, the Notification will fail without doing anything
# You have to do some try and error to add more information by using these placeholders
#
# There is NO error handling!!!
# This script comes without warranty or support.
Param(
  [string]$phoneNumber,
  [string]$deviceName,
  [string]$deviceStatus,
  [string]$deviceLink,
  [string]$sensorName
)

# truncate device name and State to keep the SMS below 160 chars
$sensorName=$sensorName.subString(0, [System.Math]::Min(25, $sensorName.Length))
# Static Message text is about 35 chars so start with 120
$remainingChars=120-$deviceLink.Length-$deviceStatus.Length-$sensorName.Length
$deviceName=$deviceName.subString(0, [System.Math]::Min($remainingChars, $deviceName.Length))

$smsMessage = "State of sensor ""$sensorName"" on ""$deviceName"" changed to ""$deviceStatus"" $deviceLink"

# Set the parameters for the COM port where the serial modem is connected
$port= new-Object System.IO.Ports.SerialPort COM3,57600,None,8,one

try
{
    $port.open()
}
catch 
{
	# Wait for 5s and try again
	# This is a quick-hack, almost no error handling...
	Start-Sleep -Seconds 5
	$port.open()
}

If ($port.IsOpen -eq $true) 
{
	# Set SMS Text Mode, you can query the available modes with AT+CMGF?
	$port.Write("AT+CMGF=1")
	# Send a newline char, if tried different approaches including WriteLine and appending `r`n but only this worked for me
	$port.Write($([char] 13))
	# Set the phone number, the AT command requires the phone number in double-quotes, so we use double-quotes to escape the double-quotes...
	$port.Write("AT+CMGS=""$phoneNumber""")
	# Again a new line
	$port.Write($([char] 13))
	# now we set the message with the variable from above, the text can containe new lines, but I have not testet using them
	$port.Write("$smsMessage")
	# Send CTRL-Z to signal the end of the message
	$port.Write($([char] 26))
	# Cosing the COM port
	$port.Close()
}

exit 0;