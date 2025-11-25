#!/bin/bash
# Script to execute SQL in Supabase using Management API
# Requires SUPABASE_ACCESS_TOKEN environment variable
# Get token from: https://app.supabase.com/account/tokens

PROJECT_REF="jlyamkhkgjkktiypywkk"
SQL_FILE="CREATE_ACTIVITIES_TABLE.sql"

if [ -z "$SUPABASE_ACCESS_TOKEN" ]; then
    echo "Error: SUPABASE_ACCESS_TOKEN environment variable is not set"
    echo "Get your token from: https://app.supabase.com/account/tokens"
    exit 1
fi

# Read SQL file and escape for JSON
SQL_CONTENT=$(cat "$SQL_FILE" | jq -Rs .)

# Execute SQL via Management API
curl -X POST \
  "https://api.supabase.com/v1/projects/${PROJECT_REF}/database/query" \
  -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"query\": ${SQL_CONTENT}}"



