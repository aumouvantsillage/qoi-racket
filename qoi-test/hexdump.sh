#!/usr/bin/env bash
hexdump -e '16/1 "%02X " "\n"' $1
