// Import and register all your controllers from the importmap under controllers/*

import { application } from "controllers/application"

// Import controllers manually to avoid loading errors
import ApplicationController from "controllers/application_controller"
import HelloController from "controllers/hello_controller"

application.register("application", ApplicationController)
application.register("hello", HelloController)