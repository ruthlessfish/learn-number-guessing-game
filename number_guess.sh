#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

secret_number=$((1 + RANDOM % 1000))

echo "Enter your username: "
read username

if [[ ${#username} -gt 22 ]]; then
  echo "Error: Username must be 22 characters or less."
  exit 1
fi

user=$($PSQL "select username, games_played, best_game from users where username='${username}' limit 1");
games_played=0
best_game=0

if [[ -z $user ]]; then
  create_user=$($PSQL "insert into users(username) values('${username}')");
  if [[ $create_user ]]; then
    echo "Welcome, ${username}! It looks like this is your first time here."
  fi
else
  oldIFS=$IFS
  IFS='|'
  read -ra cols <<< "$user"
  IFS=$oldIFS
  games_played="${cols[1]}"
  best_game="${cols[2]}"
  echo "Welcome back, ${username}! You have played ${games_played} games, and your best game took ${best_game} guesses."
fi

found=0
number_of_guesses=1
msg="Guess the secret number between 1 and 1000: "
while [[ $found -eq 0 ]]; do
  echo "$msg"
  read user_guess

  if ! [[ $user_guess =~ ^[0-9]+$ ]]; then
    msg="That is not an integer, guess again:"
    continue;
  fi

  if [[ $user_guess -lt 1 || $user_guess -gt 1000 ]]; then
    msg="Guess should be between 1 and 1000, guess again:"
    continue;
  fi

  number_of_guesses=$(($number_of_guesses+1));

  if [[ $user_guess -gt $secret_number ]]; then
    msg="It's lower than that, guess again:"
    continue;
  fi
  
  if [[ $user_guess -lt $secret_number ]]; then
    msg="It's higher than that, guess again:";
    continue;
  fi

  if [[ $user_guess -eq $secret_number ]]; then
    found=1
  fi
done

games_played=$(($games_played+1))

if [[ $best_game -eq 0 || $number_of_guesses -lt $best_game ]]; then
  best_game=$number_of_guesses
fi

update_user=$($PSQL "update users set games_played=${games_played}, best_game=$best_game where username='${username}'")

echo "You guessed it in ${number_of_guesses} tries. The secret number was ${secret_number}. Nice job!"; 
