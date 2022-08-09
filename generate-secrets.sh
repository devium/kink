#!/usr/bin/env bash
NUM_WORDS=4
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
WORDS=$(curl -L https://raw.githubusercontent.com/bitcoin/bips/master/bip-0039/english.txt | sed "s#.#\u&#")
FILE=$SCRIPT_DIR/secrets/secrets.$ANSIBLE_STAGE.yml

export NUM_WORDS
export WORDS

sed -ri 's#(.*)<generate>(.*)#printf "%s%s%s" "\1" $(echo "$WORDS" | shuf -n $NUM_WORDS) "\2"#e' $FILE
