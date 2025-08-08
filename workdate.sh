#!/bin/bash

month_ago=0

# Define the start date as 3 months in the past
start_date=$(date -d "`date +%Y%m01` -$month_ago month" +%Y-%m-%d)
# Define the end date as today or last day of the month
end_date=$(date -d "$start_date +1 month -1 day" +%Y-%m-%d)

# Generate all dates within the range
current_date="$start_date"

echo "Start Date: $(LC_ALL=en_US.utf8 date -d "$start_date" +"%a %b %e") "
echo "End Date: $(LC_ALL=en_US.utf8 date -d "$end_date" +"%a %b %e") "
echo "starting with the start date: $current_date"

# Iterate over each day from start date to end date
while [ "$current_date" != "$end_date" ]; do
  current_date_formatted=$(LC_ALL=en_US.utf8 date -d "$current_date" +"%a %b %e")
  current_date_print=$(LC_ALL=en_US.utf8 date -d "$current_date" +"%a-%b-%e" | tr -d ' ')

  # Get the login records for the current date
  logins=$(last | grep "$current_date_formatted" | grep -v still)

  if [ -z "$logins" ]; then
    # No logins, use suspend/return times if available
    first_login=""
    last_logout=""
  else
    # Get the first and last login times for the date
    first_login=$(echo "$logins" | cut -c50- | tail -n 1 | cut -c2-6)
    last_logout=$(echo "$logins" | grep -v down | cut -c50- | head -n 1 | cut -c10-14)
  fi

  # Extract suspend and return times for the day
  earliest_return_time=$(journalctl -t systemd-sleep --since "$current_date 04:00:00" --until "$current_date 10:59:59" \
      | grep "System returned from sleep state" \
      | head -n 1 \
      | awk '{print $3}' \
      | cut -d: -f1,2)

  latest_suspend_time=$(journalctl -t systemd-sleep --since "$current_date 00:00:00" --until "$current_date 19:59:59" \
      | grep "Entering sleep state 'suspend'" \
      | tail -n 1 \
      | awk '{print $3}' \
      | cut -d: -f1,2)

  # compare the login times with suspend/return times 
  if [ -z "$first_login" ] && [ -n "$earliest_return_time" ]; then
    first_login="\033[32m$earliest_return_time\033[0m"
  fi
 # if both exist, take the earliest return time
  if [ -n "$first_login" ] && [ -n "$earliest_return_time" ]; then
    if [[ "$earliest_return_time" < "$first_login" ]]; then
      first_login="\033[32m$earliest_return_time\033[0m"
      else
      first_login="\033[32m$first_login\033[0m"
    fi
  fi



  if [ -z "$last_logout" ] && [ -n "$latest_suspend_time" ]; then
    last_logout="\033[32m$latest_suspend_time\033[0m"
  fi
   # if both exist, take the latest return time
  if [ -n "$last_logout" ] && [ -n "$latest_suspend_time" ]; then
    if [[ "$latest_suspend_time" > "$last_logout" ]]; then
      last_logout="\033[32m$latest_suspend_time\033[0m"
    else
      last_logout="\033[32m$last_logout\033[0m"
    fi
  fi

# add additional times for working between 20:00 and 24:00
  # Extract suspend and return times for the day
  evening_return_time=$(journalctl -t systemd-sleep --since "$current_date 20:00:00" --until "$current_date 23:59:59" \
      | grep "System returned from sleep state" \
      | head -n 1 \
      | awk '{print $3}' \
      | cut -d: -f1,2)

  evening_suspend_time=$(journalctl -t systemd-sleep --since "$current_date 20:00:00" --until "$current_date 23:59:59" \
      | grep "Entering sleep state 'suspend'" \
      | tail -n 1 \
      | awk '{print $3}' \
      | cut -d: -f1,2)

  # Print the date with login times
    echo -e "$current_date_print\t$first_login\t$last_logout\t$evening_return_time\t$evening_suspend_time"


  # Increment the day
  current_date=$(date -I -d "$current_date + 1 day")
done

echo "use data: split text to columns to copy into excel"
echo "additionally here are the suspend times for the last month"
