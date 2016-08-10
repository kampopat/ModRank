//
//  RoundViewController.swift
//  ModRank
//
//  Created by Kam Popat on 26/07/2016.
//  Copyright © 2016 Kam Popat. All rights reserved.
//

import Foundation
import UIKit
import ReactiveCocoa
import enum Result.NoError
import Chameleon
import FirebaseDatabase


enum Winner {
    case First, Second
}

public class RoundViewController: UIViewController {
    
    
    typealias ButtonSignal = Signal<Winner, NoError>
    
    private var fireRef: FIRDatabaseReference!
    private var _currentRound: RoundProtocol!
    
    //UI Components
    private var _firstModuleButton: UIButton = UIButton()
    private var _secondModuleButton: UIButton = UIButton()
    
    //Signals
    private var _roundProducer: SignalProducer<RoundProtocol, NSError>
    private var (_firstButtonSignal, _firstButtonObserver) = ButtonSignal.pipe()
    private var (_secondButtonSignal, _secondButtonObserver) = ButtonSignal.pipe()
    private var (_winnerSignal, _winnerObserver) = Signal<ButtonSignal, NoError>.pipe()
    
    
    ////////////////////////////////////////////////////////////////////////////////
    init(roundProducer: SignalProducer<RoundProtocol, NSError>) {
        self._roundProducer = roundProducer
        
        _firstButtonSignal = _firstModuleButton
            .signalForControlEvents(.TouchUpInside).map({
                return Winner.First
            })
        
        _secondButtonSignal = _secondModuleButton
            .signalForControlEvents(.TouchUpInside).map({
                return Winner.Second
            })

        super.init(nibName: nil, bundle: nil)
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.flatNavyBlueColorDark()
      
        self._roundProducer.startWithResult { (result) in
            
            switch result {
            case let .Success(round):
                self._currentRound = round
                self.setUpViewWithRound()
                self.observeWinnerSignal()
            case let .Failure(error):
                print("Error: \(error)")
            }
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    private func observeWinnerSignal() {
        
        _winnerSignal.flatten(.Merge)//.take(1)
            .observeNext { winner in
                self._currentRound.declareModuleWinner(winner).start()
        }
        
        _winnerObserver.sendNext(_firstButtonSignal)
        _winnerObserver.sendNext(_secondButtonSignal)
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    private func setUpViewWithRound() {
        
        self._currentRound.firstRef.observeSingleEventOfType(.Value,
            withBlock: { snapshot in
                
                if let val = snapshot.value as? [String: AnyObject] {
                    let name: String = val["name"] as! String
                    self._firstModuleButton.setTitle(name, forState: .Normal)
                }
        })
        
        self._currentRound.secondRef.observeSingleEventOfType(
            .Value,
            withBlock: { snapshot in
                
                if let val = snapshot.value as? [String: AnyObject] {
                    let name: String = val["name"] as! String
                    self._secondModuleButton.setTitle(name, forState: .Normal)
                }
        })
        
        let buttonback = UIColor.whiteColor().colorWithAlphaComponent(0.5)
        
        self._firstModuleButton.backgroundColor = buttonback
        self._secondModuleButton.backgroundColor = buttonback
        
        
        let minVal = min(self.view.frame.height, self.view.frame.width) - 100.0
        let buttonSize = CGSize(width: minVal, height: minVal)
        
        let firstFrame = CGRect(origin: CGPointZero, size: buttonSize)
        
        let secondOrigin = CGPoint(x: self.view.frame.width - buttonSize.width, y: 0.0)
        let secondFrame = CGRect(origin: secondOrigin, size: buttonSize)
        
        self._firstModuleButton.frame = firstFrame
        self._secondModuleButton.frame = secondFrame
        
        let radius = minVal / 2.0
        
        self._firstModuleButton.layer.cornerRadius =  radius
        self._firstModuleButton.clipsToBounds = true
        self._secondModuleButton.layer.cornerRadius = radius
        
        self.view.addSubview(_firstModuleButton)
        self.view.addSubview(_secondModuleButton)
    }
    
}