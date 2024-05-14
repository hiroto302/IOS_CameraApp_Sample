import SwiftUI

class CountDownTimer {
    var time: Float
    var timer: Timer?
    var countdownCompletionHandler: ((Result<Void, Error>) -> Void)?

    init(time: Float, timer: Timer? = nil, countdownCompletionHandler: ( (Result<Void, Error>) -> Void)? = nil) {
        self.time = time
        self.timer = timer
        self.countdownCompletionHandler = countdownCompletionHandler
    }

    func startTimer() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.time > 0 {
                self.time -= 1
            } else {
                self.stopTimer()
                self.countdownCompletionHandler?(.success(()))
            }
        }
    }

    func stopTimer() {
        self.timer?.invalidate()
        self.timer = nil
    }
}
