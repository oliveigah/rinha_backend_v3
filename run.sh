#!/bin/bash

docker compose -f ./external_resources/rinha-de-backend-2025-payment-processor/containerization/docker-compose.yml up -d

docker compose up --build --force-recreate
