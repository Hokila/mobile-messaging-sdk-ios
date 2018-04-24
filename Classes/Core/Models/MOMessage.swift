//
//  MOMessage.swift
//  MobileMessaging
//
//  Created by Andrey Kadochnikov on 18/10/2017.
//

import Foundation

public protocol MOMessageProtocol {
	
	/// Destination indicates where the message is being sent
	var destination: String? {get}
	
	/// Sent status
	var sentStatus: MOMessageSentStatus {get}
	
	/// Indicates when the message was composed
	var composedDate: Date {get}
	
	/// Indicates the bulk id that the message was sent within
	var bulkId: String? {get}
	
	/// Indicates id of the associated message
	var initialMessageId: String? {get}
}

@objcMembers
public class MOMessage: BaseMessage, MOMessageProtocol
{
	public var destination: String?
	
	public var sentStatus: MOMessageSentStatus
	
	public var composedDate: Date
	
	public var bulkId: String?
	
	public var initialMessageId: String?
	
	var dictRepresentation: DictionaryRepresentation {
		return MOAttributes(destination: destination, text: text ?? "", customPayload: customPayload, messageId: messageId, sentStatus: sentStatus, bulkId: bulkId, initialMessageId: initialMessageId).dictRepresentation
	}
	
	convenience public init(destination: String?, text: String, customPayload: [String: CustomPayloadSupportedTypes]?, composedDate: Date, bulkId: String? = nil, initialMessageId: String? = nil) {
		let mId = NSUUID().uuidString
		self.init(messageId: mId, destination: destination, text: text, customPayload: customPayload, composedDate: composedDate, bulkId: bulkId, initialMessageId: initialMessageId, deliveryMethod: .generatedLocally)
	}
	
	convenience init?(messageStorageMessageManagedObject m: Message) {
		self.init(payload: m.payload, composedDate: m.createdDate)
		self.sentStatus = MOMessageSentStatus(rawValue: m.sentStatusValue) ?? .Undefined //TODO: proper init needed, move the sent status out of designated inits. also check mt mtessages if all specific attributes are initialized @NSManaged var messageId: String
	}
	
	convenience init?(messageManagedObject: MessageManagedObject) {
		if let p = messageManagedObject.payload {
			self.init(payload: p, composedDate: messageManagedObject.creationDate)
		} else {
			return nil
		}
	}
	
	convenience init?(moResponseJson json: JSON) {
		if let dictionary = json.dictionaryObject {
			self.init(payload: dictionary, composedDate: MobileMessaging.date.now) // workaround: `now` is put as a composed date only because there is no Composed Date field in a JSON model. however this data is not used from anywhere in SDK.
		} else {
			return nil
		}
	}
	
	convenience init?(payload: DictionaryRepresentation, composedDate: Date) {
		guard let messageId = payload[APIKeys.kMOMessageId] as? String,
			let text = payload[APIKeys.kMOText] as? String,
			let status = payload[APIKeys.kMOMessageSentStatusCode] as? Int else
		{
			return nil
		}
		let sentStatus = MOMessageSentStatus(rawValue: Int16(status)) ?? MOMessageSentStatus.Undefined
		let destination = payload[APIKeys.kMODestination] as? String
		let customPayload = payload[APIKeys.kMOCustomPayload] as? [String: CustomPayloadSupportedTypes]
		let bulkId = payload[APIKeys.kMOBulkId] as? String
		let initialMessageId = payload[APIKeys.kMOInitialMessageId] as? String
		
		self.init(messageId: messageId, destination: destination, text: text, customPayload: customPayload, composedDate: composedDate, bulkId: bulkId, initialMessageId: initialMessageId, sentStatus: sentStatus, deliveryMethod: .pull)
	}
	
	init(messageId: String, destination: String?, text: String, customPayload: [String: CustomPayloadSupportedTypes]?, composedDate: Date, bulkId: String? = nil, initialMessageId: String? = nil, sentStatus: MOMessageSentStatus = .Undefined, deliveryMethod: MessageDeliveryMethod) {
		let payload = MOAttributes(	destination: destination,
									   text: text,
									   customPayload: customPayload,
									   messageId: messageId,
									   sentStatus: sentStatus,
									   bulkId: bulkId,
									   initialMessageId: initialMessageId).dictRepresentation
		
		
		self.sentStatus = sentStatus
		self.destination = destination
		self.composedDate = composedDate
		self.bulkId = bulkId
		self.initialMessageId = initialMessageId
		
		super.init(messageId: messageId, direction: .MO, originalPayload: payload, deliveryMethod: deliveryMethod)
		
		self.text = text
	}
}
