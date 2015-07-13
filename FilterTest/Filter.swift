//
//  Filter.swift
//  FilterTest
//
//  Created by Jia Jing on 7/8/15.
//  Copyright (c) 2015 Jia Jing. All rights reserved.
//

import Foundation
import CoreImage
import Box

protocol Filter {
    func filter(filter: ConcreteFilter) -> ConcreteFilter
}

protocol ConcreteFilter: Filter {
    var outputImage: CIImage { get }
}


struct FilterGroup: ConcreteFilter {
    var outputImage: CIImage { return FilterGroup.reduceFilters(subFilters).outputImage }
    let subFilters: [Filter]
    func filter(filter: ConcreteFilter) -> ConcreteFilter {
        return FilterGroup.reduceFilters(subFilters).filter(filter)
    }
    static func reduceFilters(filters: [Filter]) -> ConcreteFilter {
        var log = filters.reduce("reducing"){"\($0) + \($1)"}
        let result: ConcreteFilter
        if filters.count < 2 {
            result = filters[0] as! ConcreteFilter
        } else {
            result = filters[1 ..< filters.count].reduce(filters.first as! ConcreteFilter){$1.filter($0)}
        }
        log += " -> \(result)"
//        println(log)
        return result
    }
}

func / <A>(lhs:[A], rhs: A -> Filter) -> ConcreteFilter {
    return FilterGroup.reduceFilters(lhs.map(rhs))
}

protocol BlendFilter: ConcreteFilter {
    func blend(background: CIImage, overlay: CIImage) -> CIImage
}

//applies effect to the input filter, returns a new CoverBlendFilter
protocol EffectFilter: Filter {
    func applyEffect(background: CIImage) -> CIImage
}
//
////creates a new BlendFilter
//protocol BlendModeFilter: Filter {
//    func createFilter(input: CIImage) -> BlendFilter
//}


//simply returns the top layer
struct ConcreteImage: BlendFilter {
    let outputImage: CIImage
    func filter(filter: ConcreteFilter) -> ConcreteFilter {
        return self
    }
    func blend(background: CIImage, overlay: CIImage) -> CIImage {
        return overlay
    }
}


protocol Updatable: class {
    func update()
}

internal protocol SimpleUpdatable: Updatable {
    func advance() -> Bool
    func emit()
}

protocol Syncable {
    var synced: Synced { get }
}


class Synced {
    weak var syncedUpon : SynchronizedUpon? {
        willSet(newSyncedUpon){
            if let oldSyncedUpon = syncedUpon, newSyncedUpon = newSyncedUpon where newSyncedUpon !== oldSyncedUpon { oldSyncedUpon.unregisterSynced(self) }
            if let newSyncedUpon = newSyncedUpon { newSyncedUpon.registerSynced(self) }
        }
    }
    func notifyUpdated() -> Bool{
        return syncedUpon?.notifyUpdated(self) ?? false
    }
}

class SynchronizedUpon {
    let onSynchronized : (Void -> Void)?
    typealias SyncStatus = (Synced, Bool)
    var isSynchronized = [SyncStatus]()
    private let lock = NSLock()
    
    required init(onSynchronized: (Void -> Void)?){
        self.onSynchronized = onSynchronized
    }
    
    
    func registerSynced(synced : Synced) {
        lock.lock()
        if !isSynchronized.reduce( false, combine: { $0 || $1.0 === synced }) {
            isSynchronized.append((synced, false))
        }
        lock.unlock()
    }
    
    func unregisterSynced(synced: Synced){
        isSynchronized = self.isSynchronized.filter { $0.0 !== synced }
        lock.lock()
        isSynced()
        lock.unlock()
    }
    
    func notifyUpdated(synced : Synced) -> Bool{
        lock.lock()
        isSynchronized = isSynchronized.map{ $0.0 === synced ? (synced, true) : $0}
        let syn = isSynced()
        lock.unlock()
        return syn
    }
    
    private func isSynced() -> Bool{
        if !isSynchronized.reduce(true, combine : {$0 && $1.1}) { return false }
        isSynchronized = isSynchronized.map{($0.0, false)}
        dispatch_async(dispatch_get_main_queue()){onSynchronized?()}
        return true
    }
    
    func newSynced() -> Synced {
        let synced = Synced()
        synced.syncedUpon = self
        return synced
    }
}

class UpdateManager{
    private var updatables: [Updatable] = []
    private let updateQueue = dispatch_queue_create("tv.kaipai.decode", DISPATCH_QUEUE_CONCURRENT)
    func next() {
        self.updatables.map{ element in dispatch_async(self.updateQueue){element.update()}}
    }
    func registerUpdatable(updatable: Updatable){
        if !self.updatables.reduce(false, combine: {$0 || $1 === updatable}) {
            self.updatables.append(updatable)
        }
    }
    func unregisterUpdatable(updatable: Updatable){
        self.updatables = self.updatables.filter{ $0 !== updatable }
    }
}
