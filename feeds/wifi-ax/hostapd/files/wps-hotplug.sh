#!/bin/sh

wps_flash_leds() {
	local ubusobjs=$1
	local finished=0

	STATE=$(/sbin/leds.sh led_get_state)

	/sbin/leds.sh led_wps

	. /usr/share/libubox/jshn.sh
	while [ $finished -eq 0 ]; do
		for ubusobj in $ubusobjs; do
			json_init
			json_load "$(ubus -S call $ubusobj wps_status)"
			json_get_vars pbc_status
			[ "$pbc_status" = "Timed-out" -o "$pbc_status" = "Disabled" ] && {
				finished=1
			}
		done
		sleep 1
	done
	if [ "$STATE" = "led_actions_off" ] ; then
                /sbin/leds.sh led_off
        else
                /sbin/leds.sh $STATE
        fi

}

wps_catch_credentials() {
	local iface ifaces ifc ifname ssid encryption key radio radios
	local found=0

	. /usr/share/libubox/jshn.sh
	ubus -S -t 30 listen wps_credentials | while read creds; do
		json_init
		json_load "$creds"
		json_select wps_credentials || continue
		json_get_vars ifname ssid key encryption
		local ifcname="$ifname"
		json_init
		json_load "$(ubus -S call network.wireless status)"
		json_get_keys radios
		for radio in $radios; do
			json_select $radio
			json_select interfaces
			json_get_keys ifaces
			for ifc in $ifaces; do
				json_select $ifc
				json_get_vars ifname
				[ "$ifname" = "$ifcname" ] && {
					ubus -S call uci set "{\"config\":\"wireless\", \"type\":\"wifi-iface\",		\
								\"match\": { \"device\": \"$radio\", \"encryption\": \"wps\" },	\
								\"values\": { \"encryption\": \"$encryption\", 			\
										\"ssid\": \"$ssid\", 				\
										\"key\": \"$key\" } }"
					ubus -S call uci commit '{"config": "wireless"}'
					ubus -S call uci apply
				}
				json_select ..
			done
			json_select ..
			json_select ..
		done
	done
}

if [ "$ACTION" = "released" ] && [ "$BUTTON" = "wps" ]; then
	wps_done=0
	ubusobjs="$( ubus -S list hostapd.* )"
	for ubusobj in $ubusobjs; do
		ubus -S call $ubusobj wps_start && wps_done=1
	done

	[ $wps_done = 0 ] || wps_flash_leds "$ubusobjs" &
fi

return 0
