//
//  RecorderTimer.swift
//  SummaryAI
//
//  Created by 超方 on 2024/3/30.
//

import Foundation

// Defines a delegate protocol for handling timer stop events.
protocol TimerDelegate {
    func timerStopped() -> Void
}

final class RecorderTimer: ObservableObject {
    @Published var secondsElapsed = 0   // total num of seconds after timer started
    var delegate: TimerDelegate?
    
    // timer stopped means recording is stopped.
    var timerStopped = true {
        didSet {
            if timerStopped {
                timer?.invalidate()
                // Notify the delegate that the timer has stopped.
                delegate?.timerStopped()
                startDate = nil
                print("Timer stopped")
            }
        }
    }

    private weak var timer: Timer?      // Weak reference to the timer to avoid retain cycles.
    private var frequency: TimeInterval { AppConstants.RecorderTimerFrequency }     // Timer update frequency.
    private var startDate: Date?        // The date when the timer started.
    private var silenctTimer: TimeInterval = 0     // Time in seconds since the last audio input.
    
    func startTimer(isSilent: @escaping ()->Bool) {
        timerStopped = false
        startDate = Date()
        silenctTimer = startDate!.timeIntervalSince1970
        
        // Create a timer that fires repeatedly based on the frequency.
        timer = Timer.scheduledTimer(withTimeInterval: frequency, repeats: true) { [weak self] _ in
            self?.update() {       // Call the update method on each timer fire.
                isSilent()
            }
        }
        timer?.tolerance = 0.1      // Set a tolerance for the timer to improve performance.
    }
    // Updates the timer state.
    nonisolated private func update(isSilent: @escaping ()->Bool) {
        guard let startDate, !timerStopped else { return }      // Ensure the timer is running and has a start date.
        let curSeconds = Date().timeIntervalSince1970
        self.secondsElapsed = Int(curSeconds - startDate.timeIntervalSince1970)

        if secondsElapsed > AppConstants.MaxRecordSeconds {
            // worked more than max record time, turn off
            self.timerStopped = true
        }

        if isSilent() {
            if curSeconds - self.silenctTimer > Double(AppConstants.MaxSilentSeconds) {
                // silent for max silent time, turn off
                self.timerStopped = true
            }
        } else {
            self.silenctTimer = curSeconds  // reset silence timer if there is input audio
        }
    }
    
    func stopTimer() {
        timerStopped = true
    }
}
