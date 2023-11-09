#!/bin/bash

RED='\033[0;31m'
GRE='\033[0;32m'
YEL='\033[0;33m'
NRM='\033[0m'

# Ensure we are running under bash
if [ "$BASH_SOURCE" = "" ]; then
    /bin/bash "$0"
    exit 0
fi

#all good
ipConfig () {
    clear
    defaultConfig=$(ls -A /etc/netplan/ | sort | awk -F '/' '{print}' | awk '/[0-9][0-9]-/{print $0}' | head -n1) #find netplan conf that being used
    if [ ! -z $defaultConfig ]; then
        printf "${GRE}Found the default netplan config\n$defaultConfig${NRM}\nChange it? [y/n]: "
        read -p "" yn
        case $yn in
            [Yy]* )
                printf "${YEL}Creating reserve copy for $defaultConfig to /etc/netplan/old/$defaultConfig.old ${NRM}\n"
                mkdir -p /etc/netplan/old/ && cp /etc/netplan/$defaultConfig /etc/netplan/old/$defaultConfig.old #save the copy
                ;;
            [Nn]* )
                mainMenu
                ;;
            * )
                printf "${RED}Bad response${NRM}\n"
                mainMenu
                ;;
        esac
                
	else #create if cant find existing
        printf "${YEL}Cant find any netplan configuration files\nCreate a new one? [y/n]: ${NRM}"
        read -p "" yn
        case $yn in
            [Yy]* )
                printf "${YEL}Enter the name of netplan config (e.g. 00-default-config): ${NRM}"
                read -p "" defaultConfig
                ;;
            [Nn]* )
                mainMenu
                ;;
            * )
                printf "${RED}Bad response${NRM}\n"
                mainMenu
                ;;
        esac
    fi

    #configuring
    ls /sys/class/net | sort | awk '{print "["NR"]",$0}' 
    printf "${YEL}Enter interface number: ${NRM}"
    read -p "" interfaceNum
    choosedInterface=$(ls /sys/class/net | sort | awk -v n="$interfaceNum" 'NR==n')
    printf "${YEL}Enter ip address and subnet mask (e.g. 192.168.0.123/24): ${NRM}"
    read -p "" ipAddress
    printf "${YEL}Enter DNS server (e.g. 192.168.0.1): ${NRM}"
    read -p "" DNSservers
    printf "${YEL}Enter default gateway (e.g. 192.168.0.1): ${NRM}"
    read -p "" defaultGateway
    
    
    printf "\n${YEL}Config name:${NRM} $defaultConfig \n"
    printf "${YEL}Interface:${NRM} $choosedInterface \n"
    printf "${YEL}IP address:${NRM} $ipAddress \n"
    printf "${YEL}DNS server:${NRM} $DNSservers \n"
    printf "${YEL}Default gateway:${NRM} $defaultGateway \n"

    printf "${YEL}Want to proceed? [y/n]: ${NRM}"
    read -p "" yn
    case $yn in
        [Yy]* )
            ;;
        [Nn]* )
            mainMenu
            ;;
        * )
            printf "${RED}Bad response${NRM}\n"
            mainMenu
            ;;
    esac

    #applying 
    echo "network:
  ethernets:
    $choosedInterface:
      addresses:
      - $ipAddress
      nameservers:
        addresses:
        - $DNSservers
        search:
        - $DNSservers
      routes:
      - to: default
        via: $defaultGateway
  version: 2" > /etc/netplan/$defaultConfig
    netplan apply
}

#all good
sshkeyGenrate(){
    clear
    userList=$(awk -F: '($3>=1000)&&($1!="nobody"){print $1}' /etc/passwd) #userlist
    if [ $(echo "$userList" | tr ' ' '\n' | wc -l) -gt 1 ]; then #if more than 1 choose
        printf "${GRE}Users:\n$(awk -F: '($3>=1000)&&($1!="nobody"){print "  " $1}' /etc/passwd)\n${NRM}"
        printf "${YEL}Enter desired user: ${NRM}"
        read -p "" usr 

        if [ -z $(echo "$userList" | grep "$usr") ]; then #invalid user
            printf "${RED}Invalid user${NRM}\n"
            read -p "Press Enter to continue..."
            mainMenu
        fi
    else
        usr=$(awk -F: '($3>=1000)&&($1!="nobody"){print $1}' /etc/passwd) #if only 1 user
    fi

    if [ ! -d "/home/$usr/.ssh" ]; then
        printf "${RED}/home/$usr/ has no .ssh directory\n${NRM}${YEL}Create? [y/n]: ${NRM}"
        read -p "" yn
        case $yn in
            [Yy]* )
                mkdir /home/$usr/.ssh
                chmod 0700 /home/$usr/.ssh
                printf "${GRE}/home/$usr/.ssh has been created\n${NRM}"

                touch /home/$usr/.ssh/authorized_keys
                chmod 0600 /home/$usr/.ssh/authorized_keys
                printf "${GRE}/home/$usr/.ssh/authorized_keys has been created\n${NRM}"

                chown -R $usr:$usr /home/$usr/.ssh
                printf "${GRE}Owner specified to $usr\n${NRM}"
                ;;
            [Nn]* )
                mainMenu
                ;;
            * )
                printf "${RED}Bad response${NRM}\n"
                mainMenu
                ;;
        esac
    fi

    printf "${YEL}Create an ssh key? [y/n]: ${NRM}"
    read -p "" yn
    case $yn in
        [Yy]* )
            printf "${YEL}Enter key name: ${NRM}"
            read -p "" keyName

            printf "${YEL}Enter key password (or leave empty): ${NRM}"
            read -p "" keyPasswd

            printf "${YEL}Enter key comment (or leave empty): ${NRM}"
            read -p "" keyComment

            ssh-keygen -t ed25519 -C "$keyComment" -f /home/$usr/.ssh/$keyName -N "$keyPasswd"

            if [ -e "/home/$usr/.ssh/$keyName" ]; then
                printf "${GRE}\nAll good! Your keys stored at /home/$usr/.ssh/\n${NRM}"
            else
                printf "${RED}\nSomething went wrong..\n${NRM}"
                mainMenu
            fi
            ;;
        [Nn]* )
            mainMenu
            ;;
        * )
            printf "${RED}Bad response${NRM}\n"
            mainMenu
            ;;
    esac
}
    
#all good
timezoneConfig(){
    clear
    printf "${YEL}Synchronizing to the NIST atomic clock..${NRM}\n"
    timedatectl set-ntp yes
    while true; do
        printf "${YEL}Choose your region or city (e.g. Europe, Amsterdam etc.): ${NRM}"
        read -p "" region
        if [ -n "$(timedatectl list-timezones | grep $region)" ]; then
            printf "${GRE}Found next timezones:\n${NRM}"
            timedatectl list-timezones | grep $region
            break
        else
            printf "${RED}Can't find region or city with this name\n${NRM}"
        fi
    done

    while true; do
        printf "${YEL}Choose your timezone (e.g. Europe/Amsterdam etc.): ${NRM}"
        read -p "" timezone
        if [[ "$timezone" =~ [A-Za-z]+/[A-Za-z]+ && -n "$(timedatectl list-timezones | grep $timezone)" ]]; then
            timedatectl set-timezone $timezone
            printf "${GRE}Time has been configured successfully!\n${NRM}"
            timedatectl | grep "Local time" | sed 's/^ *//'
            break
        else
            printf "${RED}Can't find timezone with this name\n${NRM}"
        fi
    done
}

#all good
firewallConfig(){
    firewallStatus(){
        if [ "$(ufw status | awk '/^Status:/{print $2}')" = "active" ]; then
            printf "${GRE}$(ufw status | awk '/^Status:/{print $2}')\n${NRM}" 
            if [ ! -z "$(ufw status | awk '/^[0-9]/{print $0}' | grep "ALLOW")" ]; then
                printf "${GRE}$(ufw status | awk '/^[0-9]/{print $0}' | grep "ALLOW")\n${NRM}"
            fi
            if [ ! -z "$(ufw status | awk '/^[0-9]/{print $0}' | grep "DENY")" ]; then
                printf "${RED}$(ufw status | awk '/^[0-9]/{print $0}' | grep "DENY")\n${NRM}"
            fi
        else
            printf "${RED}$(ufw status | awk '/^Status:/{print $2}')\n${NRM}"  
        fi
    }

    firewallOption(){
        if [ "$1" = "reset" ]; then
            ufw $1
        else
            printf "${YEL}Enter an value\nufw $1 ${NRM}"
            read -p "" Value
            ufw $1 $Value
        fi
    }

    while true; do
        clear
        echo "Firewall status: $(firewallStatus)"
        echo "[1] UFW on/off"
        echo "[2] UFW allow"
        echo "[3] UFW deny"
        echo "[4] UFW delete"
        echo "[5] UFW reset"
        echo "[q] Exit"

        printf "${YEL}Choose an option: ${NRM}"
        read -p "" choice

        case $choice in
            1)
                if [ "$(ufw status | awk '/^Status:/{print $2}')" = "active" ]; then
                    ufw disable  
                else
                    ufw enable
                fi
                ;;
            2)
                firewallOption "allow"
                ;;
            3)
                firewallOption "deny"
                ;;
            4)
                firewallOption "delete"
                ;;
            5)
                firewallOption "reset"
                ;;
            q)
                echo "Exiting..."
                mainMenu
                ;;
            *)
                echo "Bad input, please choose the number between 1-5"
                ;;
        esac

        read -p "Press Enter to continue..."
    done
}

#all good
commonPackages(){
    checkPackageColour() {
        if dpkg -l "$1" &> /dev/null; then
            printf "${GRE}$1${NRM}"  
        else
            printf "${RED}$1${NRM}"  
        fi
    }
    packageManage() {
        if dpkg -l "$1" &> /dev/null; then
            printf "${YEL}$1 package is going to be deleted\nProceed? [y/n]: ${NRM}"
            read -p "" yn
            case $yn in
                [Yy]* )
                    apt purge -y $1
                    apt autoremove -y
                    ;;
                [Nn]* )
                    commonPackages
                    ;;
                * )
                    printf "${RED}Bad response${NRM}\n"
                    commonPackages
                    ;;
            esac 
        else
            printf "${YEL}$1 package is going to be installed\nProceed? [y/n]: ${NRM}"
            read -p "" yn
            case $yn in
                [Yy]* )
                    apt install -y $1
                    ;;
                [Nn]* )
                    commonPackages
                    ;;
                * )
                    printf "${RED}Bad response${NRM}\n"
                    commonPackages
                    ;;
            esac
        fi
    }

    clear
    apt update
    
    while true; do
        clear

        echo "Available packages"
        printf "${RED}Uninstalled${NRM}|${GRE}Installed${NRM}\n"
        echo "[1] $(checkPackageColour "git")"
        echo "[2] $(checkPackageColour "curl")"
        echo "[3] $(checkPackageColour "wget")"
        echo "[4] $(checkPackageColour "unzip")"
        echo "[5] $(checkPackageColour "net-tools")"
        echo "[6] Other package"
        echo "[q] Back to main menu"

        printf "${YEL}Choose an option: ${NRM}"
        read -p "" choice

        case $choice in
            1)
                packageManage "git"
                ;;
            2)
                packageManage "curl"
                ;;
            3)
                packageManage "wget"
                ;;
            4)
                packageManage "unzip"
                ;;
            5)
                packageManage "net-tools"
                ;;
            6)
                printf "${YEL}Enter package name: ${NRM}"
                read -p "" otherPackage
                packageManage "$otherPackage"
                ;;
            q)
                echo "Exiting..."
                mainMenu
                ;;
            *)
                echo "Bad input, please choose the number between 1-6"
                ;;
        esac
        read -p "Press Enter to continue..."
    done
}
    
#all good
taskOrientedPackages(){
     checkPackageColour() {
        if dpkg -l "$1" &> /dev/null; then
            printf "${GRE}$1${NRM}"  
        else
            printf "${RED}$1${NRM}"  
        fi
    }    

    clear
    apt update
    
    while true; do
        clear

        echo "Available packages"
        printf "${RED}Uninstalled${NRM}|${GRE}Installed${NRM}\n"
        echo "[1] $(checkPackageColour "docker-ce")"
        #echo "[2] $(checkPackageColour "")"
        echo "[q] Back to main menu"

        printf "${YEL}Choose an option: ${NRM}"
        read -p "" choice

        case $choice in
            1)
                packageDocker
                ;;
            q)
                echo "Exiting..."
                mainMenu
                ;;
            *)
                echo "Bad input, please choose the number between 1-6"
                ;;
        esac
        read -p "Press Enter to continue..."
    done
}

#all good
userManage(){
    userAdd(){
        adduser $1

        while true; do
            clear
            printf "${GRE}$1 user has been created${NRM}\n${YEL}Grant him root access? [y/n]: ${NRM}"
            read -p "" yn
            case $yn in
                [Yy]* )
                    usermod -aG sudo $1
                    printf "${GRE}$1 root permissions has been granted!\n${NRM}"
                    read -p "Press Enter to continue..."
                    userManage
                    ;;
                [Nn]* )
                    userManage
                    ;;
                * )
                    printf "${RED}Bad input${NRM}\n"
                    ;;
            esac
            read -p "Press Enter to continue..."
        done
    }
    userDel(){
        while true; do
            clear
            if [ -z $(echo "$userList" | grep "$1") ]; then #invalid user
                printf "${RED}Invalid user${NRM}\n"
                read -p "Press Enter to continue..."
                mainMenu
            fi
            printf "${YEL}$1 and /home/$1/ is going to be deleted\nProceed? [y/n]: ${NRM}"
            read -p "" yn
            case $yn in
                [Yy]* )
                    deluser --remove-home $1
                    printf "${GRE}$1 has been deleted\n${NRM}"
                    read -p "Press Enter to continue..."
                    userManage
                    ;;
                [Nn]* )
                    userManage
                    ;;
                * )
                    printf "${RED}Bad input${NRM}\n"
                    ;;
            esac
            read -p "Press Enter to continue..."
        done
    }
    while true; do
        clear
        userList=$(awk -F: '($3>=1000)&&($1!="nobody"){print $1}' /etc/passwd) #userlist
        printf "${GRE}Users:\n$(awk -F: '($3>=1000)&&($1!="nobody"){print "  " $1}' /etc/passwd)\n${NRM}"
        echo "[1] Add user"
        echo "[2] Delete user"
        echo "[q] Exit"

        printf "${YEL}Choose an option: ${NRM}"
        read -p "" choice

        case $choice in
            1)
                printf "${YEL}Enter user name: ${NRM}"
                read -p "" usr 
                userAdd "$usr"
                ;;
            2)
                printf "${YEL}Enter user name: ${NRM}"
                read -p "" usr 
                userDel "$usr"
                ;;
            q)
                echo "Exiting..."
                mainMenu
                ;;
            *)
                echo "Bad input, please choose the number between 1-2"
                ;;
        esac
        read -p "Press Enter to continue..."
    done
}

#all good
sysUpgrade(){
    clear
    while true; do
        clear
        printf "${YEL}Are you sure[y/n]: ${NRM}"
        read -p "" yn
        case $yn in
            [Yy]* )
                sudo apt -y upgrade
                printf "${GRE}All good!${NRM}\n"
                read -p "Press Enter to continue..."
                mainMenu
                ;;
            [Nn]* )
                mainMenu
                ;;
            * )
                printf "${RED}Bad input${NRM}\n"
                ;;
        esac
        read -p "Press Enter to continue..."
    done
    
}

#all good
mainMenu (){
    while true; do
        clear
        echo "BOOTSTRAP SCRIPT"
        echo "[1] Configure ip address"
        echo "[2] Configure SSH access"
        echo "[3] Configure system timezone"
        echo "[4] Configure firewall"
        echo "[5] Install/Delete common packages"
        echo "[6] Install task-oriented packages"
        echo "[7] Manage users"
        echo "[8] System upgrade"
        echo "[q] Exit"

        printf "${YEL}Choose an option: ${NRM}"
        read -p "" choice

        case $choice in
            1)
                ipConfig
                ;;
            2)
                sshkeyGenrate
                ;;
            3)
                timezoneConfig
                ;;
            4)
                firewallConfig
                ;;
            5)
                commonPackages
                ;;
            6)
                taskOrientedPackages
                ;;
            7)
                userManage
                ;;
            8)
                sysUpgrade
                ;;
            q)
                echo "Exiting..."
                exit
                ;;
            *)
                echo "Bad input, please choose the number between 1-8"
                ;;
        esac

        read -p "Press Enter to continue..."
    done
}


mainMenu