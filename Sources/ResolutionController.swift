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
	
	let resolution : Resolution
	let resolutionVersion : ResolutionVersion
	
	init(_ resolution: Resolution, version: ResolutionVersion) {
		self.resolution = resolution
		self.resolutionVersion = version
	}
	
	// This function is called by the WebSocketHandler once the connection has been established.
	public func handleSession(request: HTTPRequest, socket: WebSocket) {
		
		socket.readStringMessage { input, _, _ in
			
			guard let nameAndMarkdown = input else {
				socket.close()
				return
			}//end guard
			
			
			let scanner = Scanner(string: nameAndMarkdown)
			var inputName: NSString? = ""
			var ignore = scanner.scanString("#", into:nil)
			
			if scanner.scanUpToCharacters(from:NSCharacterSet.newlines, into:&inputName), let inputName = inputName as String? {
				scanner.scanCharacters(from:NSCharacterSet.newlines, into:nil)
				let index = scanner.string.index(scanner.string.startIndex, offsetBy: scanner.scanLocation+1)
				let inputValue = scanner.string.substring(from: index)
				
				var toSave : PostgresStORM = self.resolution;
				
				// Is there some way to dynamically set setValue forKey ?  For now just do brute force
				switch(inputName) {
				case "notesMarkdown":
					self.resolution.notesMarkdown = inputValue
				case "title":
					self.resolutionVersion.title = inputValue
					toSave = self.resolutionVersion;
				case "textMarkdown":
					self.resolutionVersion.textMarkdown = inputValue
					toSave = self.resolutionVersion;
				case "coauthors":
					self.resolutionVersion.coauthors = inputValue
					toSave = self.resolutionVersion;
				default:
					print("NOT HANDLED: ##### Set \(inputName) of \(self.resolution) to \(inputValue)")
				}
				if (!ignore) {
					do {
						try toSave.save()
					}
					catch {
						print("Unable to save resolution")
					}
				}
								
				if inputName.hasSuffix("Markdown") {

					// convert the input from markdown to HTML
					let output = inputName + "Rendered" + "\n" + (inputValue.markdownToHTML ?? "")
				
					// sent it back to the request
					socket.sendStringMessage(string: output, final: true) {
						self.handleSession(request: request, socket: socket)
					}//end send
				}
				

				
			}
				
			
			
		}//end readStringMessage
	}//end handleSession
}//end handler

public class ResolutionController {
	
	// Defines and returns the Web Authentication routes
	public static func makeRoutes() -> Routes {
		
		// Add old-fashioned? route style
		var routes = Routes()
		
		routes.add(method: .post, uri: "/newresolution", handler: ResolutionController.newResolutionHandlerPOST)

		routes.add(method: .get, uri: "/editresolution/{id}", handler: ResolutionController.editResolutionHandlerGET)
		
		routes.add(method: .get, uri: "/editresolution/{id}/{versionid}", handler: ResolutionController.editResolutionHandlerGET)

		// Add the endpoint for the WebSocket example system
		routes.add(method: .get, uri: "/editor/{id}", handler: {
			request, response in
			
			// To add a WebSocket service, set the handler to WebSocketHandler.
			// Provide your closure which will return your service handler.
			WebSocketHandler(handlerProducer: {
				(request: HTTPRequest, protocols: [String]) -> WebSocketSessionHandler? in
				
				// Check to make sure the client is requesting our service.
				guard protocols.contains("editor") else {
					return nil
				}

				guard let idString = request.urlVariables["id"],
					let id = Int(idString) else {
						return nil
				}
								
				do {
					let resolution = try Resolution.getResolution(matchingId: id)

					let resolutionVersion = try ResolutionVersion.getLastResolutionVersion(matchingResolutionId: id)

					// Return our service handler.
					return EditorHandler(resolution, version:resolutionVersion)

				}
				catch {
					return nil
				}
				
			}).handleRequest(request: request, response: response)
		})
		
		return routes
	}

	/// Handles the POST request for a "newresolution" route.  Creates a new empty record.  We will be saving to the record in real time, no submit button.  Websockets.
	open static func newResolutionHandlerPOST(request: HTTPRequest, _ response: HTTPResponse) {

		do {

			// Create empty resolution
			let resolution = Resolution()
			resolution.creationTimeStamp = Date()
			try resolution.save { id in
				resolution.id = id as! Int
			}
			
			// Create empty resolution version that corresponds to this resolution
			let resolutionVersion = ResolutionVersion()
			resolutionVersion.creationTimeStamp = Date()
			resolutionVersion.resolutionID = resolution.id
			try resolutionVersion.save { id in
				resolutionVersion.id = id as! Int
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
			
			// Get all resolution versions too
			let resolutionVersions = try ResolutionVersion.getResolutionVersions(matchingResolutionId: id)
			values["resolution_versions"] = ResolutionVersion.resolutionVersionsToDictionary( resolutionVersions )

			// Get latest version, or specified version
			
			if let versionIdString = request.urlVariables["version"]
			{
				if let versionId = Int(versionIdString)
				{
					// Get the current resolution version in context.
					let resolutionVersion = try ResolutionVersion.getResolutionVersion(matchingResolutionId:id, matchingId: versionId)
					values["resolution_version"] = ResolutionVersion.resolutionVersionsToDictionary( [ resolutionVersion ] )
				}
			}
			// If we couldn't parse, or find given ID, get the lastest version.
			if (values["resolution_version"] == nil) {
				// Get the current resolution version in context
				let resolutionVersion = try ResolutionVersion.getLastResolutionVersion(matchingResolutionId: id)
				values["resolution_version"] = ResolutionVersion.resolutionVersionsToDictionary( [ resolutionVersion ] )
			}

			
			
			response.render(template: "editresolution", context: values)
			
		} catch {
			response.render(template: "/editresolution", context: ["flash": "An unknown error occurred."])
		}
	}


}
