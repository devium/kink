#!/usr/bin/env python3

from signedjson.key import generate_signing_key, write_signing_keys

import secrets
import string
import sys

def main():
  key_id = 'a_' + ''.join(secrets.choice(string.ascii_letters) for _ in range(4)) 
  key = generate_signing_key(key_id)
  write_signing_keys(sys.stdout, (key,))

if __name__ == '__main__':
  main()
