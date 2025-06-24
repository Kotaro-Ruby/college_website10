#!/usr/bin/env bash
# exit on error
set -o errexit

# Build commands for Render deployment
echo "=== Render Build Script Starting ==="

# Install dependencies
bundle install

# Precompile assets
bundle exec rails assets:precompile

# Run database migrations
bundle exec rails db:migrate

# Check if this is the first deployment or if we need to setup data
echo "=== Checking if data setup is needed ==="

# Count colleges with comments as a proxy for whether data is already set up
COLLEGES_WITH_COMMENTS=$(bundle exec rails runner "puts Condition.where.not(comment: [nil, '']).count" 2>/dev/null || echo "0")
TOTAL_COLLEGES=$(bundle exec rails runner "puts Condition.count" 2>/dev/null || echo "0")

echo "Colleges with comments: $COLLEGES_WITH_COMMENTS"
echo "Total colleges: $TOTAL_COLLEGES"

if [ "$COLLEGES_WITH_COMMENTS" -lt "100" ] && [ "$TOTAL_COLLEGES" -gt "100" ]; then
    echo "=== Adding missing comments and major data ==="
    # Add comments to existing colleges
    bundle exec rails import:add_comments_only
    
    echo "=== Adding some major data (limited to avoid timeout) ==="
    # Add major data for a subset of colleges to avoid timeouts
    bundle exec rails runner "
      require 'net/http'
      require 'json'
      require_relative 'lib/college_major_importer'
      
      api_key = ENV['COLLEGE_SCORECARD_API_KEY']
      if api_key
        count = 0
        Condition.where('pcip_business IS NULL OR pcip_business = 0').limit(100).each do |college|
          if CollegeMajorImporter.fetch_and_update_major_data(college.college, api_key)
            count += 1
          end
          sleep(0.1)
          break if count >= 50  # Limit to 50 colleges to avoid timeout
        end
        puts \"Added major data for #{count} colleges\"
      end
    "
else
    echo "=== Data already exists or no colleges found, skipping setup ==="
fi

echo "=== Render Build Script Completed ==="