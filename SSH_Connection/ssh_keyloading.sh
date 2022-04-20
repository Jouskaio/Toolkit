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
COUNT_OPTION=$(($(jq '. | length' "$PWD"/keys.json) + 2))
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
if [ -z "$CHOICES" ]
then
  echo "${Red}>>> No option was selected ${Color_Off}"
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

  JSON_PORT=$(whiptail --inputbox "Port : " \
                  $HEIGHT $WIDTH \
                  3>&1 1>&2 2>&3)

  # If all the dialog ae completed, test the connexion SSH and add it to
  if [[ ( -n $JSON_NAME ) && ( -n $JSON_KEY ) && ( -n $JSON_CLIENT ) && ( -n $JSON_PORT )]]
  then
    sudo cp "$JSON_KEY" "$HOME/.ssh/"
    NAME_KEY=$(basename "$JSON_KEY")
    # Exemple : jq -n --arg appname "$appname" '{apps: [ {name: $appname, script: "./cms/bin/www", watch: false}]}' > process.json
  else
    echo "${Red}>>> One dialog wasn't completed, the operation is canceled${Color_Off}"
  fi
  # Si JSON_KEY, JSON_NAME, JSON_PORT, JSON_CLIENT n'ont pas été annulé alors faire :
  # - copier la clé dans /.ssh
  # - récupérer le lien et conserver que le nom pour l'ajouter au key du nouvel élement JSON après le test de connexion (do `basename $JSON_KEY`)
  # - Tester la connexion. Si correct : Ajouter les autres éléments au JSON, sinon demander à refaire
else
  # Increment to remove the first and second options of the variable and read the JSON file correctly
  CHOICES=$((CHOICES-2))
  NAME=$(jq -cr --argjson CHOICES "$CHOICES" '.[$CHOICES].key' "$FILE")
  cd "$HOME"/.ssh || exit
  if test -f "$NAME"; then
    PORT=$(jq -cr --argjson CHOICES "$CHOICES" '.[$CHOICES].port' "$FILE")
    CLIENT=$(jq -cr --argjson CHOICES "$CHOICES" '.[$CHOICES].client' "$FILE")
    sudo ssh -i "$NAME" "$CLIENT"@"$PORT"
    else
      echo "${Red}>>> $NAME does not exist${Color_Off}"
  fi
  cd "$ROOT_PROJECT" || exit
fi

