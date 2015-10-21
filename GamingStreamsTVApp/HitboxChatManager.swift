//
//  HitboxChatManager.swift
//  GamingStreamsTVApp
//
//  Created by Olivier Boucher on 2015-10-20.
//  Copyright © 2015 Rivus Media Inc. All rights reserved.
//

import Foundation

class HitboxChatManager {
    
    enum ConnectionStatus {
        case Connected
        case Connecting
        case Disconnected
    }
    
    private var chatConnection : WebSocket?
    private var status : ConnectionStatus
    private let consumer : ChatManagerConsumer
    private let opQueue : dispatch_queue_t
    private var messageQueue : HitboxChatMessageQueue?
    private var credentials : HitboxChatCredentials?
    private var currentChannel : String?
    
    init(consumer : ChatManagerConsumer, url: NSURL) {
        status = .Disconnected
        self.consumer = consumer
        let queueAttr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_BACKGROUND, 0)
        opQueue = dispatch_queue_create("com.hitbox.chatmgr", queueAttr)
        
        messageQueue = HitboxChatMessageQueue(delegate: self)
        
        self.status = .Connecting
        self.chatConnection = WebSocket(url: url)
        self.chatConnection!.delegate = self
        self.chatConnection!.queue = self.opQueue
    }
    
    func connectAnonymously(channel : String) {
        if let socket = chatConnection as WebSocket! {
            credentials = HitboxChatCredentials.anonymous()
            currentChannel = channel.lowercaseString
            socket.connect()
        }
    }
    
    func disconnect() {
        if let socket = chatConnection as WebSocket!  where socket.isConnected {
            socket.disconnect()
        }
    }
}

extension HitboxChatManager : WebSocketDelegate {
    func websocketDidConnect(socket: WebSocket) {
        status = .Connected
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        status = .Disconnected
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        if text.hasPrefix("5:::") { //Hitbox payloads that are messages start by "5:::"
            messageQueue?.addNewMessage(text)
        }
        else if text.hasPrefix("2::") { //This is the way hitbox sends a ping request
            socket.writeString("2::")
        }
        else if text.hasPrefix("1::") {
            let msg : String = credentials!.getJoinMessage(currentChannel!)
            socket.writeString(msg)
        }
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        print("We recieved data from websocket, that's weird..")
        print(String(data: data, encoding: NSUTF8StringEncoding))
    }
}

extension HitboxChatManager : HitboxChatMessageQueueDelegate {
    func handleProcessedAttributedString(message: NSAttributedString) {
        consumer.messageReadyForDisplay(message)
    }
}