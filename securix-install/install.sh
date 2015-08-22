#!/bin/bash

#: title: Securix GNU/Linux installer
#: file: install.sh
#: desc: Securix installation/build script
#: latest version: 'wget https://securix.org/install.sh'
#: howto: boot from gentoo minimal cd, download and execute this script
#: author: Martin Cmelik (cm3l1k1) - securix.org, security-portal.cz
#
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

f_check_arch() {
    # define arch and variables
    case "${HOSTTYPE}" in
        x86_64)
            ARCH="amd64"
            SUBARCH="amd64"
            KERNELPATH="x86_64"
            CHOSTS="x86_64-pc-linux-gnu"
            modprobe aes_x86_64
            ;;
            #    i386|i486|i586|i686)
            #        ARCH="x86"
            #        SUBARCH="i686"
            #        KERNELPATH="i386"
            #        CHOSTS="i686-pc-linux-gnu"
            #        ;;
        *)
            echo "ERROR: valid architecture not found - ${HOSTTYPE}"
            exit 1
            ;;
    esac
}

##############################################################################
#
# VARIABLES
#
# You can change any variable if you will define it before script execution (e.g. VAR1=A VAR2=B ./install.sh)
# Or import configuration file by ./install.sh --config=/path/to/file || --config=https://server/file
#
# It is a must for autobuild to change ROOT_PASSWORD, ROOT_PASSWORD2 and verify that default "System setup" fit your system
#
# VARIABLE=${VARIABLE:-"Default value"}
##############################################################################

f_define_vars() {
    # Set your http/s server here
    WEB_ROOT=${WEB_ROOT:-"http://superr4y.net"}
    #SECURIX_STAGE3BASEURL=${SECURIX_STAGE3BASEURL:-"https://mirror.securix.org/releases/${ARCH}/autobuilds/"}
    #SECURIX_STAGE3LATESTTXT=${SECURIX_STAGE3LATESTTXT:-"latest-stage3-${SUBARCH}-hardened.txt"}
    #SECURIX_PORTAGEFILE=${SECURIX_PORTAGEFILE:-"https://mirror.securix.org/releases/snapshots/current/portage-latest.tar.bz2"}

    # gentoo servers usually do not use https and if so, it is just self-signed certificate
    # Use Gentoo anyway
    GENTOO_STAGE3BASEURL=${GENTOO_STAGE3BASEURL:-"http://distfiles.gentoo.org/releases/${ARCH}/autobuilds/"}
    STAGE3LATESTTXT=${STAGE3LATESTTXT:-"latest-stage3-${SUBARCH}-hardened.txt"}
    GENTOO_PORTAGEFILE=${GENTOO_PORTAGEFILE:-"http://distfiles.gentoo.org/releases/snapshots/current/portage-latest.tar.bz2"}

    # TODO: Use git folder names and just set it as a http root 

    #SECURIX_FILES=${SECURIX_FILES:-"https://update.securix.org"}
    SECURIX_FILES="$WEB_ROOT"
    #SECURIX_FILESDR=${SECURIX_FILESDR:-"http://securix.sourceforge.net"}
    SECURIX_FILESDR="$WEB_ROOT"
    #SECURIX_SYSTEMCONF=${SECURIX_SYSTEMCONF:-"/install/conf.tar.gz"}
    SYSTEMCONF=${SYSTEMCONF:-"/system-config/conf.tar.gz"}
    #SECURIX_CHROOT=${SECURIX_CHROOT:-"/install/chroot.sh"}
    CHROOT=${CHROOT:-"/securix-install/chroot.sh"}
    KERNELCONFIG=${KERNELCONFIG:-"/system-config/etc/kernels/hardened-amd64.config"}
    GMIRROR=${GMIRROR:-"http://ftp.fi.muni.cz/pub/linux/gentoo/"}
    GPG_EXTRA_OPTS=${GPG_EXTRA_OPTS:-"-quiet"}
    CPUS="$(grep -c '^processor' /proc/cpuinfo)"
    MOPTS="$((CPUS + 1))"
    GENKERNEL=${GENKERNEL:-"--install --symlink --save-config --makeopts=-j${MOPTS} --kernname=securix --kernel-config=/hardened-kernel.config"}
    GRUBOPTS=${GRUBOPTS:-"vga=791 quiet"}
    SECURIXID="$(ifconfig -a | sha1sum | awk '{ print $1 }')"
    INTERFACES="$(ifconfig -a | grep -c eth)"
    INTERFACES_FOUND="$(ifconfig -a | grep -E '^*: ' | cut -d: -f1 | grep -vE '^lo')"
    LOGFILE=${LOGFILE:-"/root/securix-install.log"}
    LOCKFILE=${LOCKFILE:-"/root/securix.lock"}
    CHROOTOK=${CHROOTOK:-"/mnt/gentoo/chroot.ok"}
    CHROOTLOGFILE=${CHROOTLOGFILE:-"/chroot.log"}
    USER_PASSWORD=${USER_PASSWORD:-"pass${RANDOM}"}
    #"#
    txtred='\e[0;31m'
    txtblue='\e[1;34m'
    txtgreen='\e[0;32m'
    txtwhite='\e[0;37m'
    txtdefault='\e[00m'
    txtyellow='\e[0;33m'
    # partitioning
    PBOOTS=${PBOOTS:-"+256M"}
    DISKMIN=${DISKMIN:-"18000000000"}
    DISKOPTIM=${DISKOPTIM:-"38000000000"}
    BOOTOPTS=${BOOTOPTS:-"noauto,relatime,nodiratime"}
    ROOTOPTS=${ROOTOPTS:-"defaults,relatime,nodiratime"}
    USROPTS=${USROPTS:-"defaults,relatime,nodiratime,nodev"}
    HOMEOPTS=${HOMEOPTS:-"defaults,relatime,nodiratime,nodev,nosuid"}
    OPTOPTS=${OPTOPTS:-"defaults"}
    VAROPTS=${VAROPTS:-"defaults,relatime,nodiratime,nodev,nosuid,noexec"}
    PORTAGEOPTS=${PORTAGEOPTS:-"defaults,relatime,nodiratime,nodev,nosuid"}
    TMPOPTS=${TMPOPTS:-"defaults,relatime,nodiratime,nodev,nosuid,noexec"}

    #
    # System setup for autobuild
    #

    SECURIX_HOSTNAME=${SECURIX_HOSTNAME:-"securix"}
    # change root password, s3cur1x can't be used
    ROOT_PASSWORD=${ROOT_PASSWORD:-"s3cur1x"}
    ROOT_PASSWORD2=${ROOT_PASSWORD2:-"s3cur1x"}
    # default mail address for system notifications, better is group mail address
    ROOT_MAIL=${ROOT_MAIL:-root}
    # define mail server hostname, default is mail = based on MX records
    MAIL_HOST=${MAIL_HOST:-mail}
    # running under virtual? if not, default Securix kernel will be used in autobuild
    VIRTUAL=${VIRTUAL:-"yes"}
    # if so, possible options: VIRTUALBOX, KVM, XEN, VMWARE
    VIRTUALHOST=${VIRTUALHOST:-"VIRTUALBOX"}
    # specify device where to install Securix
    DEVICE=${DEVICE:-"/dev/sda"}
    # format destination DEVICE?
    DELETEDISK=${DELETEDISK:-"yes"}
    # use full disk encryption? (LUKS) cant be automated
    USELUKS=${USELUKS:-"no"}
    # do you want to setup bonding?
    BONDING=${BONDING:-"no"}
    # set only if BONDING is yes
    BONDINGMODE=${BONDINGMODE:-"1"}
    BONDINGSLAVE=${BONDINGSLAVE:-"eth0 eth1"}
    # Manual setup? no = DHCP
    NETMANUAL=${NETMANUAL:-"no"}
    # use DHCP?
    USEDHCP=${USEDHCP:-"yes"}
    # network interface name
    if [ "${INTERFACES}" -eq "1" ]; then
        NETETH="${INTERFACES_FOUND}"
    else
        NETETH=${NETETH:-"eth0"}
    fi
    # set all the rest only if NETMANUAL is "no"
    NETIP=${NETIP:-"192.168.100.100"}
    NETMASK=${NETMASK:-"255.255.255.0"}
    NETGATEWAY=${NETGATEWAY:-"192.168.100.1"}
    # primary and secondary DNS server
    NETDNS=${NETDNS:-"8.8.8.8"}
    NETDNS2=${NETDNS2:-"8.8.4.4"}
    # server domain
    NETDOMAIN=${NETDOMAIN:-"securix.local"}
    # primary and secondary NTP server
    NETNTP=${NETNTP:-"0.gentoo.pool.ntp.org"}
    NETNTP2=${NETNTP2:-"1.gentoo.pool.ntp.org"}

    # set to yes, if you want to load config file also during chroot execution
    CHROOTCONFIG=${CHROOTCONFIG:-"no"}
}

##############################################################################
#
# FUNCTIONS
#
##############################################################################

f_yesno() {
    #example: f_yesno "Are you sure?" variable
    if [ "${AUTOBUILD}" != "yes" ]; then
        local answer
        echo -ne "${txtblue}» Q: ${1} (yes/NO): ${txtdefault}"
        read answer
        case "${answer}" in
            y|Y|yes|YES|Yes) yesno="yes" ;;
            *) yesno="no" ;;
        esac
        if [ ! -z "${2}" ]; then
            eval "${2}"="${yesno}"
        fi
    else
        echo -e "AUTOBUILD: ${txtblue}» Q: ${1} ${2} ${txtdefault}"
    fi
}

f_getvar() {
    #example: f_getvar "Your name?" variable "default value"
    if [ "${AUTOBUILD}" != "yes" ]; then
        local answer
        echo -ne "${txtblue}» Q: ${1} ${txtdefault}"
        read answer
        #set default when null
        if [ -z "${answer}" ]; then
            local defaultvar=${3:?Error answer and default value is null}
            eval "${2}"="${3}"
        else
            eval "${2}"="${answer}"
        fi
    else
        echo -e "AUTOBUILD: ${txtblue}» Q: ${1} ${2} ${3} ${txtdefault}"
    fi
}

f_getpass() {
    #example: f_getpass "Service password:" variable "default value"
    if [ "${AUTOBUILD}" != "yes" ]; then
        local answer
        echo -ne "${txtblue}» ${1} ${txtdefault}"
        read -s -p "" answer
        f_msg newline
        #set default when null
        if [ -z "${answer}" ]; then
            local defaultvar=${3:?Error answer and default value is null}
            eval "${2}"="${3}"
        else
            eval "${2}"="${answer}"
        fi
    else
        echo -e "AUTOBUILD: ${txtblue}» ${1} ${txtdefault}"
    fi
}

f_msg() {
    #example: f_msg info "This is info message"
    case "${1}" in
        error) echo -e "${txtred}${2} ${txtdefault}" ;;
        warn) echo -e "${txtyellow}${2} ${txtdefault}" ;;
        info) echo -e "${txtgreen}${2} ${txtdefault}" ;;
        newline) echo "" ;;
        *) echo "${1} ${2}" ;;
    esac
}

f_download() {
    #usage: f_download $link $backup-link
    #example: f_download https://x.y.z/file.tgz https://mirror.x.y.z/file.tgz
    if [ -z "${1}" ]; then
        echo "--- Error: No URL provided"
    fi
    # propagate error code in pipelines
    set -o pipefail
    local downlink="${1}"
    local backuplink="${2}"
    local downfile="${downlink##*/}"
    local backupfile="${backuplink##*/}"
    local wgeterror="no"
    # remove parameters from link
    downfile="${downfile%%\?*}"
    backupfile="${backupfile%%\?*}"
    # remove previous files if any
    rm -f ${downfile} ${backupfile}
    echo "Downloading: ${downlink}"
    echo -n "Status:     "
    # wget version in gentoo minimal CD do not support PFS and https-only :(
    wget --timeout=30 --no-cache --progress=dot -O "${downfile}" "${downlink}" 2>&1 | grep --line-buffered "%" | \
        sed -u -e "s,\.,,g" | awk '{printf("\b\b\b\b%4s", $2)}'
    if [ "${?}" -ne "0" ]; then
        wgeterror="yes"
    fi
    echo " DONE"
    if [ -f "${downfile}" -a "${wgeterror}" = "no" ]; then
        downloaded="yes"
        return 0
    else
        wgeterror="no"
        if [ ! -z "${backuplink}" ]; then
            echo "Downloading from mirror: ${backuplink}"
            echo -n "Status:     "
            # https-only not used as Gentoo mirrors usually dont have SSL
            wget --timeout=30 --no-cache --progress=dot -O "${backupfile}" "${backuplink}" 2>&1 | grep --line-buffered "%" | \
                sed -u -e "s,\.,,g" | awk '{printf("\b\b\b\b%4s", $2)}'
            if [ "${?}" -ne "0" ]; then
                wgeterror="yes"
            fi
            echo " DONE"
            if [ -f "${backupfile}" -a "${wgeterror}" = "no" ]; then
                downloaded="yes"
                return 0
            else
                downloaded="no"
                return 1
            fi
        else
            downloaded="no"
            return 1
        fi
    fi
}

f_dmesg() {
    #example: f_dmesg ttyS USERSERIAL
    #if string exist 2nd parameter have value "yes"
    grep "${1}" /var/log/dmesg > /dev/null
    if [ "${?}" -eq "0" ]; then
        export "${2}"="yes"
    else
        export "${2}"="no"
    fi
}

f_grep() {
    #example: f_grep " ept " /proc/cpuinfo EPTFLAG
    #if string exist 3rd parameter have value "yes"
    grep "${1}" "${2}" > /dev/null
    if [ $? -eq 0 ]; then
        export $3="yes"
    else
        export $3="no"
    fi
}

f_validip() {
    #example: f_validip 1.2.3.4
    #validate IP address format
    ip="$1"
    local IFS='.'
    # set IP as positional parameter for each oktet
    set -- $ip
    # check that IP contain only numbers and dots
    if [[ "$ip" =~ "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" ]]; then

        # check each position parameter
        if [[ ${1} -le 255 && ${2} -le 255 && ${3} -le 255 && ${4} -le 255 ]]; then
            VALIDIP="yes"
        else
            VALIDIP="no"
        fi
    else
        VALIDIP="no"
    fi
}

# end script in case of error
# exception: if statement, until and while loop, logical AND (&&) or OR (||)
# trap also those exit signals: 1/HUP, 2/INT, 3/QUIT, 15/TERM, ERR
trap exit_on_error 1 2 3 15 ERR

exit_on_error() {
    local exit_status="${1:-$?}"
    echo -e "${txtred}»»» Exiting ${0} with status: ${exit_status} ${txtdefault}"
    if [ "${DISKSYNC}" != "ok" ]; then
      echo -e "${txtred}»»» If you have problem with partitioning, please reboot server${txtdefault}"
    fi
    rm -f "${LOCKFILE}"
    exit "${exit_status}"
}

##############################################################################
#
# BUILD FUNCTIONS
#
##############################################################################

f_banner() {
    # banner
    clear
    echo -e "
   _________                                         __
  /   _____/   ____    ______   __  __  _________   |__| ___  ___
  \_____  \   / __ \  /  ____| |  ||  | \_  ___  \  |  | \  \/  /
  ______|  \ |  ___/  \  \___  |  ||  |  |  |_/  /  |  |  > || <
 /_________/  \_____\  \_____| |_____/   |__| |__\  |__| /__/\__\\

\n
::: Securix GNU/Linux installer
::: www.securix.org
::: www.security-portal.cz
"
    sleep 1
    f_msg info "» Starting..."
    f_msg newline
    sleep 1
}

f_basic_check() {
    # check permissions
    if [ "${EUID}" -ne "0" ]; then
        f_msg error "This script must be run as root."
        exit_on_error
    fi

    # lockfile
    if [ -f "${LOCKFILE}" ]; then
        f_msg error "It seems that there is already running Securix installer... exiting"
        f_msg info "If youre sure what youre doing, you can execute: rm -f ${LOCKFILE}"
        exit_on_error
    else
        touch "${LOCKFILE}"
    fi
}

f_check_networking() {
    wget --timeout=30 --delete-after -q http://www.google.com || google_check="${?}"
    if [ ! -z "${google_check}" ]; then
        f_msg error "ERROR: Unable to contact google.com!"
        f_msg info  "Yes, Google can be down, but Occam's Razor would suggest that you have problem with your Internet connectivity."
        f_msg info " --- Please setup http_proxy or fix network issue"
        exit_on_error
    fi
}

f_installer_signature() {
    # verifying securix installer
    if [ "${SKIPSIGN}" != "yes" ]; then
        f_msg warn "Verifying signature of installation script..."
        f_download "${SECURIX_FILES}/install/install.sh.sign" "${SECURIX_FILESDR}/install/install.sh.sign"
        f_download "${SECURIX_FILES}/certificates/securix-codesign.pub" "${SECURIX_FILESDR}/certificates/securix-codesign.pub"
        openssl dgst -sha512 -verify securix-codesign.pub -signature install.sh.sign "${BASH_SOURCE}"
        if [ "${?}" -ne "0" ]; then
            f_msg error "Verification failed!"
            f_msg warn "If YOU modified install script, you can skip this check by ./install.sh --skipsign"
            exit_on_error
        fi
        f_msg newline
    else
        f_msg warn "Skipping install script signature check (not recommended)"
    fi
    f_msg newline
}

f_banner_system_setup() {
    f_msg info "-:-:[ Please setup system details ]:-:-"
    f_msg newline
}

f_ask_hostname() {
    # setup hostname
    f_getvar "Hostname [default: ${SECURIX_HOSTNAME}]: " SECURIX_HOSTNAME "${SECURIX_HOSTNAME}"
}

f_ask_root_pass() {
    # setup root password
    unset passmatch
    until [ "${passmatch}" = "ok" ]; do
    f_getpass "Please enter ROOT password/phrase: " ROOT_PASSWORD "${ROOT_PASSWORD}"
    f_getpass "Please enter ROOT password/phrase one more time: " ROOT_PASSWORD2 "${ROOT_PASSWORD2}"

    if [ "${ROOT_PASSWORD}" = "${ROOT_PASSWORD2}" ]; then
        if [ "${ROOT_PASSWORD}" != "s3cur1x" ]; then
            passmatch="ok"
        else
            f_msg warn "Do not use default root password! Create your own and save it in KeePass (for example)"
        fi
    else
        f_msg warn "Password mismatch! Try it one more time..."
        f_msg newline
    fi
    done
}

f_ask_root_mail() {
    # setup root mail address
    f_getvar "MAIL address or better group for system notifications [default: ${ROOT_MAIL}]: " ROOT_MAIL "${ROOT_MAIL}"
    f_msg info "Now please specify outgoing mail server and username/password if needed"
    f_msg info "Example format: smtp.gmail.com:587 mymail@gmail.com mypassword"
    f_getvar "MAIL server/gateway [default: ${MAIL_HOST}]: " MAIL_HOST "${MAIL_HOST}"
}

f_check_serial() {
    # check serial
    f_dmesg ttyS USERSERIAL
    if [ "${USERSERIAL}" = "yes" ]; then
        f_msg info "-- Serial console found. I will provide you serial terminal access"
        SYSTEMPACKAGE="${SYSTEMPACKAGE} minicom setserial"
    fi
}

f_check_dmraid() {
    # check dmraid
    # if RAID is not recognized in /dev/mapper is "control" only
    DMRAIDCOUNT=$(ls /dev/mapper | wc -l)
    if [ "${DMRAIDCOUNT}" -gt "1" ]; then
        f_msg info "-- RAID device found. I will install basic tools and include support in initramfs"
        SYSTEMPACKAGE="${SYSTEMPACKAGE} dmraid"
        GENKERNEL="${GENKERNEL} --dmraid"
        GENKERNELUSE="${GENKERNELUSE} dmraid"
    fi
}

f_check_virtual() {
    # check virtual environment
    f_dmesg "virtual" VIRTUAL
    if [ "${VIRTUAL}" = "yes" ]; then
        f_msg info "-- It seems that installer is running under virtual machine (VirtualBox, VMware, ...)"
        f_yesno "Securix have pre-defined kernel setup for VM's. Do you want to use it?" VIRTUAL
        if [ "${VIRTUAL}" = "yes" ]; then
            f_getvar "Which VM host are you using? 1) VirtualBox 2) KVM/QEMU 3) Xen 4) VMware 5) None of them : " VIRTUALHOST
            case "${VIRTUALHOST}" in
                1) VIRTUALHOST="VIRTUALBOX" ;;
                2) VIRTUALHOST="KVM" ;;
                3) VIRTUALHOST="XEN" ;;
                4) VIRTUALHOST="VMWARE" ;;
                *)
                    f_msg warn "-- Only provided VM's are supported"
                    f_msg info "-- You will be asked to setup kernel configuration manually during installation"
                    VIRTUAL="no"
                    unset VIRTUALHOST
                    ;;
            esac
            if [ ! -z "${VIRTUALHOST}" ]; then
                echo "--- Selected: ${VIRTUALHOST}"
            fi
        fi
    else
        f_msg info "-- In few minutes you will be asked to manually setup kernel configuration"
        f_msg info "-- It is almost same as Securix pre-defined setup for VM's, but you need to check at least CPU, HDD, Network"
    fi
}

f_ask_network() {
    # setup networking
    if [ "${INTERFACES}" -ne "1" ]; then
        f_yesno "Multiple ethernets found. Do you want setup bonding?" BONDING
    fi

    if [ -z "${BONDING}" -o "${BONDING}" = "no" ]; then
        BONDING="no"
        f_yesno "Do you want setup networking manually? [NO is DHCP]" NETMANUAL

        if [ "${NETMANUAL}" = "no" ]; then

            # dhcp
            if [ "${INTERFACES}" -eq "1" ]; then
                f_msg info "-- Interfaces found in system: ${INTERFACES_FOUND}"
                f_getvar "Specify interface [default: ${INTERFACES_FOUND}]: " NETETH "${INTERFACES_FOUND}"
                USEDHCP="yes"
            else
                f_msg info "-- Interfaces found in system: ${INTERFACES_FOUND}"
                f_getvar "Specify interface [default: ${NETETH}]: " NETETH "${NETETH}"
                USEDHCP="yes"
            fi
        else

            # manual
            f_msg info "Current ifconfig:"
            ifconfig | grep -B 1 inet | grep -vE '127.0.0.1|Loopback'
            f_msg info "Routing:"
            route -n | grep -vE 'Kernel|127.0.0.1'
            f_msg newline
            f_getvar "Specify interface [default: ${NETETH}]: " NETETH "${NETETH}"
            f_getvar "Specify IP address [${NETIP}]: " NETIP "${NETIP}"
            f_getvar "Specify netmask [${NETMASK}]: " NETMASK "${NETMASK}"
            f_getvar "Specify default gateway [${NETGATEWAY}]: " NETGATEWAY "${NETGATEWAY}"
            f_getvar "Specify primary DNS server [${NETDNS}]: " NETDNS "${NETDNS}"
            f_getvar "Specify secondary DNS server [${NETDNS2}]: " NETDNS2 "${NETDNS2}"
            f_getvar "Specify domain name [${NETDOMAIN}]: " NETDOMAIN "${NETDOMAIN}"
            f_getvar "Specify primary NTP server [${NETNTP}]" NETNTP "${NETNTP}"
            f_getvar "Specify secondary NTP server [${NETNTP2}" NETNTP2 "${NETNTP2}"
        fi
    fi

    # bonding
    if [ "${BONDING}" = "yes" ]; then
        SYSTEMPACKAGE="${SYSTEMPACKAGE} net-misc/ifenslave"
        f_yesno "Do you want use defaults (DHCP on bond0, slaves eth0+eth1, mode active-backup)?" USEDHCP
        if [ "${USEDHCP}" = "no" ]; then
            f_msg info "Current ifconfig:"
            ifconfig | grep -B 1 inet | grep -vE '127.0.0.1|Loopback'
            f_msg info "Routing:"
            route -n | grep -vE 'Kernel|127.0.0.1'
            f_msg newline
            NETETH="bond0"
            f_msg info "Please select bonding mode number: 0-balance-rr, 1-active-backup, 2-balance-xor, 3-broadcast, 4-802.3ad, 5-balance-tlb, 6-balance-alb"
            f_msg info "Recommended: 1-Active/Backup (+fault tolerance) OR 0-Round Robin (+load balancing, +fault tolerance, -need setup etherchannel on switch)"
            f_getvar "Specify bonding mode [default: ${BONDINGMODE}]: " BONDINGMODE "${BONDINGMODE}"
            f_getvar "Specify bonding slave interfaces [${BONDINGSLAVE}]: " BONDINGSLAVE "${BONDINGSLAVE}"
            f_getvar "Specify IP address [${NETIP}]: " NETIP "${NETIP}"
            f_getvar "Specify netmask [${NETMASK}]: " NETMASK "${NETMASK}"
            f_getvar "Specify default gateway [${NETGATEWAY}]: " NETGATEWAY "${NETGATEWAY}"
            f_getvar "Specify primary DNS server [${NETDNS}]: " NETDNS "${NETDNS}"
            f_getvar "Specify secondary DNS server [${NETDNS2}]: " NETDNS2 "${NETDNS2}"
            f_getvar "Specify domain name [${NETDOMAIN}]: " NETDOMAIN "${NETDOMAIN}"
            f_getvar "Specify primary NTP server [${NETNTP}]" NETNTP "${NETNTP}"
            f_getvar "Specify secondary NTP server [${NETNTP2}" NETNTP2 "${NETNTP2}"
        fi
    fi
}

f_ask_disk_encryption() {
    # setup disk encryption
    f_msg warn "-- Do you want setup full disk encryption (LUKS)?"
    f_msg warn "-- If so, you need physical or console access every time when server will be rebooted."
    f_yesno "Are you OK with that?" USELUKS
}

f_format_boot_swap() {
    # create partitions
    f_msg info "-- We must setup partitions. All data on destination device will be deleted!!"
    f_getvar "Please specify device which should be used for Securix installation [default: ${DEVICE}]: " DEVICE "${DEVICE}"

    echo "--- Selected device: ${DEVICE}"

    if [ ! -b "${DEVICE}" ]; then
        f_msg error "Error: ${DEVICE} is not block device"
        exit_on_error
    fi

    f_msg info "### Is it this one?"
    echo "---"
    fdisk -l "${DEVICE}" | grep -E "Disk|${DEVICE}"
    echo "---"

    f_yesno "WARNING: ALL DATA WILL BE LOST! Are you OK with that?" DELETEDISK
    if [ "${DELETEDISK}" = "no" ]; then
        echo "Exiting before disk format..."
        exit_on_error
    fi

    f_msg info "###-### Step: Sizing swap ---"
    MEMSIZE=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    if [ "${MEMSIZE}" -ne "${MEMSIZE}" 2>/dev/null ]; then
        echo "MEMSIZE is not integer, value: ${MEMSIZE}"
        exit_on_error
    fi

    SWAPCOUNT="$((MEMSIZE * 2))"
    if [ "${SWAPCOUNT}" -lt "4200000" ]; then
        PSWAPS="+2G"
        SWAPSIZE="2048000000"
    elif [ "${SWAPCOUNT}" -ge "4200000" ] && [ "${SWAPCOUNT}" -le "8200000" ]; then
            PSWAPS="+4G"
            SWAPSIZE="4096000000"
        elif [ "${SWAPCOUNT}" -gt "8200000" ]; then
                PSWAPS="+8G"
                SWAPSIZE="8192000000"
    fi
}

f_size_logical_volumes() {
    f_msg info "###-### Step: Sizing logical volumes ---"
    DISKSIZE="$(fdisk -l "${DEVICE}" | grep "Disk ${DEVICE}" | awk '{print $5}')"
    if [ "${DISKSIZE}" -ne "${DISKSIZE}" 2>/dev/null ]; then
        echo "DISKSIZE is not integer, value: ${DISKSIZE}"
        exit_on_error
    fi

    DISKSIZE="$((DISKSIZE - SWAPSIZE))"

    if [ "${DISKSIZE}" -lt "${DISKMIN}" ]; then
        VOLUMES="NOVOLUMES"
        ROOTTYPE="83"
        USELVM="no"
    elif [ "${DISKSIZE}" -ge "${DISKMIN}" ] && [ "${DISKSIZE}" -le "${DISKOPTIM}" ]; then
            VOLUMES="MINVOLUMES"
            ROOTTYPE="8e"
            USELVM="yes"
        elif [ "${DISKSIZE}" -gt "${DISKOPTIM}" ]; then
                VOLUMES="OPTIMVOLUMES"
                ROOTTYPE="8e"
                USELVM="yes"
    fi
}

f_create_partitions() {
    f_msg info "###-### Step: Deleting partitions ---"
    # fix bug when kernel uses old table
    cat > fdisk.in << !EOF
o
w
!EOF

    bash -c "fdisk ${DEVICE} < fdisk.in" >> "${LOGFILE}" 2>&1

    # setup config for fdisk
    cat > fdisk.in << !EOF
n
p
1

$PBOOTS
n
p
2

$PSWAPS
t
2
82
n
p
3

t
3
$ROOTTYPE

w
q
!EOF

    f_msg info "###-### Step: Creating partitions ---"
    bash -c "fdisk ${DEVICE} < fdisk.in" >> "${LOGFILE}" 2>&1
    # wait for successful disk sync
    sleep 3
    DISKSYNC="ok"

    f_msg info "###-### Step: Creating boot and swap filesystems ---"
    mkfs.ext2 -q "${DEVICE}1"
    mkswap "${DEVICE}2" > /dev/null
    swapon "${DEVICE}2"
}

f_setup_disk_encryption() {
    if [ "${USELUKS}" = "yes" ]; then
        f_msg warn "--- Encrypting disk, please save your passphrase on secure place!"
        f_msg warn "--- Use KeePass or something else, because when you forget passphrase NOBODY will be able to recover data!"
        f_msg warn "--- Type YES if youre OK with that"
        cryptsetup -c aes-xts-plain -y -s 512 -h whirlpool luksFormat "${DEVICE}3"
        f_msg warn "--- Type selected passphrase again to open encrypted partition"
        cryptsetup luksOpen "${DEVICE}3" root
        ROOTPV="/dev/mapper/root"
        MAPPER="/dev/mapper/vg-"
        GENKERNEL="${GENKERNEL} --luks"
        GENKERNELUSE="${GENKERNELUSE} cryptsetup"
        SYSTEMPACKAGE="${SYSTEMPACKAGE} cryptsetup"
    else
        ROOTPV="${DEVICE}3"
        MAPPER="/dev/vg/"
    fi
}

f_setup_volumes() {
    case "${VOLUMES}" in
        NOVOLUMES)
            f_msg info "###-### Step: Creating root filesystem ---"
            mkfs.ext4 -q "${ROOTPV}"
            ROOTVG="${ROOTPV}"
            f_msg info "###-### Step: Mounting partitions ---"
            mount "${ROOTVG}" /mnt/gentoo
            mkdir /mnt/gentoo/boot
            mount "${DEVICE}1" /mnt/gentoo/boot
            ;;
        MINVOLUMES)
            f_msg info "###-### Step: Creating logical volumes ---"
            pvcreate -ff -y "${ROOTPV}"
            vgcreate vg "${ROOTPV}"
            lvcreate --size 1G --name root vg
            lvcreate --size 5G --name usr vg
            lvcreate --size 2G --name home vg
            lvcreate --size 5G --name var vg
            lvcreate --size 1G --name opt vg
            lvcreate --size 1G --name tmp vg
            vgchange -ay
            ROOTVG="${MAPPER}root"
            ;;
        OPTIMVOLUMES)
            f_msg info "###-### Step: Creating logical volumes ---"
            pvcreate -ff -y "${ROOTPV}"
            vgcreate vg "${ROOTPV}"
            lvcreate --size 3G --name root vg
            lvcreate --size 10G --name usr vg
            lvcreate --size 5G --name home vg
            lvcreate --size 10G --name var vg
            lvcreate --size 5G --name opt vg
            lvcreate --size 2G --name tmp vg
            vgchange -ay
            ROOTVG="${MAPPER}root"
            ;;
        *)
            f_msg error "Problem when setup volumes, value: ${VOLUMES}"
            exit_on_error
            ;;
    esac
}

f_setup_lvm() {
    if [ "${USELVM}" = "yes" ]; then
        GENKERNEL="${GENKERNEL} --lvm"
        SYSTEMPACKAGE="${SYSTEMPACKAGE} lvm2"
        f_msg info "###-### Step: Creating filesystems on logical volumes ---"
        for volumes in root usr home var opt tmp; do
            echo "  Creating ext4 on ${MAPPER}${volumes}"
            mkfs.ext4 -q "${MAPPER}${volumes}"
        done
        f_msg info "###-### Step: Mounting logical volumes ---"
        mount "${ROOTVG}" /mnt/gentoo
        mkdir /mnt/gentoo/boot
        mount "${DEVICE}1" /mnt/gentoo/boot
        for mountpoint in usr home opt var tmp; do
            mkdir "/mnt/gentoo/${mountpoint}"
            mount "${MAPPER}${mountpoint}" "/mnt/gentoo/${mountpoint}"
        done
    fi
}

f_setup_gentoo_gpg() {

    # initiate GPG environment
    f_msg info "###-### Step: Importing Gentoo GPG keys ---"
    f_download "${SECURIX_FILES}/certificates/gentoo-gpg.pub" "${SECURIX_FILESDR}/certificates/gentoo-gpg.pub"
    f_download "${SECURIX_FILES}/certificates/gentoo-gpg-autobuild.pub" "${SECURIX_FILESDR}/certificates/gentoo-gpg-autobuild.pub"
    mkdir /etc/portage/gpg
    chmod 700 /etc/portage/gpg
    gpg ${GPG_EXTRA_OPTS} --homedir /etc/portage/gpg --import gentoo-gpg.pub
    gpg ${GPG_EXTRA_OPTS} --homedir /etc/portage/gpg --import gentoo-gpg-autobuild.pub
    gpg ${GPG_EXTRA_OPTS} --homedir /etc/portage/gpg --fingerprint DCD05B71EAB94199527F44ACDB6B8C1F96D8BF6D
    gpg ${GPG_EXTRA_OPTS} --homedir /etc/portage/gpg --fingerprint 13EBBDBEDE7A12775DFDB1BABB572E0E2D182910
}

f_setup_stage3() {
    # changing context
    cd /mnt/gentoo
    # TODO: deal with signatures later

    # download stage3
    f_msg info "###-### Step: Downloading hardened stage ---"
    f_download "${GENTOO_STAGE3BASEURL}${STAGE3LATESTTXT}"

    # find path to latest stage3
    STAGE3LATESTFILE="$(grep -v '#' "${STAGE3LATESTTXT}")"
    # remove size information from path (example: 20150108/hardened/stage3-amd64-hardened-20150108.tar.bz2 188195929)
    STAGE3LATESTFILE=${STAGE3LATESTFILE%% *}
    # and download it
    f_download "${GENTOO_STAGE3BASEURL}${STAGE3LATESTFILE}"
    statusd="${?}"
    f_download "${GENTOO_STAGE3BASEURL}${STAGE3LATESTFILE}.DIGESTS.asc"

    # verify stage3 GPG
    # Example link:
    #   http://distfiles.gentoo.org/releases/amd64/autobuilds/20150108/hardened/stage3-amd64-hardened-20150108.tar.bz2.DIGESTS.asc
    # Backup for historic purposes:
    #   http://www.webcitation.org/6VVeYAc6e
    # It is a gnupg clearsigned file. Using --verify is inappropriate here.
    # Because gnupg ignores all text before and after the clearsigned text and
    # still exit 0. Malicious extraneous text confuse grep below. Therefore
    # using --verify, which extracts the clearsigned text only.
    # stdout: clear text that was clearsigned, therefore redirected to temp file.
    # stderr: gpg status messages (gpg: Signature made etc.)
    # exit code: non-zero if it cannot be verified, otherwise 0.
    f_msg info "###-### Step: Verifying Stage3 GPG signature"
    gpg ${GPG_EXTRA_OPTS} --homedir /etc/portage/gpg --output "stage3latestfile_clear_text" --decrypt "${STAGE3LATESTFILE##*/}.DIGESTS.asc"
    if [ "${?}" -ne "0" ]; then
        f_msg error "Gentoo GPG signature of Stage3 file do not match !!"
        #exit_on_error
    fi

    # check SHA512
    STAGE3SUM="$(sha512sum "${STAGE3LATESTFILE##*/}")"
    grep "${STAGE3SUM}" "stage3latestfile_clear_text" >/dev/null
    statusc="${?}"
    if [ "${statusd}" -ne "0" -o "${statusc}" -ne "0" ]; then
        f_msg error "ERROR: There was problem with download or checksum of stage3 file. Exit codes: "
        f_msg warn "download: ${statusd} checksum: ${statusc}"
        #exit_on_error
    else
        echo "-- SHA512 checksum: OK"
    fi
    rm -f stage3latestfile_clear_text

    f_msg info "###-### Step: Extracting stage ---"
    tar xjpf "${STAGE3LATESTFILE##*/}" --checkpoint=.1000
    echo " DONE"
    rm -f "${STAGE3LATESTFILE##*/}" "${STAGE3LATESTTXT}" *.CONTENTS *.asc
}

f_setup_portage() {
    # changing context
    cd /mnt/gentoo

    # download portage
    # portage is GPG verified
    f_msg info "###-### Step: Downloading Portage ---"
    f_download "${SECURIX_PORTAGEFILE}" "${GENTOO_PORTAGEFILE}"
    statusd="${?}"
    f_download "${SECURIX_PORTAGEFILE}.md5sum" "${GENTOO_PORTAGEFILE}.md5sum"
    f_download "${SECURIX_PORTAGEFILE}.gpgsig" "${GENTOO_PORTAGEFILE}.gpgsig"
    # verify portage GPG
    gpg --homedir /etc/portage/gpg --verify "${SECURIX_PORTAGEFILE##*/}.gpgsig" "${SECURIX_PORTAGEFILE##*/}"
    if [ "${?}" -ne "0" ]; then
        f_msg error "Gentoo GPG signature of Portage file do not match !!"
        #exit_on_error
    fi

    # check MD5
    md5sum --status -c "${SECURIX_PORTAGEFILE##*/}.md5sum"
    statusc="${?}"
    if [ "${statusd}" -ne "0" -o "${statusc}" -ne "0" ]; then
        f_msg error "ERROR: There was problem with download or checksum of Portage. Exit codes: "
        f_msg warn "download: ${statusd} checksum: ${statusc}"
        exit_on_error
    else
        echo "-- MD5 checksum: OK"
    fi

    f_msg info "###-### Step: Extracting Portage ---"
    tar xmjf "${SECURIX_PORTAGEFILE##*/}" -C /mnt/gentoo/usr --checkpoint=.1000
    echo " DONE"
    rm -f "${SECURIX_PORTAGEFILE##*/}" *.md5sum *.gpgsig
}

f_download_securix_conf() {
    f_msg info "###-### Step: Downloading Securix system configuration ---"
    f_download "${SECURIX_FILES}${SECURIX_SYSTEMCONF}" "${SECURIX_FILESDR}${SECURIX_SYSTEMCONF}"
}

f_download_chroot() {
    f_msg info "###-### Step: Downloading CHROOT script ---"
    f_download "${SECURIX_FILES}${SECURIX_CHROOT}" "${SECURIX_FILESDR}${SECURIX_CHROOT}"
}

f_download_hardened() {
    f_msg info "###-### Step: Downloading hardened kernel config ---"
    if [ "${VIRTUAL}" != "yes" -a "${AUTOBUILD}" != "yes" ]; then
        GENKERNEL="${GENKERNEL} --menuconfig"
    fi

    f_download "${SECURIX_FILES}${KERNELCONFIG}" "${SECURIX_FILESDR}${KERNELCONFIG}"
    mv "${KERNELCONFIG##*/}" hardened-kernel.config
}

f_verify_signature() {
    f_msg info "###-### Step: Downloading SHA512 list ---"
    f_download "${SECURIX_FILES}/install/sha512.hash" "${SECURIX_FILESDR}/install/sha512.hash"
    f_download "${SECURIX_FILES}/install/sha512.hash.sign" "${SECURIX_FILESDR}/install/sha512.hash.sign"

    f_msg info "###-### Step: Computing checksum ---"
    grep -E "chroot.sh|conf.tar.gz" sha512.hash > checksum
    shasum -a 512 -c checksum >/dev/null
    if [ "${?}" -eq "0" ]; then
        f_msg info "--- SHA512 checksum: OK"
        rm -f checksum
    else
        f_msg error "--- Problem when computing checksum of Securix files!!"
        grep -E "chroot.sh|conf.tar.gz" sha512.list && shasum -a 512 chroot.sh conf.tar.gz
        #exit_on_error
    fi

    f_msg info "###-### Step: Verifying Securix files signature ---"
    f_download "${SECURIX_FILES}/certificates/securix-codesign.pub" "${SECURIX_FILESDR}/certificates/securix-codesign.pub"
    openssl dgst -sha512 -verify securix-codesign.pub -signature sha512.hash.sign sha512.hash
}

f_setup_makeconf() {
    f_msg info "###-### Step: Configuring base system ---"
    # delete default file, as we need directory
    rm -f /mnt/gentoo/etc/portage/make.conf
    # /etc/portage/make.conf/00_securix_make.conf
    mkdir -p /mnt/gentoo/etc/portage/make.conf/
    cat > /mnt/gentoo/etc/portage/make.conf/00_securix_make.conf << !EOF

#: title: Securix GNU/Linux make.conf
#: file: /etc/portage/make.conf/00_securix_make.conf
#: author: Martin Cmelik (cm3l1k1) - securix.org, security-portal.cz
#
# Do not make any changes in this file. Create new in /etc/portage/make.conf/ for customization
#
# Please consult /usr/share/portage/config/make.conf.example for a more
# detailed example.
#

ACCEPT_KEYWORDS="${ARCH}"
CFLAGS="-march=native -O2 -fforce-addr -pipe"
CXXFLAGS="\${CFLAGS}"
CHOST="${CHOSTS}"
MAKEOPTS="-j${MOPTS}"
USE="-X -kde -gnome -qt4 -gtk -suid -jit -thin hardened pic pax_kernel chroot secure-delete ncurses symlink bash-completion ldap gnutls ssl crypt cryptsetup tcpd pam xml perl python snmp unicode jpeg png vim-syntax mmx readline"
FEATURES="sandbox sfperms strict buildpkg userfetch parallel-fetch"
LINGUAS="en"
CONFIG_PROTECT="/etc"
GENTOO_MIRRORS="${GMIRROR}"
PORTAGE_NICENESS=10
# this option will unmask packages automatically, use with caution
#EMERGE_DEFAULT_OPTS="--autounmask-write"
#PORTAGE_RSYNC_EXTRA_OPTS="--quiet"

!EOF
}

f_setup_proxies() {
    # set http_proxy if used
    if [ ! -z "${http_proxy}" ]; then
        echo "# user proxy setup is done by /etc/profile.d/sx-proxy.sh" >> /mnt/gentoo/etc/portage/make.conf/00_securix_make.conf
        echo "http_proxy=\"${http_proxy}\"" >> /mnt/gentoo/etc/portage/make.conf/00_securix_make.conf
        echo "https_proxy=\"${http_proxy}\"" >> /mnt/gentoo/etc/portage/make.conf/00_securix_make.conf
        echo "ftp_proxy=\"${http_proxy}\"" >> /mnt/gentoo/etc/portage/make.conf/00_securix_make.conf
        echo "RSYNC_PROXY=\"${http_proxy}\"" >> /mnt/gentoo/etc/portage/make.conf/00_securix_make.conf
    fi
}

f_setup_dns() {
    # DNS
    if [ "${USEDHCP}" = "no" ]; then
        echo "domain ${NETDOMAIN}" > /etc/resolv.conf
        echo "nameserver ${NETDNS}" >> /etc/resolv.conf
        echo "nameserver ${NETDNS2}" >> /etc/resolv.conf
        cp -L /etc/resolv.conf /mnt/gentoo/etc/
    else
        cp -L /etc/resolv.conf /mnt/gentoo/etc/
    fi
}

f_setup_hostname() {
    # hostname
    cat > /mnt/gentoo/etc/conf.d/hostname << !EOF
hostname="${SECURIX_HOSTNAME}"
!EOF

    cat >> /mnt/gentoo/etc/hosts << !EOF
${NETIP} ${SECURIX_HOSTNAME}
!EOF
}

f_setup_release() {
    # /etc/securix-release
    cat > /mnt/gentoo/etc/securix-release << !EOF
Securix GNU/Linux - secured linux by default
www.securix.org
SECURIXVERSION=""
!EOF
}

f_setup_fstab() {
    # /etc/fstab
    if [ "${USELVM}" = "no" ]; then
        cat > /mnt/gentoo/etc/fstab << !EOF
${DEVICE}1		/boot		ext2		${BOOTOPTS}	1 2
${ROOTPV}		/		ext4		${ROOTOPTS}	0 1
${DEVICE}2		none		swap		sw		0 0
/dev/cdrom		/mnt/cdrom	auto		noauto,ro	0 0

proc                    /proc           proc            defaults        0 0
!EOF
    else
        cat > /mnt/gentoo/etc/fstab << !EOF
${DEVICE}1		/boot		 ext2		${BOOTOPTS}	1 2
${MAPPER}root 	        /		 ext4		${ROOTOPTS}	0 1
${DEVICE}2		none		 swap		sw		0 0
/dev/cdrom		/mnt/cdrom	 auto		noauto,ro	0 0
# Logical volumes
${MAPPER}usr            /usr             ext4           ${USROPTS}      0 2
${MAPPER}home           /home            ext4           ${HOMEOPTS}     0 2
${MAPPER}var            /var             ext4           ${VAROPTS}      0 2
${MAPPER}opt            /opt             ext4           ${OPTOPTS}      0 2
${MAPPER}tmp            /tmp             ext4           ${TMPOPTS}      0 2

tmpfs                   /var/tmp/portage tmpfs          ${PORTAGEOPTS}  0 0

proc                    /proc            proc           defaults        0 0
!EOF
    fi
}

f_setup_network() {
    # Network - /etc/conf.d/net
    if [ "${BONDING}" = "no" ]; then

        if [ "${USEDHCP}" = "yes" ]; then
            cat > /mnt/gentoo/etc/conf.d/net << EOF
config_${NETETH}="dhcp"
EOF
        else
            cat > /mnt/gentoo/etc/conf.d/net << EOF
config_${NETETH}="${NETIP} netmask ${NETMASK}"
routes_${NETETH}="default via ${NETGATEWAY}"
EOF
        fi
    fi
    if [ "${BONDING}" = "yes" ]; then

        if [ "${USEDHCP}" = "yes" ]; then
            cat >> /mnt/gentoo/etc/conf.d/net << !EOF
config_eth0="null"
config_eth1="null"
slaves_bond0="eth0 eth1"
mode_bond0="1"
miimon_bond0="100"
config_bond0="dhcp"
!EOF
        else
            for slave in ${BONDINGSLAVE}; do
                echo "config_${slave}=\"null\"" >> /mnt/gentoo/etc/conf.d/net
            done
            cat >> /mnt/gentoo/etc/conf.d/net << !EOF
slaves_${NETETH}="${BONDINGSLAVE}"
mode_${NETETH}="${BONDINGMODE}"
miimon_${NETETH}="100"
config_${NETETH}="${NETIP} netmask ${NETMASK}"
routes_${NETETH}="default gw ${NETGATEWAY}"
!EOF
        fi
    fi
}

f_setup_fail2ban_ip() {
    # define NETIP for fail2ban
    if [ "${USEDHCP}" = "yes" ]; then
        NETIP=$(ifconfig -a | grep inet | grep -v "127.0.0.1" | awk '{ print $2 }')
        f_validip "${NETIP}"
        if [ "${VALIDIP}" != "yes" ]; then
            unset NETIP
        fi
    fi
}

f_mount_proc_dev() {
    # mounting proc and dev
    mount -t proc none /mnt/gentoo/proc
    mount --rbind /dev /mnt/gentoo/dev
}

f_chroot_variables() {
    # chroot variables
    cat > /mnt/gentoo/chroot.var << !EOF
export ROOT_PASSWORD="${ROOT_PASSWORD}"
export ROOT_MAIL="${ROOT_MAIL}"
export MAIL_HOST="${MAIL_HOST}"
export USER_PASSWORD="${USER_PASSWORD}"
export NETETH="${NETETH}"
export NETIP="${NETIP}"
export DEVICE="${DEVICE}"
export KERNELPATH="${KERNELPATH}"
export http_proxy="${http_proxy}"
export ARCH="${ARCH}"
export ROOTPV="${ROOTPV}"
export USELVM="${USELVM}"
export USELUKS="${USELUKS}"
export GENKERNEL="${GENKERNEL}"
export MAPPER="${MAPPER}"
export SYSTEMPACKAGE="${SYSTEMPACKAGE}"
export MOPTS="${MOPTS}"
export USESERIAL="${USESERIAL}"
export GRUBOPTS="${GRUBOPTS}"
export BONDING="${BONDING}"
export NETNTP="${NETNTP}"
export NETNTP2="${NETNTP2}"
export SECURIXID="${SECURIXID}"
export SECURIX_HOSTNAME="${SECURIX_HOSTNAME}"
export VIRTUAL="${VIRTUAL}"
export VIRTUALHOST="${VIRTUALHOST}"
export AUTOBUILD="${AUTOBUILD}"
export GPG_EXTRA_OPTS="${GPG_EXTRA_OPTS}"
!EOF

    # if really needed, config file can change some variables in chroot
    if [ ! -z "${CONFIGFILE}" -a -r "${CONFIGFILE}" -a "${CHROOTCONFIG}" = "yes" ]; then
        cp ${CONFIGFILE} /mnt/gentoo/chroot.config
    fi
}

f_execute_chroot() {
    # execute chroot script
    f_msg info "###-### Step: Entering CHROOT environment ---"
    screen chroot /mnt/gentoo/ /bin/bash chroot.sh
    f_msg info "###-### Step: Exiting CHROOT environment ---"
}

f_check_chroot() {

    # copy chroot logfile to main one
    if [ -r "/mnt/gentoo${CHROOTLOGFILE}" ]; then
        cat "/mnt/gentoo${CHROOTLOGFILE}" >> "${LOGFILE}"
    fi

    # check chroot status
    if [ ! -f "${CHROOTOK}" ]; then
        f_msg error "CHROOT script didnt end successfully..."
        exit_on_error
    else
        # do cleanup
        rm -f "${CHROOTOK}"
        rm -f "/mnt/gentoo${CHROOTLOGFILE}"
        rm -f chroot.sh
        rm -f "${LOCKFILE}"
        rm -f sha512.hash
        rm -f sha512.hash.sign
        rm -f securix-codesign.pub
        rm -f gentoo-gpg.pub
        rm -f gentoo-gpg-autobuild.pub
    fi
}

f_umount_fs() {
    # umounting filesystems
    f_msg info "###-### Step: Umounting filesystems ---"
    cd

    if [ "${USELVM}" = "yes" ]; then
        for partitions in usr home opt var tmp; do
            umount "${MAPPER}${partitions}"
        done
        umount -l /mnt/gentoo{/boot,/proc,}
        vgchange -a n
    else
        umount -l /mnt/gentoo{/boot,/proc,}
    fi

    if [ "${USELUKS}" = "yes" ]; then
        cryptsetup luksClose root
    fi
}

f_banner_completed() {
    f_msg newline
    f_msg info "#########################################################"
    f_msg info "###-### Securix GNU/Linux installation COMPLETED! ###-###"
    f_msg info "#########################################################"
    f_msg newline
    if [ "${VOLUMES}" = "OPTIMVOLUMES" ]; then
        f_msg warn "Installer did not use entire disk space. Please resize required partition by \"securix config lvm\""
        f_msg newline
    fi
    f_msg warn "Don't forget that SSH will listen on port 55522. Use \"ssh securix@${SECURIX_HOSTNAME} -p 55522\" (root CANT login via SSH)."
    f_msg warn "Installer created user \"securix\" with password \"${USER_PASSWORD}\" who can SSH to server and make \"su -\" to switch under root."
    f_msg newline
    f_msg info "You can REBOOT to your new system. Visit www.securix.org for next steps."
}

f_debug(){
    local answer
    f_msg info "Press [d] for debug shell: "
    read answer

    if [ "${answer}" = "d"]; then
	f_msg info "Execute Debug Shell"
	/bin/bash
        f_msg info "Leave Debug Shell"
    fi
}

f_install_securix() {

    # execute all steps
    f_check_arch
    f_define_vars
    f_banner
    f_basic_check
    f_check_networking
    f_installer_signature
    f_banner_system_setup
    f_ask_hostname
    f_ask_root_pass
    f_ask_root_mail
    f_check_serial
    f_check_dmraid
    f_check_virtual
    f_ask_network
    f_ask_disk_encryption
    f_format_boot_swap
    f_size_logical_volumes
    # TODO: Add option to create partitions manual
    f_create_partitions
    f_setup_disk_encryption
    f_setup_volumes
    f_setup_lvm
    f_setup_gentoo_gpg
    f_setup_stage3
f_debug
    f_setup_portage
f_debug
    f_download_securix_conf
f_debug
    f_download_chroot
f_debug
    f_download_hardened
f_debug
    f_verify_signature
f_debug
    f_setup_makeconf
f_debug
    f_setup_proxies
    f_setup_dns
    f_setup_hostname
    f_setup_release
    f_setup_fstab
f_debug
    f_setup_network
    f_setup_fail2ban_ip
    f_mount_proc_dev
    f_chroot_variables
    f_execute_chroot
    f_check_chroot
    f_umount_fs
    f_banner_completed
}

##############################################################################
#
# MAIN
#
##############################################################################

f_parse_cmd() {
    # unset command line variables
    unset AUTOBUILD CONFIGFILE SKIPSIGN SXDISK

    # parse command line arguments (if any)
    for argument in "${@}"; do
        case "${argument}" in
            -a|--auto|--autobuild)
                # autobuild mode without questions, please verify default variables
                # use it together with -c or -s as at least root password must be changed
                if [ "${ROOT_PASSWORD}" = "s3cur1x" ]; then
                    f_msg error "--- Change root password variable first!"
                    # do not continue and exit
                    exit
                fi
                AUTOBUILD="yes"
                ;;
            "-c="*|"--conf="*|"--config="*)
                # load variables/setup from different file
                CONFIGFILE="${argument#*=}"
                f_msg info "Sourcing configuration file: ${CONFIGFILE}"
                if [ -r "${CONFIGFILE}" ]; then
                    source "${CONFIGFILE}"
                else
                    f_download "${CONFIGFILE}"
                    source "${CONFIGFILE##*/}"
                fi
                ;;
            -s|--skip|--skipsign)
                # if you must modify install script, use this option
                # it will skip script signature verification
                SKIPSIGN="yes"
                ;;
            --mountlvm)
                # for debug purposes or when you forget root password
                # mount Securix LVM partitions
                f_getvar "Please specify disk with Securix installation (example: /dev/sda): " SXDISK "/dev/sda"
                f_msg info "--- Scanning for volume groups"
                vgscan
                vgchange -a y
                f_msg info "--- Mounting /"
                mount /dev/vg/root /mnt/gentoo
                for mountpoint in usr home opt var tmp; do
                    f_msg info "--- Mounting /${mountpoint}"
                    mount "/dev/vg/${mountpoint}" "/mnt/gentoo/${mountpoint}"
                done
                mount "${SXDISK}1" /mnt/gentoo/boot
                f_msg info "--- Changing context"
                cd /mnt/gentoo
                f_msg info "###-#### Youre now in Securix root folder (${PWD})"
                # do not continue and exit
                exit
                ;;
            --mountluks)
                # for debug purposes or when you forget root password
                # mount Securix LUKS and LVM partitions
                f_getvar "Please specify disk with Securix installation (example: /dev/sda): " SXDISK "/dev/sda"
                f_msg info "--- Now opening LUKS"
                cryptsetup luksOpen "${SXDISK}3" root
                f_msg info "--- Scanning for volume groups"
                vgscan
                vgchange -a y
                f_msg info "--- Mounting /"
                mount /dev/mapper/root /mnt/gentoo
                for mountpoint in usr home opt var tmp; do
                    f_msg info "--- Mounting /${mountpoint}"
                    mount "/dev/mapper/vg-${mountpoint}" "/mnt/gentoo/${mountpoint}"
                done
                mount "${SXDISK}1" /mnt/gentoo/boot
                f_msg info "--- Changing context"
                cd /mnt/gentoo
                f_msg info "###-#### Youre now in Securix root folder (${PWD})"
                # do not continue and exit
                exit
                ;;
            --help|-h)
                # print script help
                echo "Usage: "${0}" [option]"
                echo ""
                echo "-a|--auto|--autobuild"
                echo "Mode without questions during build. Please verify first default variables as at least root password must be changed."
                echo "You can change variables manually and then use \"-s\" option or change them by own configuration file \"-c\" (prefered)."
                echo ""
                echo "-c=[file/url]|--conf=[file/url]|--config=[file/url]"
                echo "Load variables/setup from configuration file. File could be local path or URL address. You can find all variables at the beginning of script."
                echo ""
                echo "-s|--skip|--skipsign"
                echo "Do not verify install script signature. Use only when you must modify install script."
                echo ""
                echo "--mountlvm"
                echo "Mount existing Securix installation which is NOT using LUKS (for debug or failsave purposes)"
                echo ""
                echo "--mountluks"
                echo "mount existing Securix installation which is using LUKS (for debug or failsave purposes)"
                # do not continue and exit
                exit
                ;;
        esac
    done
}

# setup logging
if [ -r "${LOGFILE}" ]; then
    rm -f "${LOGFILE}"
fi
exec >  >(tee -a "${LOGFILE}")
exec 2> >(tee -a "${LOGFILE}" >&2)

# main execution
f_parse_cmd ${1+"$@"}
f_install_securix ${1+"$@"}

exit
