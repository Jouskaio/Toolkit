#!/bin/bash

# ATTENTION :
# - Execute the file with `bash ssh_keyloading.sh` and not `sh ./ssh_keyloading.sh`
#   for compatibility reason
# - No space in JSON elements, whitespace aren't ignored in the condition in whiptail command

# ------------- INSTALL PACKAGE NEEDED -------------
FILE="$PWD"/keys.json
ROOT_PROJECT=$PWD

source colors.sh
source functions.sh

clear
read -p $'\033[1;33m Do you want to install the last version of Bash ? Y/n \033[0m: ' COMMAND_BASH
if [[ "$COMMAND_BASH" == "Y" || "$COMMAND_BASH" == "y" ]]; then
  printf "${White}"
  sudo apt update
  sudo apt-get install --only-upgrade bash
  printf "${Color_Off}"
  else
    echo -e "${Yellow}Quit bash update...${Color_Off}"
fi

read -p $'\033[1;33mDo you want to install jq ? Y/n \033[0m: ' COMMAND_JQ
if [[ "$COMMAND_JQ" = "Y" || "$COMMAND_JQ" = "y" ]]; then
  printf  "${White}"
  sudo apt update
  sudo apt install jq
  printf "${Color_Off}"
  else
    echo -e "${Yellow}Quit jq installation...${Color_Off}"
fi


# ------------- DIMENSION DIALOG -------------
HEIGHT=0
WIDTH=0
CHOICE_HEIGHT=4
# Add 2 two considerate the insert and delete option
COUNT_OPTION=$(jq '. | length' "$PWD"/keys.json)
#backtitle="SSH Connexion"
TITLE="SSH connexion"
MENU="Select the ssh connexion you want to use. If you want to add a new connexion, remember to add the ssh key in ssh folder (~/.ssh for Linux)"

# ------------- ADDING OPTIONS DIALOG -------------
DESCRIPTION=""
COUNTER=1
# To resolve whitespace who dictates to foreach that any word is a new element, we use this command
# Source : https://unix.stackexchange.com/questions/459419/why-are-spaces-echoing-as-newlines
# Update : This method doesn't work on whiptail because the description part use whitespace to
# separate elements between value and label
while IFS= read -r line; do
  DESCRIPTION+=("$COUNTER $line")
  COUNTER=$((COUNTER+1))
done < <(jq -cr '.[].name ' < "keys.json")
# Add the insert and delete option
DESCRIPTION='0 Insert_new_connection' $DESCRIPTION

# ------------- INITIALIZATION DIALOG -------------
ARRAY_NAME=$(jq  '.[].name' $PWD/keys.json | jq --slurp '.[]')
# shellcheck disable=SC2068
CHOICES=$(whiptail --title "$TITLE" \
          --backtitle "Menu" --menu \
          --nocancel "$MENU" $HEIGHT $WIDTH $CHOICE_HEIGHT \
          `for i in ${!DESCRIPTION[@]}; do echo "${DESCRIPTION[$i]}"; done` \
          3>&1 1>&2 2>&3)
#Other solution ? : https://unix.stackexchange.com/questions/479552/dynamic-options-on-whiptail-got-not-printed

# Description 3>&1 1>&2 2>&3 :
# Create a file descriptor 3 that points to 1 (stdout)
# Redirect 1 (stdout) to 2 (stderr)
# Redirect 2 (stderr) to the 3 file descriptor, which is pointed to stdout
# ------------- CASES -------------

# Choice : No selection
if [ -z "$CHOICES" ]
then
  echo -e "${Red}>>> No option was selected ${Color_Off}"

# Choice : Insertion
elif [ "$CHOICES" = "0" ]
then
  # shellcheck disable=SC2068
  JSON_NAME=$(whiptail --inputbox "New name (without space please) : " \
            $HEIGHT $WIDTH \
            3>&1 1>&2 2>&3)

  JSON_KEY=$(whiptail --inputbox "Enter the absolute path where is located the key. The programme will copy it to the right emplacement : " \
              $HEIGHT $WIDTH \
              3>&1 1>&2 2>&3)

  JSON_CLIENT=$(whiptail --inputbox "Client's name : " \
                $HEIGHT $WIDTH \
                3>&1 1>&2 2>&3)

  JSON_HOSTNAME=$(whiptail --inputbox "Hostname : " \
                  $HEIGHT $WIDTH \
                  3>&1 1>&2 2>&3)

  # If all the dialog are completed, test the connexion SSH and add it to
  if [[ ( -n $JSON_NAME ) && ( -n $JSON_KEY ) && ( -n $JSON_CLIENT ) && ( -n $JSON_HOSTNAME )]]
  then
    # If the file exists, then copy the file in .ssh folder
    if [ -f "$JSON_KEY" ]
    then
      sudo cp "$JSON_KEY" "$HOME/.ssh/"
      # Get the name of the file
      NAME_KEY=$(basename "$JSON_KEY")
      # Add these new information to the file
      RESULT=$(jq -s --arg name "$JSON_NAME" \
              --arg key "$NAME_KEY" \
              --arg hostname "$JSON_HOSTNAME" \
              --arg client "$JSON_CLIENT" \
              '.[] |= . + [{ "name" : $name, "key" : $key, "hostname" : hostname, "client": $client }]' "$FILE")
      # Test if the connection works
      # Source : https://myblog.robert.sebille.name/?Tester-si-une-connexion-ssh-est
      echo -e "${BYellow}Please enter your password to test then connect to your server. If it's not working, the process will be canceled...${Color_Off} \n"
      sudo ssh -q -i "$NAME" "$CLIENT"@"$HOSTNAME" echo > /dev/null
      if [ "$?" == "255" ]
      then
        echo -e "${Red}>>> Connexion impossible to $NAME. The inscription is canceled ${Color_Off}"
      elif [ "$?" == "0" ]
      then
        echo -e "${Red}>>> Connexion impossible or failed to $NAME. The inscription is canceled ${Color_Off}"
      else
        sudo ssh -i "$NAME" "$CLIENT"@"$HOSTNAME"
      fi
      # This RESULT command create an array in excess, we need to delete it before insert it in the file
      echo "$RESULT" | jq '.[0]' > "$FILE"
    else
      echo  -e "${Red}>>> The file doesn't exist, the insert is canceled${Color_Off}"
    fi
  else
    echo  -e "${Red}>>> Atleast one dialog wasn't completed, the operation is canceled${Color_Off}"
  fi

# Choice : other choices in list
else
  # Increment to remove the first and second options of the variable and read the JSON file correctly
  CHOICES=$((CHOICES-1))

  NAME=$(jq -cr --argjson CHOICES "$CHOICES" '.[$CHOICES].name' "$FILE")
  HOSTNAME=$(jq -cr --argjson CHOICES "$CHOICES" '.[$CHOICES].hostname' "$FILE")
  KEY=$(jq -cr --argjson CHOICES "$CHOICES" '.[$CHOICES].key' "$FILE")
  CLIENT=$(jq -cr --argjson CHOICES "$CHOICES" '.[$CHOICES].client' "$FILE")
  PORT=$(jq -cr --argjson CHOICES "$CHOICES" '.[$CHOICES].port' "$FILE")

    # In function of data given, adapt the test  SSH connection
    # Test connexion then connect
    echo -e "${BYellow}Please enter your password to test then connect to your server. If it's not working, the process will be canceled...${Color_Off} \n"
    if [ "$PORT" == "null" ] && [ -n "$KEY" ]; then
      # SSH connection without port
      cd "$HOME"/.ssh || exit
      sudo ssh -q -i "$KEY" "$CLIENT"@"$HOSTNAME" echo > /dev/null
      if test_connection ; then
        sudo ssh -q -i "$KEY" "$CLIENT"@"$HOSTNAME"
      fi
    elif [ -n "$PORT" ] && [ "$KEY" == "null"  ]; then
      # SSH connection with port
      # $((PORT + 0)) is used to convert string in int
      sudo ssh "$CLIENT"@"$HOSTNAME" -p $((PORT + 0)) echo > /dev/null
      if test_connection ; then
        sudo ssh "$CLIENT"@"$HOSTNAME" -p $((PORT + 0))
      fi
    else
      echo -e "${Red}>>> Invalid configuration for $NAME. The connection is canceled.${Color_Off}"
    fi
  cd "$ROOT_PROJECT" || exit
fi

