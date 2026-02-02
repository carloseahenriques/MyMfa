#!/bin/bash

read -p "
Qual conta deseja logar-se?
===========================
" SHIELDACCOUNT

# Esta condicional implementada com uma função OR garante que a passwd do root e do usuário mymfa não sejam alteradas.
[[ ${SHIELDACCOUNT} == root ]] || [[ ${SHIELDACCOUNT} == mymfa ]] && { echo "conta  proibida!"; exit; } || :

# O $({ date +%N; }) logo em segida do ${RANDOM} serve para colocar o tempo local em nanosegundos
# com a finalidade de evitar a repetição de senhas visto que o range do gerador de números pseu-
# do aleatórios vai de 0 a 32767
LOGIN_PASS=$(echo "${SHIELDACCOUNT}:$(echo ${RANDOM}$({ date +%N; }) | sha256sum)")
export LOGIN_PASS=${LOGIN_PASS:(0):(-3)}

# Nessa linha a nova passwd segura é criada/alterada
echo -n ${LOGIN_PASS} | sudo chpasswd -c SHA512 -s 8192

# Quando enviamos a passwd segura para um serviço como o Discord, Telegram, Whatsapp, email ou qualquer outro
# usamos o tor justamente para que esses serviços não tomem conhecimento de qual host esse passwd pertence.
# Nada impede que você use o curl diretamente, sendo apenas uma medida adicional de segurança.
# Nesse caso adotei o Discord, por que além da simplicidade eu já o uso a vários anos para reber alertas de
# todo tipo.
sudo torsocks curl -H "Content-Type: application/json" -d '{"username": "TESTE", "content": ":blue_circle: '${LOGIN_PASS/#*:/}'"}' https://discord.com/api/webhooks/846400894047879208/EL5VE3kNGrBExtMjZn-J07OFFe7tsp7TP7RIt8qCOPPeJr6jORynoAXHUFCdhJIQxuPo

# Essa linha determina por quanto tempo sua nova passwd gerada permanece válida.
# É um implemento de segurança, mas se quiser pode desabilita-lo apenas comentando
# a linha. Defini o tempo como 60 segundos. Notem o nohup. O que ele faz é rodar essa
# linha após esse script haver sido finalizado.
nohup bash -c "{ sleep 60; sudo /usr/bin/passwd -d ${LOGIN_PASS/%:*/}; }" > /dev/null 2>&1 &

exit
