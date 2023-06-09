#!/usr/bin/env bash


################################################################################
### Head: Init
##
set -e ## for Exit immediately if a command exits with a non-zero status.
THE_BASE_DIR_PATH="$(cd -- "$(dirname -- "$0")" ; pwd)"
THE_CMD_FILE_NAME="$(basename "$0")"
##
### Tail: Init
################################################################################


################################################################################
### Head: Util / Debug
##

util_error_echo () {
	echo "$@" 1>&2
}

##
### Head: Util / Debug
################################################################################


################################################################################
### Head: Signal
##
exit_on_signal_interrupted () {

	util_error_echo
	util_error_echo "## Script interrupted."
	util_error_echo

	mod_iso_clean_on_exit
	exit 0
}

exit_on_signal_terminated () {

	util_error_echo
	util_error_echo "## Script terminated."
	util_error_echo

	mod_iso_clean_on_exit
	exit 0
}

mod_signal_bind () {
	trap exit_on_signal_interrupted SIGINT
	trap exit_on_signal_terminated SIGTERM
}

##
### Tail: Signal
################################################################################


################################################################################
### Head: Model / Build ISO
##

mod_iso_profile_clone () {

	mkdir -p ./var

	if [ -a ./var/profile ]; then
		return 0
	fi

	git clone https://github.com/endeavouros-team/EndeavourOS-ISO.git ./var/profile

}

mod_iso_profile_prepare () {

	cp -rf ./var/profile ./profile
	
	mod_iso_profile_overlay

	mkdir -p ./tmp

}

mod_iso_clean_on_prepare () {
	util_error_echo
	util_error_echo "## Cleaning Data On Prepare"
	util_error_echo

	rm -rf "./profile"
	sudo rm -rf "./tmp"

}

mod_iso_clean_on_exit () {
	util_error_echo
	util_error_echo "## Cleaning Data On Exit"
	util_error_echo

	#rm -rf "./tmp/work"
	rm -rf "./tmp/out"

}

mod_iso_clean_on_finish () {
	util_error_echo
	util_error_echo "## Cleaning Data On Finish"
	util_error_echo

	#rm -rf "./tmp/work"
	#rm -rf "./tmp/out"
}

mod_iso_make_prepare () {
	mod_iso_clean_on_prepare
	mod_iso_profile_clone
	mod_iso_profile_prepare
}


mod_iso_make () {

	util_error_echo
	util_error_echo "## Building New ISO"
	util_error_echo

	#sudo mkarchiso -v profile
	#sudo mkarchiso -w tmp/work -o tmp/out -v profile
	#sudo ./profile/mkarchiso -w tmp/work -o tmp/out -v profile

	cd ./profile	

	sudo ./mkarchiso -v .

	cd "${OLDPWD}"


}

mod_iso_make_finish () {

	mod_iso_make_copy_to_store

	mod_iso_clean_on_finish

}

mod_iso_make_copy_to_store () {

	local iso_store_dir_path="../../../../iso/"

	if ! [ -d "${iso_store_dir_path}" ]; then
		return
	fi

	cp -a out/*.iso "${iso_store_dir_path}/"
}

mod_iso_build () {
	mod_iso_make_prepare
	mod_iso_make
	mod_iso_make_finish
}

##
### Tail: Model / Build ISO
################################################################################


################################################################################
### Head: Model / Build ISO / Overlay Profile
##

mod_iso_profile_overlay () {
	return 0
	mod_iso_profile_overlay_pacman_conf
	mod_iso_profile_overlay_packages_x86_64
	mod_iso_profile_overlay_locale
}

mod_iso_profile_overlay_pacman_conf () {
	cp -f ./asset/overlay/etc/pacman.conf ./profile/airootfs/etc/pacman.conf

	cp -f ./asset/overlay-build/pacman.conf ./profile/pacman.conf
}

mod_iso_profile_overlay_packages_x86_64 () {
	cat ./asset/overlay-build/packages.x86_64.part >> ./profile/packages.x86_64
}

mod_iso_profile_overlay_locale () {

	cp -f ./asset/overlay/etc/locale.conf ./profile/airootfs/etc/locale.conf
	
	#cp -f ./asset/overlay/etc/locale.gen ./profile/airootfs/etc/locale.gen
	

	mkdir -p ./profile/airootfs/etc/pacman.d/hooks

	cp -f ./asset/overlay/etc/pacman.d/hooks/40-locale-gen.hook ./profile/airootfs/etc/pacman.d/hooks/40-locale-gen.hook
}

##
### Tail: Model / Build ISO / Overlay Profile
################################################################################


################################################################################
### Head: Main
##
__main__ () {

	mod_signal_bind
	mod_iso_build

}

__main__
##
### Tail: Main
################################################################################




