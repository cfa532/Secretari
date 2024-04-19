//
//  RecorderTimer.swift
//  SummaryAI
//
//  Created by 超方 on 2024/3/30.
//

import Foundation

protocol TimerDelegate {
    func timerStopped() -> Void
}

//@MainActor
final class RecorderTimer: ObservableObject {
    @Published var secondsElapsed = 0   // total num of seconds after timer started
    var delegate: TimerDelegate?
    
    // time stopped means recording is stopped.
    var timerStopped = true {
        didSet {
            if timerStopped {
                timer?.invalidate()
                delegate?.timerStopped()    // send query to Ai
                startDate = nil
                print("Timer stopped")
            }
        }
    }

    private weak var timer: Timer?
    private var frequency: TimeInterval { 1.0 }
    private var startDate: Date?
    private var silenctTimer: TimeInterval = 0     // num of seconds of no audio input
    
    func startTimer(isSilent: @escaping ()->Bool) {
        timerStopped = false
        startDate = Date()
        silenctTimer = startDate!.timeIntervalSince1970
        
        timer = Timer.scheduledTimer(withTimeInterval: frequency, repeats: true) { [weak self] _ in
            self?.update() { isSilent() }
        }
        timer?.tolerance = 0.1
    }
    
    nonisolated private func update(isSilent: @escaping ()->Bool) {
//        Task { @MainActor in
            guard let startDate, !timerStopped else { return }
            let curSeconds = Date().timeIntervalSince1970
            self.secondsElapsed = Int(curSeconds - startDate.timeIntervalSince1970)

            if secondsElapsed > 28800 {
                // worked more than 8hrs, turn off
                self.timerStopped = true
            }

            if isSilent() {
                if curSeconds - self.silenctTimer > 1800 {
                    // silent for 30mins, turn off
                    self.timerStopped = true
                }
            } else {
                self.silenctTimer = curSeconds  // reset silence timer if there is input audio
            }
//        }
    }
    
    func stopTimer() {
        timerStopped = true
//        timer?.invalidate()
//        startDate = nil
    }
}
