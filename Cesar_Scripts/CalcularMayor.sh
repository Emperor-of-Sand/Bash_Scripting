#!/bin/bash

array=($@);
cantidad=${#array[@]};

numeroMayor=0;
for ((i=0;i<$cantidad;i++))
do
    numero=${array[$i]}

    if [ $numero -gt $numeroMayor ]; then
        numeroMayor=$numero;
    fi
done


echo "El numero mayor es: " $numeroMayor