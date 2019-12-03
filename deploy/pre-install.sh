#!/usr/bin/env bash

command -v gem || (sudo apt-get update -yq; sudo apt-get install -y ruby-dev; sudo gem install dpl)