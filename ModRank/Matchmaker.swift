//
//  Matchmaker.swift
//  ModRank
//
//  Created by Kam Popat on 22/07/2016.
//  Copyright © 2016 Kam Popat. All rights reserved.
//

import Foundation
import ReactiveCocoa
import enum Result.NoError

typealias ModulePair = (ModuleProtocol, ModuleProtocol)

protocol MatchmakerProtocol {
    func roundProducer() -> SignalProducer<RoundProtocol, NSError>
}


let facebookTest = Module(name: "Facebook", rating: 1400, rounds: 0, kFactor: 32)
let twitterTest = Module(name: "Twitter", rating: 1400, rounds: 0, kFactor: 32)
let calTest = Module(name: "Calendar", rating: 1400, rounds: 0, kFactor: 32)
let emailTest = Module(name: "Email", rating: 1400, rounds: 0, kFactor: 32)

let testModules = [facebookTest, twitterTest, calTest, emailTest]




struct MatchmakerTest: MatchmakerProtocol {
    
    func roundProducer() -> SignalProducer<RoundProtocol, NSError> {
        return self.modulesForNextRound()
            .flatMap(FlattenStrategy.Latest, transform: self.nextRound)
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    func modulesForNextRound() -> SignalProducer<ModulePair, NSError> {
        return SignalProducer { observer, _ in
            
            var roundModules = testModules
            
            if roundModules.count > 1 {
                
                let firstIndex = Int(arc4random_uniform(UInt32(roundModules.count)))
                let first = roundModules.removeAtIndex(firstIndex)
                
                let secondIndex = Int(arc4random_uniform(UInt32(roundModules.count)))
                let second = roundModules.removeAtIndex(secondIndex)
                let pair = ModulePair(first, second)
                observer.sendNext(pair)
                observer.sendCompleted()
            }
            
            //TODO: Handle Error cases
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    func nextRound(modules: ModulePair) -> SignalProducer<RoundProtocol, NSError> {
        return SignalProducer { observer, _ in
            
            let elo = EloRating()
            let round = Round(firstModule: modules.0, secondModule: modules.1, elo: elo)
            observer.sendNext(round)
            observer.sendCompleted()
        }
    }
}


