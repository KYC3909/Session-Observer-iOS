//


import Foundation
import UIKit

class SessionObserve: UIApplication {
    private var timerToDetectInactivity: Timer?
    private var timerExceededInSeconds: TimeInterval {
        return 10
    }
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { [weak self] foregroundNotification in
            guard let self = self else {return}
            self.instantiateTimer()
            print("willEnterForegroundNotification")
        }
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] foregroundNotification in
            guard let self = self else {return}
            self.resetTimer()
            print("didEnterBackgroundNotification")
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if let event = event {
            if timerToDetectInactivity != nil {
                self.instantiateTimer()
            }
            if let touches = event.allTouches {
                for touch in touches where touch.phase == UITouch.Phase.began {
                    self.instantiateTimer()
                }
            }
        }
        let wathecer = SessionObserveApp(sessionTime: 10, workItemProvider: DefaultWorkItemProvider(), queue: .main)
        
    }
    
    // reset the timer because there was user event
    private func resetTimer() {
        if let timerToDetectInactivity = timerToDetectInactivity {
            timerToDetectInactivity.invalidate()
        }
    }
    
    private func instantiateTimer() {
        resetTimer()
        
        timerToDetectInactivity = Timer.scheduledTimer(timeInterval: timerExceededInSeconds,
                                                       target: self,
                                                       selector: #selector(SessionObserve.timerHasExceeded),
                                                       userInfo: nil,
                                                       repeats: false
        )
    }
    @objc private func timerHasExceeded() {
        print("timerHasExceeded")
        
    }
}
protocol WorkItemProvider {
    func workItem(actionBlock: @escaping () -> ()) -> DispatchWorkItem?
}

class DefaultWorkItemProvider: WorkItemProvider {
    func workItem(actionBlock: @escaping () -> ()) -> DispatchWorkItem? {
        let newWorkItem = DispatchWorkItem { [weak self] in
            guard let _ = self else {return}
            print ("DefaultWorkItemProvider")
            actionBlock()
        }
        return newWorkItem
    }
}

class SessionObserveApp {
    private var workItemProvider: WorkItemProvider
    private var workItem: DispatchWorkItem?
    private let sessionTime: TimeInterval
    private let queue: DispatchQueue
    
    var onTimeExceeded: (() -> Void)?
    
    init(sessionTime: TimeInterval = 5, workItemProvider: WorkItemProvider, queue: DispatchQueue) {
        self.workItemProvider = workItemProvider
        self.sessionTime = sessionTime
        self.queue = queue
        let newWorkItem = DefaultWorkItemProvider().workItem { [weak self] in
            print ("init")
            self?.onTimeExceeded?()
        }
        workItem = newWorkItem
        if let workItem = workItem {
            queue.asyncAfter(deadline: .now() + sessionTime, execute: workItem)
        }
    }
    
    func cancelWorkTime() {
    }
    func start() {
        workItem?.cancel()
        let newWorkItem = workItemProvider.workItem { [weak self] in
            print ("start")
            self?.onTimeExceeded?()
        }
        workItem = newWorkItem
        if let workItem = workItem {
            queue.asyncAfter(deadline: .now() + sessionTime, execute: workItem)
        }
    }
    
    func receivedUserAction() {
        workItem?.cancel()
        start()
    }
    
    func stop() {
        workItem?.cancel()
    }
}
