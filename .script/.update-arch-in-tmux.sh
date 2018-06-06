#!/bin/bash

#this script check for archlinux news and if no news found update archlinux.

Args=$@
USERNAME=${SUDO_USER:-$(id -u -n)}
HOMEDIR="/home/$USERNAME"
SUDO=""
if [ $EUID -ne 0 ]; then
    SUDO='/usr/bin/sudo'
fi

# Colors
blue="\033[1;34m"
green="\033[1;32m"
red="\033[1;31m"
bold="\033[1;37m"
reset="\033[0m"

programname="update-arch"
RSSFILE="$HOMEDIR/.archnews"
TMPFILE="$HOMEDIR/.archnewstmp"
Build=""
Install=""
Mirror=""
Refresh=""
AUR=""
Help=""
Sync=""
LoggingOff=""
RSSOff=""
PacOff=""
NamCapOff=""
Shutdown=""
Sleep=""
Logout=""
Hibernate=""
Reboot=""
UpdateMirrorCMD="${SUDO} /usr/bin/reflector --sort rate --latest 10 --protocol https --protocol ftp --age 6 --save /etc/pacman.d/mirrorlist"
SuspendCMD="/usr/bin/systemctl suspend"
ShutdownCMD="/usr/bin/systemctl poweroff"
RebootCMD="/usr/bin/systemctl reboot"
LogoutCMD="/usr/bin/loginctl terminate-user $USERNAME"
HibernateCMD="/usr/bin/systemctl hibernate"

function help {
    echo "Usage: $programname [OPTION]"
    echo "A script for updating archlinux."
    echo ""
    echo "  -a, --aur       Refresh and synchronize all normal and aur package databases"
    echo "  -o  --poweroff  Shutdown computer if the script finished without error"         
    echo "  -e  --reboot    Restart computer if the script finished without error"
    echo "  -f  --freeze    Hibernate computer if the script finished without error"
    echo "  -u  --suspend   Suspend computer if the script finished without error"
    echo "  -g  --logout    Logout if the script finished without error"
    echo "  --shutdown      Shutdown computer if the script finished without error"     
    echo "  --restart       Restart computer if the script finished without error"
    echo "  --hibernate     Hibernate computer if the script finished without error"
    echo "  --sleep         Suspend computer if the script finished without error"
    echo "  --logoff        Logout if the script finished without error"
    echo "  -s, --sync      Refresh and synchronize normal package databases"
    echo "  -y, --refresh   Force the refresh of package databases"
    echo "  -n, --nonamcap  Disable checking packages with namcap"
    echo "  -r  --norss     Disable checking for archlinux news" 
    echo "  -p, --nopac     Disable checking for pacnew files" 
    echo "  -i, --install   Install a package"
    echo "  -b, --build     Build a package"
    echo "  -l  --nolog     Disable logging"
    echo "  -m, --mirror    Update mirrors"
    echo "  -h, --help      Display help"
    echo ""
    read -p "Press enter to exit..."
}

function usage {
    help
    exit 1
}

#testing number of args:
if [ "${#}" -gt 11 ]; then
    echo -e $red"Error:$reset Invalid number of parameters"
    echo ""
    usage
elif [ "${#}" -eq 0 ]; then
    usage
fi

# Test command-line arguments.
if [ -n "$1" ]; then #non-empty
  while [ "$1" != "" ]; do
    PARAM="$1"
    if [[  $PARAM =~ ^--[Ii][Nn][Ss][Tt][Aa][Ll][Ll]$ ]] || [[ $PARAM =~ ^-[Ii]$ ]]; then
	  if [[ $Install == "" ]]; then
        Install="Yes"
	  else
	    echo -e $red"Error:$reset Invalid arguments '${Args}'"
	    echo ""
	    usage
	  fi
    elif [[ $PARAM =~ ^--[Bb][Uu][Ii][Ll][Dd]$ ]] || [[ $PARAM =~ ^-[Bb]$ ]]; then
      if [[ $Build == "" ]]; then
        Build="Yes"
	  else
        echo -e $red"Error:$reset Invalid arguments '${Args}'"
        echo ""
		usage
	  fi 
    elif [[ $PARAM =~ ^--[Mm][Ii][Rr][Rr][Oo][Rr]$ ]] || [[ $PARAM =~ ^-[Mm]$ ]]; then
	  if [[ $Mirror == "" ]]; then
        Mirror="Yes"
	  else
		echo -e $red"Error:$reset Invalid arguments '${Args}'"
		echo ""
		usage
	  fi
    elif [[ $PARAM =~ ^--[Rr][Ee][Ff][Rr][Ee][Ss][Hh]$ ]] || [[ $PARAM =~ ^-[Yy]$ ]]; then
	  if [[ $Refresh == "" ]]; then
        Refresh="Yes"
	  else
		echo -e $red"Error:$reset Invalid arguments '${Args}'"
		echo ""
		usage
	  fi
    elif [[ $PARAM =~ ^--[Aa][Uu][Rr]$ ]] || [[ $PARAM =~ ^-[Aa]$ ]]; then
	  if [[ $AUR == "" ]]; then
        AUR="Yes"
	  else
		echo -e $red"Error:$reset Invalid arguments '${Args}'"
		echo ""
		usage
	  fi
    elif [[ $PARAM =~ ^--[Hh][Ee][Ll][Pp]$ ]] || [[ $PARAM =~ ^-[Hh]$ ]]; then
      if [[ $Help == "" ]]; then
        Help="Yes"
	  else
        echo -e $red"Error:$reset Invalid arguments '${Args}'"
        echo ""
		usage
	  fi
	elif [[ $PARAM =~ ^--[Ss][Yy][Nn][Cc]$ ]] || [[ $PARAM =~ ^-[Ss]$ ]]; then
      if [[ $Sync == "" ]]; then
        Sync="Yes"
	  else
        echo -e $red"Error:$reset Invalid arguments '${Args}'"
        echo ""
		usage
	  fi
	elif [[ $PARAM =~ ^--[Nn][Oo][Ll][Oo][Gg]$ ]] || [[ $PARAM =~ ^-[Ll]$ ]]; then
      if [[ $LoggingOff == "" ]]; then
        LoggingOff="Yes"
	  else
        echo -e $red"Error:$reset Invalid arguments '${Args}'"
        echo ""
		usage
	  fi
	elif [[ $PARAM =~ ^--[Nn][Oo][Rr][Ss][Ss]$ ]] || [[ $PARAM =~ ^-[Rr]$ ]]; then
      if [[ $RSSOff == "" ]]; then
        RSSOff="Yes"
      else
        echo -e $red"Error:$reset Invalid arguments '${Args}'"
        echo ""
        usage
	  fi
    elif [[ $PARAM =~ ^--[Nn][Oo][Pp][Aa][Cc]$ ]] || [[ $PARAM =~ ^-[Pp]$ ]]; then
      if [[ $PacOff == "" ]]; then
        PacOff="Yes"
	  else
        echo -e $red"Error:$reset Invalid arguments '${Args}'"
        echo ""
		usage
	  fi
    elif [[ $PARAM =~ ^--[Nn][Oo][Nn][Aa][Mm][Cc][Aa][Pp]$ ]] || [[ $PARAM =~ ^-[Nn]$ ]]; then
      if [[ $NamCapOff == "" ]]; then
        NamCapOff="Yes"
	  else
        echo -e $red"Error:$reset Invalid arguments '${Args}'"
        echo ""
		usage
	  fi
    elif [[ $PARAM =~ ^--[Pp][Oo][Ww][Ee][Rr][Oo][Ff][Ff]$ ]] || [[ $PARAM =~ ^--[Ss][Hh][Uu][Tt][Dd][Oo][Ww][Nn]$ ]] || [[ $PARAM =~ ^-[Oo]$ ]]; then
      if [[ $Sleep == "" ]] && [[ $Shutdown == "" ]] && [[ $Reboot == "" ]] && [[ $Hibernate == "" ]] && [[ $Logout == "" ]]; then
        Shutdown="Yes"
      else
        echo -e $red"Error:$reset Invalid arguments '${Args}'"
        echo ""
		usage
	  fi  
    elif [[ $PARAM =~ ^--[Ss][Uu][Ss][Pp][Ee][Nn][Dd]$ ]] || [[ $PARAM =~ ^--[Ss][Ll][Ee][Ee][Pp]$ ]] || [[ $PARAM =~ ^-[Uu]$ ]]; then
      if [[ $Sleep == "" ]] && [[ $Shutdown == "" ]] && [[ $Reboot == "" ]] && [[ $Hibernate == "" ]] && [[ $Logout == "" ]]; then
        Sleep="Yes"
      else
        echo -e $red"Error:$reset Invalid arguments '${Args}'"
        echo ""
		usage
	  fi
    elif [[ $PARAM =~ ^--[Rr][Ee][Ss][Tt][Aa][Rr][Tt]$ ]] || [[ $PARAM =~ ^--[Rr][Ee][Bb][Oo][Oo][Tt]$ ]] || [[ $PARAM =~ ^-[Ee]$ ]]; then
      if [[ $Sleep == "" ]] && [[ $Shutdown == "" ]] && [[ $Reboot == "" ]] && [[ $Hibernate == "" ]] && [[ $Logout == "" ]]; then
        Reboot="Yes"
      else
        echo -e $red"Error:$reset Invalid arguments '${Args}'"
        echo ""
		usage
	  fi 
    elif [[ $PARAM =~ ^--[Ll][Oo][Gg][Oo][Ff][Ff]$ ]] || [[ $PARAM =~ ^--[Ll][Oo][Gg][Oo][Uu][Tt]$ ]] || [[ $PARAM =~ ^-[Gg]$ ]]; then
      if [[ $Sleep == "" ]] && [[ $Shutdown == "" ]] && [[ $Reboot == "" ]] && [[ $Hibernate == "" ]] && [[ $Logout == "" ]]; then
        Logout="Yes"
      else
        echo -e $red"Error:$reset Invalid arguments '${Args}'"
        echo ""
		usage
	  fi
    elif [[ $PARAM =~ ^--[Hh][Ii][Bb][Ee][Rr][Nn][Aa][Tt][Ee]$ ]] || [[ $PARAM =~ ^--[Ff][Rr][Ee][Ee][Zz][Ee]$ ]] || [[ $PARAM =~ ^-[Ff]$ ]]; then
      if [[ $Sleep == "" ]] && [[ $Shutdown == "" ]] && [[ $Reboot == "" ]] && [[ $Hibernate == "" ]] && [[ $Logout == "" ]]; then
        Hibernate="Yes"
      else
        echo -e $red"Error:$reset Invalid arguments '${Args}'"
        echo ""
		usage
	  fi
    elif [[ $PARAM =~ ^-[AaBbEeFfGgIiLlMmNnOoPpRrSsTtUuYy][AaBbEeFfGgIiLlMmNnOoPpRrSsTtUuYy][AaBbEeFfGgIiLlMmNnOoPpRrSsTtUuYy]?[AaBbEeFfGgIiLlMmNnOoPpRrSsTtUuYy]?[AaBbEeFfGgIiLlMmNnOoPpRrSsTtUuYy]?[AaBbEeFfGgIiLlMmNnOoPpRrSsTtUuYy]?[AaBbEeFfGgIiLlMmNnOoPpRrSsTtUuYy]?[AaBbEeFfGgIiLlMmNnOoPpRrSsTtUuYy]?[AaBbEeFfGgIiLlMmNnOoPpRrSsTtUuYy]?[AaBbEeFfGgIiLlMmNnOoPpRrSsTtUuYy]?[AaBbEeFfGgIiLlMmNnOoPpRrSsTtUuYy]?$ ]]; then
	  i=1
	  while (( i++ < ${#PARAM} ))
	  do
   		char=$(expr substr "$PARAM" $i 1)
   		if [[ $char =~ [Mm] ]]; then
			if [[ $Mirror == "" ]]; then
				Mirror="Yes"
			else
				echo -e $red"Error:$reset Invalid arguments '${Args}'"
                echo ""
		        usage
			fi
   		elif [[ $char =~ [Ii] ]]; then
			if [[ $Install == "" ]]; then
				Install="Yes"
			else
				echo -e $red"Error:$reset Invalid arguments '${Args}'"
                echo ""
		        usage
			fi
		elif [[ $char =~ [Bb] ]]; then
			if [[ $Build == "" ]]; then
				Build="Yes"
			else
				echo -e $red"Error:$reset Invalid arguments '${Args}'"
				echo ""
				usage
			fi		
        elif [[ $char =~ [Yy] ]]; then
			if [[ $Refresh == "" ]]; then
				Refresh="Yes"
			else
				echo -e $red"Error:$reset Invalid arguments '${Args}'"
                echo ""
		        usage
			fi
        elif [[ $char =~ [Aa] ]]; then
			if [[ $AUR == "" ]]; then
				AUR="Yes"
			else
				echo -e $red"Error:$reset Invalid arguments '${Args}'"
                echo ""
		        usage
			fi
		elif [[ $char =~ [Ss] ]]; then
			if [[ $Sync == "" ]]; then
				Sync="Yes"
			else
				echo -e $red"Error:$reset Invalid arguments '${Args}'"
				echo ""
				usage
			fi
		elif [[ $char =~ [Ll] ]]; then
			if [[ $LoggingOff == "" ]]; then
				LoggingOff="Yes"
			else
				echo -e $red"Error:$reset Invalid arguments '${Args}'"
				echo ""
				usage
			fi
		elif [[ $char =~ [Rr] ]]; then
			if [[ $RSSOff == "" ]]; then
				RSSOff="Yes"
			else
				echo -e $red"Error:$reset Invalid arguments '${Args}'"
				echo ""
				usage
			fi
		elif [[ $char =~ [Pp] ]]; then
			if [[ $PacOff == "" ]]; then
				PacOff="Yes"
			else
				echo -e $red"Error:$reset Invalid arguments '${Args}'"
				echo ""
				usage
			fi
        elif [[ $char =~ [Nn] ]]; then
			if [[ $NamCapOff == "" ]]; then
				NamCapOff="Yes"
			else
				echo -e $red"Error:$reset Invalid arguments '${Args}'"
				echo ""
				usage
			fi
        elif [[ $char =~ [Uu] ]]; then
            if [[ $Sleep == "" ]] && [[ $Shutdown == "" ]] && [[ $Reboot == "" ]] && [[ $Hibernate == "" ]] && [[ $Logout == "" ]]; then
                Sleep="Yes"
            else
                echo -e $red"Error:$reset Invalid arguments '${Args}'"
                echo ""
                usage
            fi  
        elif [[ $char =~ [Oo] ]]; then
            if [[ $Sleep == "" ]] && [[ $Shutdown == "" ]] && [[ $Reboot == "" ]] && [[ $Hibernate == "" ]] && [[ $Logout == "" ]]; then
                Shutdown="Yes"
            else
                echo -e $red"Error:$reset Invalid arguments '${Args}'"
                echo ""
                usage
            fi 
        elif [[ $char =~ [Ee] ]]; then
            if [[ $Sleep == "" ]] && [[ $Shutdown == "" ]] && [[ $Reboot == "" ]] && [[ $Hibernate == "" ]] && [[ $Logout == "" ]]; then
                Reboot="Yes"
            else
                echo -e $red"Error:$reset Invalid arguments '${Args}'"
                echo ""
                usage
            fi
        elif [[ $char =~ [Gg] ]]; then
            if [[ $Sleep == "" ]] && [[ $Shutdown == "" ]] && [[ $Reboot == "" ]] && [[ $Hibernate == "" ]] && [[ $Logout == "" ]]; then
                Logout="Yes"
            else
                echo -e $red"Error:$reset Invalid arguments '${Args}'"
                echo ""
                usage
            fi 
        elif [[ $char =~ [Ff] ]]; then
            if [[ $Sleep == "" ]] && [[ $Shutdown == "" ]] && [[ $Reboot == "" ]] && [[ $Hibernate == "" ]] && [[ $Logout == "" ]]; then
                Hibernate="Yes"
            else
                echo -e $red"Error:$reset Invalid arguments '${Args}'"
                echo ""
                usage
            fi
		else
			echo -e $red"Error:$reset Invalid argument '$PARAM'"
            echo ""
            usage
		fi
	  done
    else
      echo -e $red"Error:$reset Invalid argument '$PARAM'"
      echo ""
      usage
    fi
    shift
  done
fi

if [[ $Help == "Yes" ]]; then
	help
    exit 0
fi

if [[ $AUR == "Yes" ]]; then
    Sync="Yes"
fi

if [[ $Refresh == "Yes" ]] && [[ ! $Sync == "Yes" ]] && [[ ! $AUR == "Yes" ]]; then
    usage
fi

if [[ ! $Build == "Yes" ]] && [[ ! $Install == "Yes" ]] && [[ ! $Mirror == "Yes" ]] && [[ ! $AUR == "Yes" ]] && [[ ! $Sync == "Yes" ]]; then
    usage
fi

if [[ ! $PacOff == "Yes" ]]; then
    echo
    echo -e $blue"===>$reset Checking for pacnew files..."
    echo
    if [[ $($SUDO find /etc -regextype posix-extended -regex ".+\.pacnew" 2> /dev/null) ]]; then
        echo -e $red"Error:$reset Pacnew file(s) found! (Use pacdiff to deal with them):"
        echo
        $SUDO find /etc -regextype posix-extended -regex ".+\.pac(new|save)" 2> /dev/null
        echo
        read -p "Press enter to exit..."
        exit 1
    else
        echo 
        echo "No pacnew file found"
    fi
    echo
    echo
fi
if [[ ! $RSSOff == "Yes" ]]; then
    [ -f $RSSFILE ] && cat "${RSSFILE}" 2> /dev/null
    /usr/bin/rm -f "${TMPFILE}"
    echo
    echo -e $blue"===>$reset Checking for unread arch linux news..."
    echo
    echo
    echo
    #tac reverses the output
    { /usr/bin/rsstail -n 5 -1 -u https://www.archlinux.org/feeds/news/ | /usr/bin/tac > "${TMPFILE}" ; } || { echo -e $red"Error:$reset Cannot download the rss content" ; read -p "Press enter to exit..." ; exit 1; }
    [[ -s "${TMPFILE}" ]] || { echo -e $red"Error:$reset Cannot download the rss content" ; read -p "Press enter to exit..." ; exit 1; }
    if [ -f $RSSFILE ]; then
        if /usr/bin/cmp -s "$RSSFILE" "$TMPFILE"; then
            rm -f "${TMPFILE}"
            echo "No new rss entry found"
            echo
        else
            echo -e $red" !!!$reset New arch linux news entry found $red!!!$reset"
            echo
            [ -f $TMPFILE ] && cat "${TMPFILE}" 2> /dev/null
            sleep 3		
            /usr/bin/mv -f $TMPFILE $RSSFILE
            { /usr/bin/rsstail -n 5 -1 -l -d -H -u https://www.archlinux.org/feeds/news/ | /usr/bin/less ; } || { echo -e $red"Error:$reset Cannot download the rss content" ; read -p "Press enter to exit..." ; exit 1; }
            exit 0
        fi
    else
        echo -e $red" !!!$reset New arch linux news entry found $red!!!$reset"
        echo
        [ -f $TMPFILE ] && cat "${TMPFILE}"  2> /dev/null
        echo
        sleep 3
        /usr/bin/mv $TMPFILE $RSSFILE
        { /usr/bin/rsstail -n 10 -1 -l -d -H -u https://www.archlinux.org/feeds/news/ | /usr/bin/less ; } || { echo -e $red"Error:$reset Cannot download the rss content" ; read -p "Press enter to exit..." ; exit 1; }
        exit 0
    fi
fi
if [[ $Mirror == "Yes" ]]; then
        echo
        echo -e  $blue"===>$reset Updating mirrorlist..."
        { $SUDO /usr/bin/cp -f /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak ; } || { echo -e $red"Error:$reset Cannot backup mirrorlist" ; read -p "Press enter to exit..." ; exit 1; }
        { eval "${UpdateMirrorCMD}" ; } || { echo -e $red"Error:$reset Cannot update mirrors"; }
fi
if [[ $Install == "Yes" ]] || [[ $Build == "Yes" ]]; then
    if [[ $Build == "Yes" ]]; then
        if [[ ! $NamCapOff == "Yes" ]]; then
            echo ""
            echo -e $blue"===>$reset Checking PKGBUILD file for error..."
            echo ""
            /usr/bin/namcap PKGBUILD
            echo ""
            read -p "Press enter to continue..."
        fi
        echo ""
        echo -e $blue"===>$reset Building the package..."
        echo ""
        { /usr/bin/sudo -u $USERNAME /usr/bin/makepkg -sc ; } || { echo "" ; echo -e $red"Error:$reset Cannot build the package" ; echo "" ; read -p "Press enter to exit..." ; exit 1; }
    fi
    if [[ ! $NamCapOff == "Yes" ]]; then
        echo ""
        echo -e $blue"===>$reset Checking the build package file for error..."
        echo ""
        /usr/bin/find . -maxdepth 1 -name '*.pkg.tar.xz' -exec /usr/bin/namcap {} \;
        echo ""
        read -p "Press enter to continue..."
    fi
    if [[ $Install == "Yes" ]]; then
        echo ""
        echo -e $blue"===>$reset Installing the package..."
        echo ""
        { /usr/bin/find . -maxdepth 1 -name '*.pkg.tar.xz' -exec $SUDO /usr/bin/pacman -U {} \; ; } || { echo "" ; echo -e $red"Error:$reset Cannot install the package" ; echo "" ; read -p "Press enter to exit..." ; exit 1; }
    fi
fi	
if [[ $Sync == "Yes" ]]; then
    echo
    echo -e $blue"===>$reset Checking for updates..."
    echo
    if [[ ! $Refresh == "Yes" ]]; then
        if [[ $AUR == "Yes" ]]; then
            if [ -x /usr/bin/yaourt ]; then
                { /usr/bin/sudo -u $USERNAME /usr/bin/yaourt -Syua ; } || { echo -e $red"Error:$reset Cannot update the system" ; read -p "Press enter to exit..." ; exit 1; }
            else
                echo -e $red"Error:$reset Yaourt not found"
                exit 1
            fi 
        elif [ -x /usr/bin/pacmatic ]; then
            { $SUDO /usr/bin/pacmatic -Syu ; } || { echo -e $red"Error:$reset Cannot update the system" ; exit 1; }
        else
            { $SUDO /usr/bin/pacman -Syu ; } || { echo -e $red"Error:$reset Cannot update the system" ; read -p "Press enter to exit..." ; exit 1; }
        fi
    else
        if [[ $AUR == "Yes" ]]; then
            if [ -x /usr/bin/yaourt ]; then
                { /usr/bin/sudo -u $USERNAME /usr/bin/yaourt -Syyua ; } || { echo -e $red"Error:$reset Cannot update the system" ; read -p "Press enter to exit..." ; exit 1; }
            else
                echo -e $red"Error:$reset Yaourt not found"
                exit 1
            fi
        elif [ -x /usr/bin/pacmatic ]; then
            { $SUDO /usr/bin/pacmatic -Syyu ; } || { echo -e $red"Error:$reset Cannot update the system" ; exit 1; }
        else
            { $SUDO /usr/bin/pacman -Syyu ; } || { echo -e $red"Error:$reset Cannot update the system" ; read -p "Press enter to exit..." ; exit 1; }
        fi
    fi
fi
echo
if [[ ! $RSSOff == "Yes" ]]; then
    [ -f $RSSFILE ] && cat "${RSSFILE}" | 2> /dev/null
fi
echo
if [[ ! $LoggingOff == "Yes" ]]; then
    echo
    echo -e  $blue"===>$reset Updating log files..."
    echo
    { /usr/bin/bash "$HOMEDIR/bin/logupdates" ; } || { echo -e $red"Error:$reset Cannot update '.number_of_updates.txt' file" ; }
    { /usr/bin/sudo -u $USERNAME /usr/bin/tail --lines=100 /var/log/pacman.log > $HOMEDIR/.updatesystem.log ; } || { echo -e $red"Error:$reset Cannot update '.updatesystem.log' file" ; }
fi
echo
if [[ ! $RSSOff == "Yes" ]]; then
    echo
    echo "Latest arch linux news:"
    echo
    [ -f $RSSFILE ] && cat "${RSSFILE}" 2> /dev/null
fi
if [[ $Sleep == "Yes" ]]; then
  echo
  x=15
  while [ $x -gt 0 ]
    do
     sleep 1s
     clear
     echo -e $red"Suspend$reset in$green $x$reset seconds..."
     x=$(( $x - 1 ))
  done
  eval "${SuspendCMD}"
  exit 0
elif [[ $Shutdown == "Yes" ]]; then
  echo
  x=15
  while [ $x -gt 0 ]
    do
     sleep 1s
     clear
     echo -e $red"Shutdown$reset in$green $x$reset seconds..."
     x=$(( $x - 1 ))
  done
  eval "${ShutdownCMD}"
  exit 0
elif [[ $Reboot == "Yes" ]]; then
  echo
  x=15
  while [ $x -gt 0 ]
    do
     sleep 1s
     clear
     echo -e $red"Restart$reset in$green $x$reset seconds..."
     x=$(( $x - 1 ))
  done
  eval "${RebootCMD}"
  exit 0
elif [[ $Logout == "Yes" ]]; then
  echo
  x=15
  while [ $x -gt 0 ]
    do
     sleep 1s
     clear
     echo -e $red"Logout$reset in$green $x$reset seconds..."
     x=$(( $x - 1 ))
  done
  eval "${LogoutCMD}"
  exit 0
elif [[ $Hibernate == "Yes" ]]; then
  echo
  x=15
  while [ $x -gt 0 ]
    do
     sleep 1s
     clear
     echo -e $red"Hibernate$reset in$green $x$reset seconds..."
     x=$(( $x - 1 ))
  done
  eval "${HibernateCMD}"
  exit 0
else
    echo
    read -p "Press enter to exit..."
    exit 0
fi
