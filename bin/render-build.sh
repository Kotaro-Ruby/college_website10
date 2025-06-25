#!/usr/bin/env bash
# exit on error
set -o errexit

# Build commands for Render deployment
echo "=== Render Build Script Starting (v3) ==="

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
COLLEGES_WITH_MAJORS=$(bundle exec rails runner "puts Condition.where('pcip_business > 0 OR pcip_engineering > 0 OR pcip_computer_science > 0').count" 2>/dev/null || echo "0")

echo "Colleges with comments: $COLLEGES_WITH_COMMENTS"
echo "Total colleges: $TOTAL_COLLEGES"
echo "Colleges with majors: $COLLEGES_WITH_MAJORS"

# Check if compressed data file exists
if [ -f "db/college_data_compressed.json.gz" ]; then
    echo "=== Compressed data file found, will be processed in releaseCommand ==="
elif [ "$TOTAL_COLLEGES" -lt "50" ]; then
    echo "=== Loading basic sample data ==="
    bundle exec rails render:setup_data
    echo "=== Basic data loaded successfully ==="
elif [ "$COLLEGES_WITH_COMMENTS" -lt "100" ] || [ "$COLLEGES_WITH_MAJORS" -lt "10" ]; then
    echo "=== Loading supplementary data ==="
    SKIP_DETAILED_PROGRAMS=true bundle exec rails college_data:setup_production_fast
    echo "=== Supplementary data loaded successfully ==="
else
    echo "=== Data already exists, skipping setup ==="
fi

echo "=== Render Build Script Completed ==="