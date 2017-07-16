//
//  main.swift
//  PerfectTurnstileSQLiteDemo
//
//  Created by Jonathan Guthrie on 2016-10-11.
//	Copyright (C) 2015 PerfectlySoft, Inc.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2015 - 2016 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

import PerfectLib
import PerfectHTTP
import PerfectHTTPServer

import StORM
import PostgresStORM
import PerfectTurnstilePostgreSQL
import PerfectRequestLogger
import TurnstilePerfect


StORMdebug = true
RequestLogFile.location = "./requests.log"

// Used later in script for the Realm and how the user authenticates.
let pturnstile = TurnstilePerfectRealm()


PostgresConnector.host        = "localhost"
PostgresConnector.username    = "perfect"				// createuser -D -P perfect
PostgresConnector.password    = "perfect"
PostgresConnector.database 	  = "resolutionary"			// createdb -O perfect resolutionary
PostgresConnector.port        = 5432

// Set up my tables
let approval = Approval();
try? approval.setup();

let board = Board();
try? board.setup();

let person = Person();
try? person.setup();

let resolution = Resolution();
try? resolution.setup();

let resolutionVersion = ResolutionVersion();
try? resolutionVersion.setup();

// Set up the Authentication table
let auth = AuthAccount()
try? auth.setup()

// Connect the AccessTokenStore
tokenStore = AccessTokenStore()
try? tokenStore?.setup()

//let facebook = Facebook(clientID: "CLIENT_ID", clientSecret: "CLIENT_SECRET")
//let google = Google(clientID: "CLIENT_ID", clientSecret: "CLIENT_SECRET")

// Create HTTP server.
let server = HTTPServer()

// Register routes and handlers; Add the routes to the server.
let authWebRoutes = makeWebAuthRoutes()
server.addRoutes(authWebRoutes)

let resolutionWebRoutes = ResolutionController.makeRoutes()
server.addRoutes(resolutionWebRoutes)






// Setup logging
let myLogger = RequestLogger()

// add routes to be checked for auth
var authenticationConfig = AuthenticationConfig()
// TODO: set up 'denied' above so disallowed pages will redirect to a login page.

// Things to require login for
authenticationConfig.include("/*")

// Things to allow not being logged in.  Maybe a safer approach so we won't have to worry about each private page

authenticationConfig.exclude("/")
authenticationConfig.exclude("/login")
authenticationConfig.exclude("/register")


let authFilter = AuthFilter(authenticationConfig)

// Note that order matters when the filters are of the same priority level
server.setRequestFilters([pturnstile.requestFilter])
server.setResponseFilters([pturnstile.responseFilter])

server.setRequestFilters([(authFilter, .high)])

server.setRequestFilters([(myLogger, .high)])
server.setResponseFilters([(myLogger, .low)])

server.serverPort = 8080
server.serverAddress = "127.0.0.1"

// Where to serve static files from.  We are setting the default but it's OK to just make it explicit in case default changes
server.documentRoot = "./webroot"

do {
	// Launch the HTTP server.
	try server.start()
} catch PerfectError.networkError(let err, let msg) {
	print("Network error thrown: \(err) \(msg)")
}
