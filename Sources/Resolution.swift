/*
Board → Board
Current Version ID
Author → Person
Notes (free-form, introduction to resolution, why written, requests for improvement, etc.)
CreationTimeStamp
*/



import StORM
import PostgresStORM
import Foundation

class Resolution: PostgresStORM {
	
	var id: Int = 0
	var boardID: Int = 0
	var authorID: Int = 0
	
	var notesMarkdown: String = ""


	var creationTimeStamp: Date = Date()

	override open func table() -> String { return "resolutions" }
	
	override func to(_ this: StORMRow) {
		id = this.data["id"] as? Int ?? 0
		boardID = this.data["boardid"] as? Int ?? 0
		authorID = this.data["authorid"] as? Int ?? 0
		
		notesMarkdown = this.data["notesmarkdown"] as? String	?? ""

		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss a Z"				// WOW that was hard to reverse-engineer from what seems to be stored!
		// https://stackoverflow.com/questions/2993578/whats-wrong-with-how-im-using-nsdateformatter
		let dateString = this.data["creationtimestamp"] as? String ?? ""
		creationTimeStamp = dateFormatter.date(from: dateString) ?? Date(timeIntervalSinceReferenceDate:10000000000)

	}
	
	func rows() -> [Resolution] {
		var rows = [Resolution]()
		for i in 0..<self.results.rows.count {
			let row = Resolution()
			row.to(self.results.rows[i])
			rows.append(row)
		}
		return rows
	}
	
	func asDictionary() -> [String: Any] {
		return [
			"id": self.id,
			"boardID": self.boardID,
			"authorID": self.authorID,
			"notesMarkdown": self.notesMarkdown,
			"creationTimeStamp": self.creationTimeStamp,
		]
	}
	
	static func all() throws -> [Resolution] {
		let getObj = Resolution()
		try getObj.findAll()
		return getObj.rows()
	}
	
	static func getResolution(matchingId id:Int) throws -> Resolution {
		let getObj = Resolution()
		var findObj = [String: Any]()
		findObj["id"] = "\(id)"
		try getObj.find(findObj)
		return getObj
	}
	
	static func getResolutions(matchingShort short:String) throws -> [Resolution] {
		let getObj = Resolution()
		var findObj = [String: Any]()
		findObj["short"] = short
		try getObj.find(findObj)
		return getObj.rows()
	}
	

	
	static func resolutionsToDictionary(_ resolutions: [Resolution]) -> [[String: Any]] {
		var resolutionsDict: [[String: Any]] = []
		for row in resolutions {
			resolutionsDict.append(row.asDictionary())
		}
		return resolutionsDict
	}
	
//	static func all() throws -> String {
//		return try allAsDictionary().jsonEncodedString()
//	}
	

	static func allAsDictionary() throws -> [[String: Any]] {
		let resolutions = try Resolution.all()
		return resolutionsToDictionary(resolutions)
	}
	
	
	
	
	
	
	
}
