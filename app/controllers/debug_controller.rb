class DebugController < ApplicationController
    def db_status
      tables = ActiveRecord::Base.connection.tables
      counts = {}
      
      if tables.include?("conditions")
        counts["conditions"] = Condition.count
      end
      
      render json: { 
        tables: tables, 
        counts: counts,
        environment: Rails.env
      }
    end
  end