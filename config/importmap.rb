# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "controllers/index", to: "controllers/index.js"
pin "controllers/application", to: "controllers/application.js"
pin "controllers/application_controller", to: "controllers/application_controller.js"
pin "controllers/hello_controller", to: "controllers/hello_controller.js"
pin "header_dropdown", preload: true
