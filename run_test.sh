#!/bin/bash

export K6_WEB_DASHBOARD=true
export K6_WEB_DASHBOARD_PORT=5665
export K6_WEB_DASHBOARD_PERIOD=2s
export K6_WEB_DASHBOARD_OPEN=true
export K6_WEB_DASHBOARD_EXPORT='report.html'

k6 run -e MAX_REQUESTS=4000 external_resources/rinha-de-backend-2025/rinha-test/rinha.js
