#!/usr/bin/env bash
NUM_WORDS=4
NUM_SECRETS=16
WORDS=$(curl -L https://raw.githubusercontent.com/bitcoin/bips/master/bip-0039/english.txt | sed "s#.#\u&#")

export NUM_WORDS
export WORDS

for i in $(seq $NUM_SECRETS); do
    printf "%s%s" $(echo "$WORDS" | shuf -n $NUM_WORDS)
    printf "\n"
done
