#!/usr/bin/env bash
# exit on error
set -o errexit

# Build commands for Render deployment
echo "=== Render Build Script Starting (v2) ==="

# Install dependencies
bundle install

# Precompile assets
bundle exec rails assets:precompile

# Run database migrations
bundle exec rails db:migrate

# Check if data setup is needed
echo "=== Checking if data setup is needed ==="

COLLEGES_WITH_COMMENTS=$(bundle exec rails runner "puts Condition.where.not(comment: [nil, '']).count" 2>/dev/null || echo "0")
TOTAL_COLLEGES=$(bundle exec rails runner "puts Condition.count" 2>/dev/null || echo "0")

echo "Colleges with comments: $COLLEGES_WITH_COMMENTS"
echo "Total colleges: $TOTAL_COLLEGES"

if [ "$TOTAL_COLLEGES" -lt "100" ]; then
    echo "=== Importing base college data from Excel ==="
    bundle exec rails import:base_colleges
    
    echo "=== Loading seed data (comments and majors) ==="
    bundle exec rails db:seed
    
    echo "=== All data loaded successfully ==="
elif [ "$COLLEGES_WITH_COMMENTS" -lt "100" ]; then
    echo "=== Loading seed data only (comments and majors) ==="
    bundle exec rails db:seed
    
    echo "=== Seed data loaded successfully ==="
else
    echo "=== Data already exists, skipping setup ==="
fi

echo "=== Render Build Script Completed ==="