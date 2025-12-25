# College Spark

A multilingual university search service for students exploring study abroad opportunities.

## Features

- **University Search**: Search 1,000+ US universities and 39 Australian universities
- **Advanced Filtering**: Filter by state, tuition, SAT/ACT scores, majors, and more
- **Japanese/English Support**: Search in both languages with automatic translation
- **Favorites & Comparison**: Save and compare universities side by side
- **View History**: Track recently viewed universities
- **Admin Dashboard**: Manage news, blogs, and consultation requests

## Tech Stack

- **Backend**: Ruby on Rails 8.0
- **Database**: PostgreSQL (production), SQLite (development)
- **Frontend**: Bootstrap 5, Hotwire (Turbo/Stimulus), JavaScript ES6+
- **Authentication**: Google OAuth 2.0
- **Deployment**: Render.com
- **CI/CD**: GitHub Actions

## Getting Started

### Prerequisites

- Ruby 3.3+
- Node.js 18+
- PostgreSQL (for production-like environment)

### Installation

```bash
# Clone the repository
git clone https://github.com/Kotaro-Ruby/college_website10.git
cd college_website10

# Install dependencies
bundle install

# Setup database
bin/rails db:create db:migrate

# Start the server
bin/rails server
```

### Running Tests

```bash
# Run all tests
bin/rails test

# Run model tests only
bin/rails test test/models/

# Run controller tests only
bin/rails test test/controllers/

# Run with verbose output
bin/rails test -v
```

### Code Quality

```bash
# Run RuboCop
bin/rubocop

# Run Brakeman security scan
bin/brakeman
```

## Project Structure

```
app/
├── controllers/     # Request handling
├── models/          # Business logic
├── views/           # ERB templates
├── helpers/         # View helpers
└── services/        # Service objects

lib/
└── tasks/           # 50+ Rake tasks for data management

test/
├── models/          # 253 model tests
├── controllers/     # Controller integration tests
└── fixtures/        # Test data
```

## Data Sources

- [College Scorecard API](https://collegescorecard.ed.gov/data/) - US university data
- [CRICOS](https://cricos.education.gov.au/) - Australian university data
- [Wikimedia Commons API](https://commons.wikimedia.org/) - University images

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is proprietary software.
