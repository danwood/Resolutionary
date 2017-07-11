/*
Board → Board
Current Version ID
Author → Person
CoAuthors (free form text; author responsible for crediting; allows non users to chime in and get credit)
Notes (free-form, introduction to resolution, why written, requests for improvement, etc.)
CreationTimeStamp
*/



import StORM
import PostgresStORM
import Foundation
import PerfectHTTP
import PerfectMustache



import PerfectHTTPServer
import PerfectWebSockets
import PerfectMarkdown

/// server port to start with
let PORT = 7777

/// web socket protocol
let PROTOCOL = "editor"

/// WebSocket Event Handler
public class EditorHandler: WebSocketSessionHandler {
	
	public let socketProtocol : String? = PROTOCOL
	
	// This function is called by the WebSocketHandler once the connection has been established.
	public func handleSession(request: HTTPRequest, socket: WebSocket) {
		
		socket.readStringMessage { input, _, _ in
			
			guard let nameAndMarkdown = input else {
				socket.close()
				return
			}//end guard
			
			
			let scanner = Scanner(string: nameAndMarkdown)
			var value: NSString? = ""
			if scanner.scanUpToCharacters(from:NSCharacterSet.newlines, into:&value), let value = value as String? {
				scanner.scanCharacters(from:NSCharacterSet.newlines, into:nil);
				//let input = scanner.string.substring(from:scanner.scanLocation)
				
				let input = scanner.string[scanner.string.scanLocation..<scanner.string.index(scanner.string.startIndex, offsetBy: 0)]

				// convert the input from markdown to HTML
				let output = input.markdownToHTML ?? ""
				
				// sent it back to the request
				socket.sendStringMessage(string: output, final: true) {
					self.handleSession(request: request, socket: socket)
				}//end send

				
			}
				
			
			
		}//end readStringMessage
	}//end handleSession
}//end handler

public class ResolutionController {
	
	// Defines and returns the Web Authentication routes
	public static func makeRoutes() -> Routes {
		
		// Add old-fashioned? route style
		var routes = Routes();
		
		routes.add(method: .post, uri: "/newresolution", handler: ResolutionController.newResolutionHandlerPOST)

		routes.add(method: .get, uri: "/editresolution/{id}", handler: ResolutionController.editResolutionHandlerGET)
		
		// Add the endpoint for the WebSocket example system
		routes.add(method: .get, uri: "/editor", handler: {
			request, response in
			
			// To add a WebSocket service, set the handler to WebSocketHandler.
			// Provide your closure which will return your service handler.
			WebSocketHandler(handlerProducer: {
				(request: HTTPRequest, protocols: [String]) -> WebSocketSessionHandler? in
				
				// Check to make sure the client is requesting our "echo" service.
				guard protocols.contains("editor") else {
					return nil
				}
				
				// Return our service handler.
				return EditorHandler()
			}).handleRequest(request: request, response: response)
		})
		
		return routes
	}

	/// Handles the POST request for a "newresolution" route.  Creates a new empty record.  We will be saving to the record in real time, no submit button.  Websockets.
	open static func newResolutionHandlerPOST(request: HTTPRequest, _ response: HTTPResponse) {

		do {

			let resolution = Resolution()
			resolution.creationTimeStamp = Date()
			try resolution.save { id in
				resolution.id = id as! Int
			}
			response.redirect(path: "/editresolution/" + String(resolution.id) )
		} catch {
			response.render(template: "/editresolution", context: ["flash": "An unknown error occurred."])
		}
	}


	/// Handles the POST request for a "newresolution" route.  Creates a new empty record.  We will be saving to the record in real time, no submit button.  Websockets.
	open static func editResolutionHandlerGET(request: HTTPRequest, _ response: HTTPResponse) {
		
		do {
			
			guard let idString = request.urlVariables["id"],
				let id = Int(idString) else {
					response.completed(status: .badRequest)
					return
			}

			let resolution = try Resolution.getResolution(matchingId: id)

			var values = MustacheEvaluationContext.MapType()
			values["resolutions"] = Resolution.resolutionsToDictionary( [ resolution ] )
			
			response.render(template: "editresolution", context: values)
			
		} catch {
			response.render(template: "/editresolution", context: ["flash": "An unknown error occurred."])
		}
	}


}
