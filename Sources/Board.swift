/*
Name
Description
Subdomain (for logging in and collecting resolutions)
Label for identifier #1 (e.g. Phone number, AD, Delegate ID# etc.)
Label for identifier #2
Label for identifier #3
Contact → Person
CreationTimeStamp
*/


import StORM
import PostgresStORM
import Foundation

class Board: PostgresStORM {
	
	var id: Int = 0
	var name: String = ""
	var description: String = ""
	var label1: String? = nil
	var label2: String? = nil
	var label3: String? = nil
	
	var contactPersonID: Int = 0

	var creationTimeStamp: Date?

	override open func table() -> String { return "boards" }
	
	override func to(_ this: StORMRow) {
		id = this.data["id"] as? Int ?? 0
		name	= this.data["name"] as? String	?? ""
		description = this.data["description"] as? String	?? ""

		label1 = this.data["label1"] as? String
		label2 = this.data["label2"] as? String
		label3 = this.data["label3"] as? String
		
		creationTimeStamp	= this.data["creationtimestamp"] as? Date

	}
	
	func rows() -> [Board] {
		var rows = [Board]()
		for i in 0..<self.results.rows.count {
			let row = Board()
			row.to(self.results.rows[i])
			rows.append(row)
		}
		return rows
	}
	
	func asDictionary() -> [String: Any] {
		return [
			"id": self.id,
		]
	}
	
	static func all() throws -> [Board] {
		let getObj = Board()
		try getObj.findAll()
		return getObj.rows()
	}
	
	static func getBoard(matchingId id:Int) throws -> Board {
		let getObj = Board()
		var findObj = [String: Any]()
		findObj["id"] = "\(id)"
		try getObj.find(findObj)
		return getObj
	}
	
	static func getBoards(matchingShort short:String) throws -> [Board] {
		let getObj = Board()
		var findObj = [String: Any]()
		findObj["short"] = short
		try getObj.find(findObj)
		return getObj.rows()
	}
	
	
}
