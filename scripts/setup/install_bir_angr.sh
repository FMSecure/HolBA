#!/usr/bin/env bash

# exit immediately if an error happens
set -e

python3 -m pip install angr
python3 -m pip install --upgrade git+https://github.com/FMSecure/bir_angr.git@main

