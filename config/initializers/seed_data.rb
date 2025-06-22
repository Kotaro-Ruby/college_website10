# Load initial data if database is empty
if Rails.env.production? && defined?(Rails::Server)
  Rails.application.config.after_initialize do
    if Condition.count == 0
      Rails.logger.info "Database is empty, loading seed data..."
      load Rails.root.join('db/seeds.rb')
    else
      Rails.logger.info "Database already has #{Condition.count} records"
    end
  end
end