#!/bin/bash

# ATTENTION :
# - Execute the file under `bash ssh_keyloading.sh` and not `sh ./ssh_keyloading.sh`
#   for compatibility reason
# - No space in JSON elements, whitespace aren't ignored in the condition in whiptail command

# ------------- INSTALL PACKAGE NEEDED -------------
FILE="$PWD"/keys.json
ROOT_PROJECT=$PWD

source colors.sh

clear
read -p "Do you want to install the last version of Bash ? Y/n " COMMAND_BASH
if [ "$COMMAND_BASH" = "Y" ]; then
  sudo apt update
  sudo apt-get install --only-upgrade bash
  else
    echo -e "${Green}Quit bash update...${Color_Off}"
fi

read -p "${LIGHT_GREEN}Do you want to install jq ? Y/n ${NO_COLOR}" COMMAND_JQ
if [ "$COMMAND_JQ" = "Y" ]; then
  sudo apt install jq
  else
    echo -e "${Green}Quit jq installation...${Color_Off}"
fi


# ------------- DIMENSION DIALOG -------------
HEIGHT=0
WIDTH=0
CHOICE_HEIGHT=4
COUNT_OPTION=$(jq '. | length' "$PWD"/keys.json)
#backtitle="SSH Connexion"
TITLE="SSH connexion"
MENU="Select the ssh connexion you want to use. If you want to add a new connexion, remember to add the ssh key in ssh folder (~/.ssh for Linux)"

# ------------- ADDING OPTIONS DIALOG -------------
DESCRIPTION=""
COUNTER=0
# To resolve whitespace who dictates to foreach that any word is a new element, we use this command
# Source : https://unix.stackexchange.com/questions/459419/why-are-spaces-echoing-as-newlines
while IFS= read -r line; do
  DESCRIPTION+=("$COUNTER $line")
  COUNTER=$((COUNTER+1))
done < <(jq -cr '.[].name ' < "keys.json")

# ------------- INITIALIZATION DIALOG -------------
ARRAY_NAME=$(jq  '.[].name' $PWD/keys.json | jq --slurp '.[]')
# shellcheck disable=SC2068
CHOICES=$(whiptail --title "$TITLE" \
          --backtitle "Menu" --menu \
          --nocancel "$MENU" 20 80 10 \
          `for i in ${!DESCRIPTION[@]}; do echo "${DESCRIPTION[$i]}"; done` \
          3>&1 1>&2 2>&3)
#Other solution ? : https://unix.stackexchange.com/questions/479552/dynamic-options-on-whiptail-got-not-printed

# Description 3>&1 1>&2 2>&3 :
# Create a file descriptor 3 that points to 1 (stdout)
# Redirect 1 (stdout) to 2 (stderr)
# Redirect 2 (stderr) to the 3 file descriptor, which is pointed to stdout
# ------------- CASES -------------
if [ -z "$CHOICES" ]
then
  echo "No option was selected"
else
  NAME=$(jq -cr --argjson CHOICES "$CHOICES" '.[$CHOICES].key' "$FILE")
  cd "$HOME"/.ssh || exit
  if test -f "$NAME"; then
    PORT=$(jq -cr --argjson CHOICES "$CHOICES" '.[$CHOICES].port' "$FILE")
    CLIENT=$(jq -cr --argjson CHOICES "$CHOICES" '.[$CHOICES].client' "$FILE")
    sudo ssh -i "$NAME" "$CLIENT"@"$PORT"
    else
      echo "$NAME do not exists"
  fi
  cd "$ROOT_PROJECT" || exit
fi

