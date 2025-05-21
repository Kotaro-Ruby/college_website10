class DebugController < ApplicationController
    def db_status
      @tables = ActiveRecord::Base.connection.tables
      @condition_count = Condition.count rescue "Error accessing Condition model"
      
      # 州ごとの条件数を確認（実際のモデル構造に合わせて調整）
      @states_data = {}
      if defined?(Condition)
        states = Condition.pluck(:state).uniq
        states.each do |state|
          count = Condition.where(state: state).count
          @states_data[state] = count if count > 0
        end
      end
      
      render json: {
        tables: @tables,
        condition_count: @condition_count,
        states_data: @states_data
      }
    end
  end