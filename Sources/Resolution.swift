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

let primeMultiplier = 8669
let xor32Bit = 0xA3CE47B9


class Resolution: PostgresStORM {
	
	var id: Int = 0
	var boardID: Int = 0
	var authorID: Int = 0
	var status: ResolutionStatus = .hidden
	
	var currentTitle: String = ""				// Title may change, but this is the current/latest version of it. Redundant but joins are hard right now.
	var publicNotesMarkdown: String = ""
	var privateNotesMarkdown: String = ""


	var creationTimeStamp: Date = Date()

	override open func table() -> String { return "resolutions" }
	
	override func to(_ this: StORMRow) {
		id = this.data["id"] as? Int ?? 0
		boardID = this.data["boardid"] as? Int ?? 0
		authorID = this.data["authorid"] as? Int ?? 0
		currentTitle = this.data["currenttitle"] as? String ?? ""
		
		publicNotesMarkdown = this.data["publicnotesmarkdown"] as? String	?? ""
		privateNotesMarkdown = this.data["privatenotesmarkdown"] as? String	?? ""
		
		// PostgresStORM seems to store an enum as text, so to convert back from database we need to do string matching.
		// WE WOULD PREFER THIS:  status = this.data["status"] as? ResolutionStatus ?? .hidden
		//
		switch(this.data["status"] as? String ?? "") {
			case "unlisted":status = ResolutionStatus.unlisted
			case "listed":	status = ResolutionStatus.listed
			case "finished":status = ResolutionStatus.finished
			case "hidden":	status = ResolutionStatus.hidden
			default:		status = ResolutionStatus.hidden	// in case of a weird input
		}

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
			"currentTitle": self.currentTitle,
			"boardID": self.boardID,
			"authorID": self.authorID,
			"publicNotesMarkdown": self.publicNotesMarkdown,
			"privateNotesMarkdown": self.privateNotesMarkdown,
			"creationTimeStamp": self.creationTimeStamp,
			"publicNotesMarkdownRendered":(self.publicNotesMarkdown.markdownToHTML ?? ""),			// Also this in context!
			"privateNotesMarkdownRendered":(self.privateNotesMarkdown.markdownToHTML ?? ""),			// Also this in context!
			"status":self.status,	// in case we need status as a number/enum
			
			"status_options": [		// for rendering template
			
				["val":"hidden",	"sel":((self.status==ResolutionStatus.hidden)	?"selected":""), "title":"Hidden",	"info":"nobody else can view this"],
				["val":"unlisted",	"sel":((self.status==ResolutionStatus.unlisted)	?"selected":""), "title":"Unlisted","info":"Viewable by others only if they know the link"],
				["val":"listed",	"sel":((self.status==ResolutionStatus.listed)	?"selected":""), "title":"Listed",	"info":"Others can easily find this resolution for making comments"],
				["val":"finished",	"sel":((self.status==ResolutionStatus.finished)	?"selected":""), "title":"Finished","info":"Public, but no longer accepting comments or updates"],
			
			],
			
			"c":self.encodedId()		// put in context so templates can continue using for links
		]
	}
	
	
	public func encodedId() -> String {
		// Take the ID, mess with it mathematically, then base 64.
		// An Xor should convert the number into something unrecognizable,
		// then multiply by a prime number .
		
		let xoredId = self.id ^ xor32Bit
		let multiplied = xoredId * primeMultiplier
		
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

		guard let data = NSData(base64Encoded: encodedPadded, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters) else {
			return nil
		}

		var multiplied: Int = 0
		data.getBytes(&multiplied, length: MemoryLayout<Int>.size)

		let divided = multiplied / primeMultiplier
		
		if (0 != multiplied % primeMultiplier) {			// Make sure it is an exact multiple! Otherwise somebody is trying to hack the number.
			return nil
		}
		
		let xored = divided ^ xor32Bit
		
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
	
	static func getResolutions(matchingAuthorId authorid:Int) throws -> [Resolution] {
		let getObj = Resolution()
		var findObj = [String: Any]()
		findObj["authorid"] = "\(authorid)"
		try getObj.find(findObj)
		return getObj.rows()
	}
	
	static func getPublicResolutions() throws -> [Resolution] {
		let getObj = Resolution()
		var findObj = [String: Any]()
		findObj["status"] = "listed"
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
