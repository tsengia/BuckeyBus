#!/bin/bash
BUCKEY_SETUP_VERSION=0.1

source buckey-setup.conf

#Exit on errors
set -e

#Check to see if the buckey user exists, if it does, skip creating it and the user group. If it doesn't exist, create the user and the user group
create_buckey_user() {
	if id -u ${BUCKEY_RUN_USER} >/dev/null 2>&1; then
		echo "WARNING: The '${BUCKEY_RUN_USER}' user already exists! Assuming from a previous Buckey install..."
	else
		echo "User '${BUCKEY_RUN_USER}' not found, creating..."
		if useradd -c "User for the Buckey AI system" -M -r -U ${BUCKEY_RUN_USER} ; then
			echo "Created '${BUCKEY_RUN_USER}' user and user group..."
		else
			echo "Failed to create the '${BUCKEY_RUN_USER}' user! Are you sure you have the correct permissions?"
			exit -1
		fi
	fi
}

#Create the user that will run the dedicated DBus for Buckey
create_buckey_bus_user() {
	if id -u ${BUCKEY_BUS_RUN_USER} >/dev/null 2>&1; then
		echo "WARNING: The '${BUCKEY_BUS_RUN_USER}' user already exists! Assuming from a previous Buckey install..."
	else
		echo "User '${BUCKEY_BUS_RUN_USER}' not found, creating..."
		if useradd -c "User for the Buckey AI dedicated DBus daemon" -M -r -N ${BUCKEY_BUS_RUN_USER} ; then
			echo "Created '${BUCKEY_BUS_RUN_USER}' user..."
		else
			echo "Failed to create the '${BUCKEY_BUS_RUN_USER}' user! Are you sure you have the correct permissions?"
			exit -1
		fi
	fi
}


#Create the directories for Buckey
create_buckey_directories() {
	mkdir -v -p /etc/buckey
	mkdir -v -p /etc/buckey/bus
	mkdir -v -p /var/run/buckey
	mkdir -v -p /var/log/buckey

	chown buckey /etc/buckey
	chown buckey /var/run/buckey
	chown buckey /var/log/buckey
}

install_syslog_config() {
	if [ -d /etc/rsyslog.d ]; then
		echo "Found rsyslog installation"
		echo ':syslogtag, isequal, "buckey:"    /var/log/buckey/buckey.log' > /etc/rsyslog.d/30-buckey.conf
		echo "Installed rsyslog configuration"
	fi
}

echo "Setup script for Buckey system, version 0.1..."

echo "Testing for existance of and creating the '${BUCKEY_RUN_USER}' user"
create_buckey_user

echo "Creating Buckey's dedicated DBus user..."
create_buckey_bus_user

echo "Creating /etc and /var directories..."
create_buckey_directories

echo "Copying in the buckey-setup.conf file..."
cp -v buckey-setup.conf /etc/buckey/

echo "Generating the dedicated DBus config file..."
cat >buckey-dbus.conf <<EOL
<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-Bus Bus Configuration 1.0//EN" "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>

	<!--
		Dedicated DBus bus for Buckey. Generated by setup.sh version ${BUCKEY_SETUP_VERSION}
	-->

	<type>session</type>
	<fork />
	<syslog />

	<pidfile>${BUCKEY_BUS_PID_FILE}</pidfile>

	<listen>unix:path=${BUCKEY_BUS_SOCKET_PATH}</listen>

	<policy context="default" >
		<allow send_destination="*" eavesdrop="true" />
		<allow eavesdrop="true" />
		<allow send_type="method_call" />
	</policy>
</busconfig>
EOL
cp -v buckey-dbus.conf ${BUCKEY_BUS_CONFIG_PATH}

echo "Installing syslog configuration for Buckey..."
install_syslog_config


echo "DONE"
