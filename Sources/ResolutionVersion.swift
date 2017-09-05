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
	
	var creationTimeStamp: Date?
	
	override open func table() -> String { return "resolutionversions" }
	
	override func to(_ this: StORMRow) {
		id = this.data["id"] as? Int ?? 0
		resolutionID = this.data["resolutionid"] as? Int ?? 0
		version = this.data["id"] as? Int ?? 0
		
		title	= this.data["title"] as? String	?? ""
		coauthors	= this.data["coauthors"] as? String	?? ""
		textMarkdown	= this.data["textmarkdown"] as? String	?? ""
		isPublished = this.data["ispublished"] as? Bool ?? false

		creationTimeStamp	= this.data["creationtimestamp"] as? Date
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
		]
	}
	
	static func all() throws -> [ResolutionVersion] {
		let getObj = ResolutionVersion()
		try getObj.findAll()
		return getObj.rows()
	}
	
	static func getResolutionVersion(matchingId id:Int) throws -> ResolutionVersion {
		let getObj = ResolutionVersion()
		var findObj = [String: Any]()
		findObj["id"] = "\(id)"
		try getObj.find(findObj)
		return getObj
	}
	
	// Look up (all?) resolution versions matching the resolution ID
	static func getResolutionVersion(matchingResolutionId resolutionID:Int) throws -> ResolutionVersion {
		let getObj = ResolutionVersion()
		var findObj = [String: Any]()
		findObj["resolutionID"] = "\(resolutionID)"
		try getObj.find(findObj)
		return getObj
	}
	
	static func getResolutionVersions(matchingShort short:String) throws -> [ResolutionVersion] {
		let getObj = ResolutionVersion()
		var findObj = [String: Any]()
		findObj["short"] = short
		try getObj.find(findObj)
		return getObj.rows()
	}
	

	static func resolutionVersionsToDictionary(_ resolutionVersions: [ResolutionVersion]) -> [[String: Any]] {
		var resolutionVersionsDict: [[String: Any]] = []
		for row in resolutionVersions {
			resolutionVersionsDict.append(row.asDictionary())
		}
		return resolutionVersionsDict
	}

}
