//
//  EloRating.swift
//  ModRank
//
//  Created by Kam Popat on 25/07/2016.
//  Copyright © 2016 Kam Popat. All rights reserved.
//

import Foundation
import ReactiveCocoa
import enum Result.NoError

// --------------------
// MARK: Rounding
// --------------------
extension Double {
    /// Rounds the double to decimal places value
    func roundToPlaces(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return round(self * divisor) / divisor
    }
}

// --------------------
// MARK: Classification
// --------------------
enum Classification {
    case Winner, Loser
}

// --------------------
// MARK: Elo Rating Protocol
// --------------------
protocol EloRatingProtocol {
    
    func expectedWinProbability(forModule fRating: Double, againstModule aRating: Double)
        -> Double
    
    func newRating(forRating rating: Double,
                             withClassification classification: Classification, expected: Double, kFactor: Int)
        -> SignalProducer<Double, NoError>
}

// --------------------
// MARK: EloRating
// --------------------
struct EloRating: EloRatingProtocol {
    
    func expectedWinProbability(forModule fRating: Double, againstModule aRating: Double) -> Double {
        return 1 / (1 +  pow(10.0, ((aRating-fRating)/400.0)))
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    func newRating(forRating rating: Double, withClassification classification: Classification, expected: Double, kFactor: Int)
        -> SignalProducer<Double, NoError> {
            
            switch classification {
            case .Winner:
                return winnerNewRating(rating, expected: expected, kFactor: kFactor)
            case .Loser:
                return loserNewRating(rating, expected: expected, kFactor: kFactor)
            }
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    private func loserNewRating(current: Double, expected: Double, kFactor: Int)
        -> SignalProducer<Double, NoError> {
            return SignalProducer { observer, _ in
                let rating = current + ( Double(kFactor) * (0-expected))
                observer.sendNext(rating.roundToPlaces(3))
                observer.sendCompleted()
            }
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    private func winnerNewRating(current: Double, expected: Double, kFactor: Int)
        -> SignalProducer<Double, NoError> {
            return SignalProducer { observer, _ in
                let rating = current + ( Double(kFactor) * (1-expected))
                observer.sendNext(rating.roundToPlaces(3))
                observer.sendCompleted()
            }
    }
}











