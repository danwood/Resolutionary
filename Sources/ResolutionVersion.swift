/*
ID
Resolution ID → Resolution
Version Number
textMarkdown (free-form, markdown)
title
CoAuthors (free form text; author responsible for crediting; allows non users to chime in and get credit)
[_] IsPublished — allow incremental changes before new version is public. Version number won’t increment until it’s published.)
CreationTimeStamp
*/


import StORM
import PostgresStORM
import Foundation

class ResolutionVersion: PostgresStORM {
	
	var id: Int = 0
	var resolutionID: Int = 0
	var version: Int = 0
	var title: String = ""
	var coauthors: String = ""
	var textMarkdown: String = ""
	var isPublished: Bool = false;
	
	var creationTimeStamp: Date = Date()
	
	override open func table() -> String { return "resolutionversions" }
	
	override func to(_ this: StORMRow) {
		id = this.data["id"] as? Int ?? 0
		resolutionID = this.data["resolutionid"] as? Int ?? 0
		version = this.data["version"] as? Int ?? 0
		
		title	= this.data["title"] as? String	?? ""
		coauthors	= this.data["coauthors"] as? String	?? ""
		textMarkdown	= this.data["textmarkdown"] as? String	?? ""
		isPublished = this.data["ispublished"] as? Bool ?? false

		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss a Z"				// WOW that was hard to reverse-engineer from what seems to be stored!
		// https://stackoverflow.com/questions/2993578/whats-wrong-with-how-im-using-nsdateformatter
		let dateString = this.data["creationtimestamp"] as? String ?? ""
		creationTimeStamp = dateFormatter.date(from: dateString) ?? Date(timeIntervalSinceReferenceDate:10000000000)
}
	
	func rows() -> [ResolutionVersion] {
		var rows = [ResolutionVersion]()
		for i in 0..<self.results.rows.count {
			let row = ResolutionVersion()
			row.to(self.results.rows[i])
			rows.append(row)
		}
		return rows
	}
	
	func asDictionary() -> [String: Any] {
		return [
			"id": self.id,
			"resolutionID": self.resolutionID,
			"version": self.version,
			"title": self.title,
			"coauthors": self.coauthors,
			"textMarkdown": self.textMarkdown,
			"isPublished": self.isPublished,
			"creationTimeStamp": self.creationTimeStamp,
			"textMarkdownRendered":(self.textMarkdown.markdownToHTML ?? "")			// Also this in context!
		]
	}
	
	static func all() throws -> [ResolutionVersion] {
		let getObj = ResolutionVersion()
		try getObj.findAll()
		return getObj.rows()
	}
	
	// If not found, returns an empty ResolutionVersion with a zero ID
	static func getResolutionVersion(matchingId id:Int) throws -> ResolutionVersion {
		let getObj = ResolutionVersion()
		var findObj = [String: Any]()
		findObj["id"] = "\(id)"
		try getObj.find(findObj)
		return getObj
	}
	
	// If not found, returns an empty ResolutionVersion with a zero ID
	static func getResolutionVersion(matchingResolutionId resolutionId:Int, matchingVersion version:Int) throws -> ResolutionVersion {
		let getObj = ResolutionVersion()
		try getObj.select(whereclause: "version = $1 AND resolutionId = $2", params: [version, resolutionId], orderby: ["version DESC"])
		return getObj
	}

	// Look up all resolution versions matching the resolution ID
	static func getResolutionVersions(matchingResolutionId resolutionID:Int) throws -> [ResolutionVersion] {
		let getObj = ResolutionVersion()
		try getObj.select(whereclause: "resolutionID = $1", params: [resolutionID], orderby: ["version DESC"], cursor: StORMCursor(limit: 250, offset: 0))
		return getObj.rows();
	}
	
	// Look up last resolution versions matching the resolution ID
	static func getLastResolutionVersion(matchingResolutionId resolutionID:Int) throws -> ResolutionVersion {
		let getObj = ResolutionVersion()
		try getObj.select(whereclause: "resolutionID = $1", params: [resolutionID], orderby: ["version DESC"], cursor: StORMCursor(limit: 1, offset: 0))
		
		// Note: We are limiting to 1, but there may be more than one result ignoring the limits, so makeRow() is *not* called.
		// So we can't just return the getObj as if it were automatically instantiated!
		getObj.makeRow()
		
		return getObj
	}

	static func resolutionVersionsToDictionary(_ resolutionVersions: [ResolutionVersion]) -> [[String: Any]] {
		var resolutionVersionsDict: [[String: Any]] = []
		for row in resolutionVersions {
			resolutionVersionsDict.append(row.asDictionary())
		}
		return resolutionVersionsDict
	}

}
