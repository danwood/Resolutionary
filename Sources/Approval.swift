/*
Person ID → Person
ResolutionVersion ID → ResolutionVersion
[_] Approval represents endorsement of organization
State (Yes/No/Maybe) [No means you won’t be bugged about resolution again]
Notes (suggested improvements, attaboys, etc.)
[_] NotesArePrivate (allows honest feedback, but we encourage public feedback to keep conversation going)
CreationTimeStamp
*/


import StORM
import PostgresStORM
import Foundation

enum ApprovalState {
	case unknown
	case no
	case maybe
	case yes
}

class Approval: PostgresStORM {
	
	var id: Int = 0
	var personID: Int = 0
	var resolutionVersionID: Int = 0
	var isApprovalOrganization: Bool = false
	var isNotePrivate: Bool = false
	var approvalState: ApprovalState = .unknown
	var note: String = ""
	var creationTimeStamp: Date?
	
	override open func table() -> String { return "approvals" }
	
	override func to(_ this: StORMRow) {
		id = this.data["id"] as? Int ?? 0
		personID	= this.data["personid"] as? Int ?? 0
		resolutionVersionID = this.data["resolutionversionid"] as? Int ?? 0
		isApprovalOrganization	= this.data["isapprovalorganization"] as? Bool ?? false
		isNotePrivate = this.data["isnoteprivate"] as? Bool	?? false
		approvalState	= this.data["approvalstate"] as? ApprovalState	?? .unknown
		note = this.data["note"] as? String	?? ""
		creationTimeStamp	= this.data["creationtimestamp"] as? Date
	}
	
	func rows() -> [Approval] {
		var rows = [Approval]()
		for i in 0..<self.results.rows.count {
			let row = Approval()
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
	
	static func all() throws -> [Approval] {
		let getObj = Approval()
		try getObj.findAll()
		return getObj.rows()
	}
	
	static func getApproval(matchingId id:Int) throws -> Approval {
		let getObj = Approval()
		var findObj = [String: Any]()
		findObj["id"] = "\(id)"
		try getObj.find(findObj)
		return getObj
	}
	
	static func getApprovals(matchingShort short:String) throws -> [Approval] {
		let getObj = Approval()
		var findObj = [String: Any]()
		findObj["short"] = short
		try getObj.find(findObj)
		return getObj.rows()
	}
	
	
}
