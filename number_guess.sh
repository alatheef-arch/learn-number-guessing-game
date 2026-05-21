#!/bin/bash

# Main PostgreSQL connection string variable
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Generate the random target number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# 1. Prompt for and read the username
echo "Enter your username:"
read USERNAME

# Fetch user_id from the database to see if the user exists
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME';")

if [[ -z $USER_ID ]]
then
  # Scenario A: Brand new user branch
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  
  # Insert new user into the database
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME');")
  # Retrieve the newly generated user_id for match logging
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME';")
else
  # Scenario B: Returning user branch - aggregate match summaries 
  GAMES_PLAYED=$($PSQL "SELECT COUNT(*) FROM games WHERE user_id=$USER_ID;")
  BEST_GAME=$($PSQL "SELECT MIN(number_of_guesses) FROM games WHERE user_id=$USER_ID;")
  
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# 2. Initiate the game loop
echo "Guess the secret number between 1 and 1000:"
GUESS_COUNT=0

while true
do
  read GUESS
  
  # 3. Type validation FIRST: If it's not a positive integer, reject it immediately
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    continue
  fi
  
  # 4. Only increment the guess counter if the input is a valid integer
  ((GUESS_COUNT++))
  
  # 5. Evaluate game target logic
  if [[ $GUESS -eq $SECRET_NUMBER ]]
  then
    echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"
    break
  elif [[ $GUESS -gt $SECRET_NUMBER ]]
  then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
done

# 6. Log final game results into database upon successful completion
INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(user_id, number_of_guesses) VALUES($USER_ID, $GUESS_COUNT);")