//
//  Goal.swift
//  App
//
//  Created by Ryan Gunn on 2/8/19.
//

import Foundation
import FluentPostgreSQL
import Vapor

final class Goal: PostgreSQLModel {
    var id: Int?
    var startDate:Date
    var endDate:Date
    var goalCount:Int
    var goalType:GoalType
    var userID:Int

    init(id:Int? = nil, startDate:Date, endDate:Date,goalCount:Int,goalType:GoalType,userID:Int) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.goalCount = goalCount
        self.goalType = goalType
        self.userID = userID
    }
}

extension Goal:Content{}
extension Goal: Parameter{}

extension Goal:Migration{
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return PostgreSQLDatabase.create(Goal.self, on: conn) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.startDate)
            builder.field(for: \.endDate)
            builder.field(for: \.goalCount)
            builder.field(for: \.goalType)
            builder.unique(on: \.userID)
        }
    }
}
extension Goal{
    var user:Parent<Goal,User>{
        return parent(\.userID)
    }
}

enum GoalType:Int,PostgreSQLRawEnum,Codable {
    case page,book
}

