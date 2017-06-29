/*
Name
Organization representing
Board ID → Board
Password Hash
Identifier #1
Identifier #2
Identifier #3
Email address (not unique??? — allow multiple user records with same email address JUST in case)
CreationTimeStamp


From AuthAccount:
public var uniqueID
public var username
public var password
public var facebookID
public var googleID
public var firstname
public var lastname
public var email

*/


import StORM
import PostgresStORM
import PerfectTurnstilePostgreSQL
import Foundation

class Person: PostgresStORM {
	
	var id : Int = 0;
	var organization: String = ""
	var identifier1: String = ""
	var identifier2: String = ""
	var identifier3: String = ""

	var creationTimeStamp: Date?

	

	override open func table() -> String { return "persons" }
	
	override func to(_ this: StORMRow) {
		
		id = this.data["id"] as? Int	?? 0

		organization = this.data["organization"] as? String	?? ""

		identifier1 = this.data["identifier1"] as? String	?? ""
		identifier2 = this.data["identifier2"] as? String	?? ""
		identifier3 = this.data["identifier3"] as? String	?? ""
		
		creationTimeStamp = this.data["creationtimestamp"] as? Date ?? nil
	}
	
	func rows() -> [Person] {
		var rows = [Person]()
		for i in 0..<self.results.rows.count {
			let row = Person()
			row.to(self.results.rows[i])
			rows.append(row)
		}
		return rows
	}
	
	func asDictionary() -> [String: Any] {
		
		return [
			"organization": self.organization,
			"identifier1": self.identifier1,
			"identifier2": self.identifier2,
			"identifier3": self.identifier3
		]
	}
	
	static func all() throws -> [Person] {
		let getObj = Person()
		try getObj.findAll()
		return getObj.rows()
	}
	
	static func getPerson(matchingId id:Int) throws -> Person {
		let getObj = Person()
		var findObj = [String: Any]()
		findObj["id"] = "\(id)"
		try getObj.find(findObj)
		return getObj
	}
		
	
}
