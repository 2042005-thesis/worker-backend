# Voting Apps: Worker Backend Service
A simple distributed application running across multiple Docker containers.
This solution uses Python, Node.js, .NET, with Redis for messaging and Postgres for storage.

## Dockerhub
* Build: `docker build -t taufiq14s/voting-apps-worker-backend:tagname`
* Push: `docker push taufiq14s/voting-apps-worker-backend:tagname`
* Repository: https://hub.docker.com/r/taufiq14s/voting-apps-worker-backend

## Architecture

* A [Caddy 2](https://hub.docker.com/_/caddy) is a powerful reverse proxy, enterprise-ready, open source web server with automatic HTTPS written in Go
* A front-end web app in [Python](/vote) which lets you vote between two options
* A [Redis](https://hub.docker.com/_/redis/) which collects new votes
* A [.NET](/worker/) worker which consumes votes and stores them in…
* A [Postgres](https://hub.docker.com/_/postgres/) database backed by a Docker volume
* A [Node.js](/result) web app which shows the results of the voting in real time

## Notes

The voting application only accepts one vote per client browser. It does not register additional votes if a vote has already been submitted from a client.

This isn't an example of a properly architected perfectly designed distributed app... it's just a simple
example of the various types of pieces and languages you might see (queues, persistent data, etc), and how to
deal with them in Docker at a basic level.# worker-backend
