#!/bin/bash
# Linting para todos los servicios

# Lint Dockerfiles
hadolint vote/Dockerfile
hadolint worker/Dockerfile
hadolint result/Dockerfile

# Lint vote (Java)
cd services/vote
mvn checkstyle:check

# Lint worker (Go)
cd ../worker
golangci-lint run

# Lint result (Node.js)
cd ../result
npm run lint

echo "All linters passed"