#!/bin/bash

test_connection () {
   if [ "$?" == "255" ]
    then
      echo -e "${Red}>>> Connexion not possible to $NAME (wrong authentification). The execution is canceled ${Color_Off}"
      return 1
    elif [ "$?" == "0" ]
    then
      echo -e "${Red}>>> Connexion not possible or failed to $NAME. The execution is canceled ${Color_Off}"
      return 1
    else
      return 0
    fi
}
