//
//  HistoryViewModel.swift
//  Brush WatchKit Extension
//
//  Created by Bastiaan Jansen on 27/06/2020.
//

import Foundation
import HealthKit

class HistoryViewModel: ObservableObject {
    @Published var data: [HKCategorySample] = []
    
    var averageSeconds: Int {
        let seconds: [Int] = data.map { ($0.endDate - $0.startDate).second! }
        let total = seconds.reduce(0, +)
        
        if total > 0 {
            return total / seconds.count
        }
        
        return 0
    }
    
    init() {
        updateData()
    }
    
    func updateData() {
        
        if HKHealthStore.isHealthDataAvailable() {
            let healthStore = HKHealthStore()
           
            guard let sampleType = HKSampleType.categoryType(forIdentifier: .toothbrushingEvent) else {
                fatalError("This method should never fail")
            }
            
            let observerQuery = HKObserverQuery(sampleType: sampleType, predicate: nil) { query, completionHandler, error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                
                let query = HKSampleQuery(sampleType: sampleType, predicate: nil, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [
                    NSSortDescriptor(key: "startDate", ascending: false)
                ]) { query, results, error in
                    guard let results = results as? [HKCategorySample] else {
                        fatalError(error?.localizedDescription ?? "Something went wrong")
                    }

                    DispatchQueue.main.async {
                        self.data = results
                    }
                }
                
                healthStore.execute(query)
                completionHandler()
            }
            
            healthStore.execute(observerQuery)
        } else {
            print("Healthkit not available")
        }
    }
    
    func deleteSample(sample: HKCategorySample) {
        if HKHealthStore.isHealthDataAvailable() {
            let healthStore = HKHealthStore()
            healthStore.delete(sample) { success, error in
                if let error = error {
                    fatalError(error.localizedDescription)
                }
            }
        } else {
            fatalError("Healthkit not available")
        }
    }
}
