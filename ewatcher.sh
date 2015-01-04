#!/bin/bash
# A lightweight cli ebay bidding watcher
#
# A copypasta of the commit 1df36d65535bd8131a3dac1a7d554a55d2ae61fa
# of <https://github.com/dominictarr/JSON.sh>
#
# The MIT License
# Copyright (c) 2011 Dominic Tarr
# Permission is hereby granted, free of charge,
# to any person obtaining a copy of this software and
# associated documentation files (the "Software"), to
# deal in the Software without restriction, including
# without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom
# the Software is furnished to do so,
# subject to the following conditions:
# The above copyright notice and this permission notice
# shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
# ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# Apache License, Version 2.0
# Copyright (c) 2011 Dominic Tarr
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
JSON() {
  throw () {
    echo "$*" >&2
    exit 1
  }

  BRIEF=0
  LEAFONLY=0
  PRUNE=0

  usage() {
    echo
    echo "Usage: JSON.sh [-b] [-l] [-p] [-h]"
    echo
    echo "-p - Prune empty. Exclude fields with empty values."
    echo "-l - Leaf only. Only show leaf nodes, which stops data duplication."
    echo "-b - Brief. Combines 'Leaf only' and 'Prune empty' options."
    echo "-h - This help text."
    echo
  }

  parse_options() {
    set -- "$@"
    local ARGN=$#
    while [ $ARGN -ne 0 ]
    do
      case $1 in
        -h) usage
            exit 0
        ;;
        -b) BRIEF=1
            LEAFONLY=1
            PRUNE=1
        ;;
        -l) LEAFONLY=1
        ;;
        -p) PRUNE=1
        ;;
        ?*) echo "ERROR: Unknown option."
            usage
            exit 0
        ;;
      esac
      shift 1
      ARGN=$((ARGN-1))
    done
  }

  awk_egrep () {
    local pattern_string=$1

    gawk '{
      while ($0) {
        start=match($0, pattern);
        token=substr($0, start, RLENGTH);
        print token;
        $0=substr($0, start+RLENGTH);
      }
    }' pattern=$pattern_string
  }

  tokenize () {
    local GREP
    local ESCAPE
    local CHAR

    if echo "test string" | egrep -ao --color=never "test" &>/dev/null
    then
      GREP='egrep -ao --color=never'
    else
      GREP='egrep -ao'
    fi

    if echo "test string" | egrep -o "test" &>/dev/null
    then
      ESCAPE='(\\[^u[:cntrl:]]|\\u[0-9a-fA-F]{4})'
      CHAR='[^[:cntrl:]"\\]'
    else
      GREP=awk_egrep
      ESCAPE='(\\\\[^u[:cntrl:]]|\\u[0-9a-fA-F]{4})'
      CHAR='[^[:cntrl:]"\\\\]'
    fi

    local STRING="\"$CHAR*($ESCAPE$CHAR*)*\""
    local NUMBER='-?(0|[1-9][0-9]*)([.][0-9]*)?([eE][+-]?[0-9]*)?'
    local KEYWORD='null|false|true'
    local SPACE='[[:space:]]+'

    $GREP "$STRING|$NUMBER|$KEYWORD|$SPACE|." | egrep -v "^$SPACE$"
  }

  parse_array () {
    local index=0
    local ary=''
    read -r token
    case "$token" in
      ']') ;;
      *)
        while :
        do
          parse_value "$1" "$index"
          index=$((index+1))
          ary="$ary""$value" 
          read -r token
          case "$token" in
            ']') break ;;
            ',') ary="$ary," ;;
            *) throw "EXPECTED , or ] GOT ${token:-EOF}" ;;
          esac
          read -r token
        done
        ;;
    esac
    [ "$BRIEF" -eq 0 ] && value=`printf '[%s]' "$ary"` || value=
    :
  }

  parse_object () {
    local key
    local obj=''
    read -r token
    case "$token" in
      '}') ;;
      *)
        while :
        do
          case "$token" in
            '"'*'"') key=$token ;;
            *) throw "EXPECTED string GOT ${token:-EOF}" ;;
          esac
          read -r token
          case "$token" in
            ':') ;;
            *) throw "EXPECTED : GOT ${token:-EOF}" ;;
          esac
          read -r token
          parse_value "$1" "$key"
          obj="$obj$key:$value"        
          read -r token
          case "$token" in
            '}') break ;;
            ',') obj="$obj," ;;
            *) throw "EXPECTED , or } GOT ${token:-EOF}" ;;
          esac
          read -r token
        done
      ;;
    esac
    [ "$BRIEF" -eq 0 ] && value=`printf '{%s}' "$obj"` || value=
    :
  }

  parse_value () {
    local jpath="${1:+$1,}$2" isleaf=0 isempty=0 print=0
    case "$token" in
      '{') parse_object "$jpath" ;;
      '[') parse_array  "$jpath" ;;
      # At this point, the only valid single-character tokens are digits.
      ''|[!0-9]) throw "EXPECTED value GOT ${token:-EOF}" ;;
      *) value=$token
         isleaf=1
         [ "$value" = '""' ] && isempty=1
         ;;
    esac
    [ "$value" = '' ] && return
    [ "$LEAFONLY" -eq 0 ] && [ "$PRUNE" -eq 0 ] && print=1
    [ "$LEAFONLY" -eq 1 ] && [ "$isleaf" -eq 1 ] && [ $PRUNE -eq 0 ] && print=1
    [ "$LEAFONLY" -eq 0 ] && [ "$PRUNE" -eq 1 ] && [ "$isempty" -eq 0 ] && print=1
    [ "$LEAFONLY" -eq 1 ] && [ "$isleaf" -eq 1 ] && \
      [ $PRUNE -eq 1 ] && [ $isempty -eq 0 ] && print=1
    [ "$print" -eq 1 ] && printf "[%s]\t%s\n" "$jpath" "$value"
    :
  }

  parse () {
    read -r token
    parse_value
    read -r token
    case "$token" in
      '') ;;
      *) throw "EXPECTED EOF GOT $token" ;;
    esac
  }

  if ([ "$0" = "$BASH_SOURCE" ] || ! [ -n "$BASH_SOURCE" ]);
  then
    parse_options "$@"
    tokenize | parse
  fi
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
  printf '%s\n' "Watching bids for auction #$ID:"

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

    # If there's a price update, store it and output a new line
    PRICE="$(<"$JSON" parse '\["ViewItemLiteResponse","Item",0,"CurrentPrice","Amount"\]')"
    if ! [ "$PRICE" = "$LAST" ]; then
      ! [ -z "$LAST" ] && echo
      LAST="$PRICE"
      DATE="$(date '+%Y/%m/%d %H:%M:%S')"
    else # Otherwise, rewrite the current line (if we're in a term)
      $TERM && printf "%b\n" "\033[1K\033[1A"
    fi

    # Print the details
    printf '%s' "$DATE – $(<$JSON parse '\["ViewItemLiteResponse","Item",0,"CurrentPrice","MoneyStandard"\]') ("
    printf '%s' "$(<$JSON parse '\["ViewItemLiteResponse","Item",0,"HighBidder","Name"\]' |
      if $TERM; then hashColor; else cat; fi)"')'

    # Exit once the auction has finished
    if [ $(<$JSON parse '\["ViewItemLiteResponse","Item",0,"IsFinalized"\]') = true ]; then
      printf ', winner'
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
