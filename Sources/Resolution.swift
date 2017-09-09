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

public enum ResolutionStatus {
	case hidden					// Not viewable by others. For early drafts, or if author doesn't want it to be seen, etc.
	case unlisted				// Viewable by others if they know the link, useful if sharing with limited group
	case listed					// Findable by others in list of your resolutions and all resolutions
	case finished				// Cannot be commented on or updated
}


class Resolution: PostgresStORM {
	
	var id: Int = 0
	var boardID: Int = 0
	var authorID: Int = 0
	var status: ResolutionStatus = .hidden
	
	var publicNotesMarkdown: String = ""
	var privateNotesMarkdown: String = ""


	var creationTimeStamp: Date = Date()

	override open func table() -> String { return "resolutions" }
	
	override func to(_ this: StORMRow) {
		id = this.data["id"] as? Int ?? 0
		boardID = this.data["boardid"] as? Int ?? 0
		authorID = this.data["authorid"] as? Int ?? 0
		
		publicNotesMarkdown = this.data["publicnotesmarkdown"] as? String	?? ""
		privateNotesMarkdown = this.data["privatenotesmarkdown"] as? String	?? ""

		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"                // WOW that was hard to reverse-engineer from what seems to be stored!
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
			"publicNotesMarkdown": self.publicNotesMarkdown,
			"privateNotesMarkdown": self.privateNotesMarkdown,
			"creationTimeStamp": self.creationTimeStamp,
			"publicNotesMarkdownRendered":(self.publicNotesMarkdown.markdownToHTML ?? ""),			// Also this in context!
			"privateNotesMarkdownRendered":(self.privateNotesMarkdown.markdownToHTML ?? "")			// Also this in context!
		]
	}
	
	public func encodedId() -> String {
		// Take the ID, mess with it mathematically, then base 64.
		// An Xor should convert the number into something unrecognizable,
		// then multiply by a prime number .
		
		let xoredId = self.id ^ 0xA3CE47B9	// arbitrary 32-bit number
		let multiplied = xoredId * 8669		// a prime number
		
		// https://stackoverflow.com/questions/28680589/how-to-convert-an-int-into-nsdata-in-swift
		var score = multiplied
		let data = NSData(bytes: &score, length: MemoryLayout<Int>.size)
	
		let base64 = data.base64EncodedString(options:[]) // Don't ask for line breaks
		
		// Remove ending ='s to obscure that it's Base64
		let trimmed = base64.trimmingCharacters(in: CharacterSet(charactersIn:"="))
		
		return trimmed

	}
	
	public static func encodedIdToId(_ encoded: String) -> Int? {
		
		let length = encoded.characters.count
		let encodedPadded = encoded.padding(toLength: length + (4 - length % 4) % 4, withPad: "=", startingAt: 0)

		let data = NSData(base64Encoded: encodedPadded, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters)

		var multiplied: Int = 0
		data!.getBytes(&multiplied, length: MemoryLayout<Int>.size)

		let divided = multiplied / 8669
		let xored = divided ^ 0xA3CE47B9
		
		return xored
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
