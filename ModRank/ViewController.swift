//
//  ViewController.swift
//  ModRank
//
//  Created by Kam Popat on 22/07/2016.
//  Copyright © 2016 Kam Popat. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    private var _matchmaker: MatchmakerProtocol
    private var _round: RoundProtocol?
    
    ////////////////////////////////////////////////////////////////////////////////
    init(matchmaker: MatchmakerProtocol) {
        self._matchmaker = matchmaker
        
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    ////////////////////////////////////////////////////////////////////////////////
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.redColor()
        
        
        
        self._matchmaker.roundProducer().startWithResult { (result) in
            
            print("result: \(result)")
        }
        
        self._matchmaker.roundProducer().startWithNext { round in
            self._round = round
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

