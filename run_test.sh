#!/bin/bash

k6 run -e MAX_REQUESTS=550 external_resources/rinha-de-backend-2025/rinha-test/rinha.js
