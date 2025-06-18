#!/bin/bash

# ~ Christina Mantik <tina@ft50.org>
#   Falls ihr fragen habt, helf ich gerne :)
#
# - Notes:
# Changes are definitely needed to get this working with all kinds of beamers and other
# devices. This may work for some Epson beamers, but definitely isnt a plug and play
# solution, due to the nature of every company doing their own stuff.
#
# - WiringPi Pinouts:
# Leds (physical pins):
# Bluetooth	= 15 - Ground
# Power		= 16 - Ground
#
# Button (physical pins):
# Bluetooth	= 11 - Ground
# Power		= 5  - Ground
#
# - Dependencies: socat, bluez

# variables
SERIAL_DEVICE_ARRAY=("/dev/ttyS0" "/dev/ttyUSB0" "/dev/ttyUSB1" "/dev/ttyUSB2" "/dev/ttyCH341USB0" "/dev/ttyCH341USB1" "/dev/ttyCH341USB2")
#SERIAL_DEVICE_ARRAY=("/dev/ttyUSB0" "/dev/ttyUSB1" "/dev/ttyUSB2" "/dev/ttyCH341USB0" "/dev/ttyCH341USB1" "/dev/ttyCH341USB2") # use this when not using the PI serial port
VOLUME1="125"
VOLUME2="125"
CYCLEA="1"
CYCLEB="1"
PIPE="/tmp/pipe"
PIPE_BL="/tmp/pipe_bl"
PORT="1234"
BL_VERIFY_PORT="1235"
BLUETOOTH_SECRET="test1234"
DIR=/usr/BACKEND

# create pipe for the TCP socket
mkfifo "$PIPE" 2> /dev/null

# functions

# simple TCP socket using socat, that pipes whatever it gets into a named pipe
receive() {
	socat -u tcp-l:$PORT,fork,reuseaddr,reuseport file:"$PIPE" &
}

gpio_init() {
	sleep 0.5
	$DIR/buttons/button_bluetooth &
	$DIR/buttons/button_power &
}

# gathers usable serial devices and stores them in an array.
find_serial_devices() {
	for device in "${SERIAL_DEVICE_ARRAY[@]}"
	do
		if [[ -e "$device" ]]
		then
			USABLE_SERIAL_DEVICE_ARRAY+=("$device")
		fi
	done

	echo "  Usable serial devices: ${USABLE_SERIAL_DEVICE_ARRAY[*]}"
	if [[ "${#USABLE_SERIAL_DEVICE_ARRAY[@]}" -lt "3" ]]
	then
		echo "  Warning: less than 3 serial devices connected!"
	fi
}

# this took weeks to figure out (improvements may be necassary)
find_matrix() {
	while :
	do
		for device in "${USABLE_SERIAL_DEVICE_ARRAY[@]}"
		do
			(
				#response=$(head -n 1 < "$device")
				response="$(head -n 1 < $device | cut -c-1 -)"
				if [[ "$response" == "<" ]]
				then
					echo "  FOUND: $device"
					echo -n "$device" > /tmp/SERIAL_DEVICE
				fi
			) &
			echo ">GetPowerOn" > "$device"
			sleep 1
		done
		if [[ ! -f /tmp/SERIAL_DEVICE ]]
		then
			continue
		else
			break
		fi
	done
	MATRIX="$(cat /tmp/SERIAL_DEVICE)"
	USABLE_SERIAL_DEVICE_ARRAY=("${USABLE_SERIAL_DEVICE_ARRAY[@]/$MATRIX}")
	#asumes remaining devices are beamer 1 and 2
	BEAMER1="${USABLE_SERIAL_DEVICE_ARRAY[1]}"
	BEAMER2="${USABLE_SERIAL_DEVICE_ARRAY[2]}"
}

# checks for the broken CH341 serial adapter, and applies duct tape solution
# to get it to work
check_serial_adapter() {
	if lsusb | grep 1a86 > /dev/null 2>&1
	then
		china=1
	else
		china=0
	fi
}

# said duct tape solution. For some reason necassary for the beamers,
# but not for the HDMI matrix.
fill() {
	command="$1"
	if [[ "$china" == "0" ]]
	then
		return
	fi
	while :
	do
		command="${command}\x0"
		if [[ "$(echo -e $command | wc -c)" == "15" ]]
		then
			break
		fi
	done
}

send() {
	echo -e "$1" > "$2"
}

bluetooth_hciconfig_loop() {
	while :
	do
		sudo hciconfig hci0 leadv 0 2> /dev/null
		sleep 2
	done &
	bluetooth_loop_pid="$!"
}

bluetooth() {
	python $DIR/bluetooth/bluetooth.py &
	bluetooth_pid="$!"
}

bluetooth_verify() {
	(
		mkfifo $PIPE_BL 2> /dev/null
		python $DIR/bluetooth/bluetooth_verify.py &
		verify_pid="$!"
		socat -U tcp-l:$BL_VERIFY_PORT,reuseaddr,reuseport file:"$PIPE_BL" &
		while IFS= read -r answer
		do
			if [[ "$answer" == "$BLUETOOTH_SECRET" ]]
			then
				kill -9 "$verify_pid"
				echo -e "  Correct secret, starting main bluetooth control"
				bluetooth
				break
			else
				echo -e "  Wrong secret"
			fi
		done < "$PIPE_BL"
	) &
}

# main loop of the script. Basically a huge case sequence that takes input
# from the pipe that the TCP socket puts whatever it gets into, and acts accordingly.
process() {
	# nh justus
	while :; do
	while IFS= read -r line
	do
		case "$line" in
			# MATRIX CODES
			"matrix_out_a_1")
				command=">SetAV A H1"
				send "$command" "$MATRIX"
			;;
			"matrix_out_a_2")
				command=">SetAV A H2"
				send "$command" "$MATRIX"
			;;
			"matrix_out_a_3")
				command=">SetAV A H3"
				send "$command" "$MATRIX"
			;;
			"matrix_out_a_4")
				command=">SetAV A H4"
				send "$command" "$MATRIX"
			;;
			"matrix_out_a_cycle")
				command=">SetAV A H$CYCLEA"
				send "$command" "$MATRIX"
				CYCLEA="$(( $CYCLEA + 1 ))"
				if [[ "$CYCLEA" == "5" ]]
				then
					CYCLEA="1"
				fi
			;;
			"matrix_out_b_1")
				command=">SetAV B H1"
				send "$command" "$MATRIX"
			;;
			"matrix_out_b_2")
				command=">SetAV B H2"
				send "$command" "$MATRIX"
			;;
			"matrix_out_b_3")
				command=">SetAV B H3"
				send "$command" "$MATRIX"
			;;
			"matrix_out_b_4")
				command=">SetAV B H4"
				send "$command" "$MATRIX"
			;;
			"matrix_out_b_cycle")
				command=">SetAV B H$CYCLEB"
				send "$command" "$MATRIX"
				CYCLEB="$(( $CYCLEB + 1 ))"
				if [[ "$CYCLEB" == "5" ]]
				then
					CYCLEB="1"
				fi
			;;
			# BEAMER1 CODES
			"beamer1_pwron")
				fill "PWR ON"
				send "$command" "$BEAMER1"
			;;
			"beamer1_pwroff")
				fill "PWR OFF"
				send "$command" "$BEAMER1"
			;;
			"beamer1_muteon")
				fill "MUTE ON"
				send "$command" "$BEAMER1"
			;;
			"beamer1_muteoff")
				fill "MUTE OFF"
				send "$command" "$BEAMER1"
			;;
			"beamer1_freezeon")
				fill "FREEZE ON"
				send "$command" "$BEAMER1"
			;;
			"beamer1_freezeoff")
				fill "FREEZE OFF"
				send "$command" "$BEAMER1"
			;;
			"beamer1_volup")
				if [[ "$VOLUME1" -ge "250" ]]; then
					continue
				fi
				VOLUME1="$(( $VOLUME1 + 25 ))"
				fill "VOL $VOLUME1"
				send "$command" "$BEAMER1"
			;;
			"beamer1_voldown")
				if [[ "$VOLUME1" == "0" ]]; then
					continue
				fi
				VOLUME1="$(( $VOLUME1 - 25 ))"
				fill "VOL $VOLUME1"
				send "$command" "$BEAMER1"
			;;
			# BEAMER2 CODES
			"beamer2_pwron")
				fill "PWR ON"
				send "$command" "$BEAMER2"
			;;
			"beamer2_pwroff")
				fill "PWR OFF"
				send "$command" "$BEAMER2"
			;;
			"beamer2_muteon")
				fill "MUTE ON"
				send "$command" "$BEAMER2"
			;;
			"beamer2_muteoff")
				fill "MUTE OFF"
				send "$command" "$BEAMER2"
			;;
			"beamer2_freezeon")
				fill "FREEZE ON"
				send "$command" "$BEAMER2"
			;;
			"beamer2_freezeoff")
				fill "FREEZE OFF"
				send "$command" "$BEAMER2"
			;;
			"beamer2_volup")
				if [[ "$VOLUME2" -ge "250" ]]; then
					continue
				fi
				VOLUME2="$(( $VOLUME2 + 25 ))"
				fill "VOL $VOLUME2"
				send "$command" "$BEAMER2"
			;;
			"beamer2_voldown")
				if [[ "$VOLUME2" == "0" ]]; then
					continue
				fi
				VOLUME2="$(( $VOLUME2 - 25 ))"
				fill "VOL $VOLUME2"
				send "$command" "$BEAMER2"
			;;
			# PI CODES
			"pi_bluetooth")
				# physical gpio pin 11, to ground
				if [[ "$bluetooth_pid" != "" ]]
				then
					$DIR/leds/bluetooth_off
					kill $bluetooth_loop_pid
					kill $bluetooth_pid
					bluetooth_loop_pid=""
					bluetooth_pid=""
				else
					echo -e "\e[1;35m Starting bluetooth backend...\e[m"
					$DIR/leds/bluetooth_on
					bluetooth_hciconfig_loop
					#bluetooth_verify
					bluetooth
				fi
			;;
			"pi_power")
				# physical gpio pin 5, to ground
				poweroff
			;;
			*)
				echo "ERROR: hermann war mal wieder am werk"
			;;
		esac
	done < $PIPE
	done
}

echo -e "\e[1;35m Starting serial backend...\e[m"
echo -e "\e[1;35m Checking serial chipset...\e[m"
check_serial_adapter
echo -e "\e[1;35m Finding serial devices...\e[m"
find_serial_devices
echo -e "\e[1;35m Finding HDMI matrix...\e[m"
find_matrix
echo -e "\e[1;35m Starting TCP listener...\e[m"
receive
echo -e "\e[1;35m Starting GPIO communication...\e[m"
gpio_init
echo -e "\e[1;35m Starting main loop...\e[m"
echo -e "\n Server info:\n	Port = $PORT\n	Cheap serial adapter = $china\n	Matrix Device = $MATRIX\n	Beamer1 = $BEAMER1\n	Beamer2 = $BEAMER2"
$DIR/leds/power_on
process

