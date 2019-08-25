#!/bin/sh

# Set up observer to run the experiment when any file changes
ls **/*.ex **.exs docker-compose.yaml Dockerfile | entr bash -c "docker-compose build && docker-compose run chaos; docker-compose down"
