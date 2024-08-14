#!/usr/bin/env bash

# Kill any servers that may be running in the background
sudo pkill -f runserver

cd /home/ubuntu/otaku-house/

# Activate Virtual Environment
python3 -m venv venv

sudo chmod -R a+rwx venv

source venv/bin/activate

# Install pip requirements
install requirements.txt
pip install -r /home/ubuntu/otaku-house/requirements.txt

# Run Django Server
screen -d -m python3 manage.py runserver 0:8000