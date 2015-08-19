#!/bin/bash
# Attempts to execute JSON.sh, preferring the directory
# where the current script is located, which makes it
# unnecessary to expose JSON.sh in $PATH directories.
JSON() {
  PATH="$(dirname "$(readlink -f $0)")":"$PATH" JSON.sh
}

# Finds the value of $1 in the output of JSON
parse() {
  grep "$1" | sed "s/$1\s\+//" | sed 's/^"\(.*\)"$/\1/'
}

# Reads one line from stdin, computes its hash, colors
# the line based on the hash and flushes it back to stdout
hashColor() {
  read line
  printf "%b\n" "\033[1m\033[3$((
    $(
      printf '%s' "$line" | while IFS= read -r -n1 char; do
        printf "%d\n" "'$char"
      done | awk '{s+=$1} END {print s}'
    ) % 6 + 1
  ))m${line}\033[m"
}

# Find out, whether we are in a terminal
[ -t 1 ]; TERM=$(if [ $? = 0 ]; then
  echo true
else
  echo false
fi)

if [ -z "$1" ]; then # Print usage info
  printf '%s\n' "Usage: $0 AuctionID"
else # Start watching
  
  # Parse the auction id out of $1
  ID="$(printf '%s' "$1" | sed 's#.*/\([0123456789]*\)?.*#\1#')"

  # Create a temporary file to store ebay responses
  JSON="$(mktemp)"
  trap 'exit 1' 1 2 3 6 9 14 15
  trap 'rm '"$JSON"'; $TERM && echo' EXIT

  while true; do

    # Try to to grab and parse the JSON response
    curl -s "http://www.ebay.com/itm/ws/eBayISAPI.dll?ViewItemLite&dl=3&item=$ID" | JSON > "$JSON"
    [ $(wc -l < "$JSON") = 0 ] && continue
    DAY="$(<"$JSON" parse '\["ViewItemLiteResponse","Item",0,"TimeLeft","DaysLeft"\]')"
    HRS="$(<"$JSON" parse '\["ViewItemLiteResponse","Item",0,"TimeLeft","HoursLeft"\]')"
    MIN="$(<"$JSON" parse '\["ViewItemLiteResponse","Item",0,"TimeLeft","MinutesLeft"\]')"
    SEC="$(<"$JSON" parse '\["ViewItemLiteResponse","Item",0,"TimeLeft","SecondsLeft"\]')"
    BIDDER="$(<"$JSON" parse '\["ViewItemLiteResponse","Item",0,"HighBidder","Name"\]')"
    PRICE="$(<"$JSON" parse '\["ViewItemLiteResponse","Item",0,"CurrentPrice","MoneyStandard"\]')"

    # If there's a price update, store it and output a new line
    if ! [ "$PRICE" = "$LAST" ]; then
      # If FD 3 is open, send price updates into it
      (printf '%s\n' "$PRICE" 1>&3) 2>&-
      ! [ -z "$LAST" ] && echo
      LAST="$PRICE"
      DATE="$(date '+%Y/%m/%d %H:%M:%S')"
    else # Otherwise, rewrite the current line (if we're in a term)
      $TERM && printf "%b\n" "\033[1K\033[1A"
    fi

    # Print the details
    printf '%s — %s' "$DATE" "$PRICE"
    if [ -n "$BIDDER" ]; then
      printf ' (%s)' "$(echo $BIDDER | if $TERM; then hashColor; else cat; fi)"
    fi

    # Exit once the auction has finished
    if [ $(<"$JSON" parse '\["ViewItemLiteResponse","Item",0,"IsFinalized"\]') = true ]; then
      if [ -n "$BIDDER" ]; then
        printf ', finished'
      else
        printf ', expired'
      fi
      $TERM || echo # If we're not in a term, output a new line
      exit
    else
      printf ', '
    fi

    # Otherwise, print the rest of the details
    [ -z "$DAY" -o -z "$HRS" -o -z "$MIN" -o -z "$SEC" ] && continue
    LEFT=$(($DAY * 86400 + $HRS * 3600 + $MIN * 60 + $SEC))
         if ! [ $DAY = "0" ]; then printf '%dd %02dh %02dm %02ds left' $DAY $HRS $MIN $SEC
    else if ! [ $HRS = "0" ]; then printf '%dh %02dm %02ds left' $HRS $MIN $SEC
    else if ! [ $MIN = "0" ]; then printf '%dm %02ds left' $MIN $SEC
    else                           printf '%ds left' $SEC; fi; fi; fi
    $TERM || echo # If we're not in a term, output a new line

    # Sleep for a variable amount of time
         if [ "$LEFT" -gt "1800" ]; then sleep 30s
    else if [ "$LEFT" -gt "300"  ]; then sleep  5s
    else                                 sleep  1s; fi; fi
  
  done
fi
