
import Metal

final class MTLBufferPool {
    
    private var pool: [Int: [UInt: ContiguousArray<MTLBuffer>]] = [:]
    private let device: MTLDevice
    private let monitor = NSObject()
    
    init(device: MTLDevice) {
        self.device = device
    }
    
    subscript(length: Int, resourceOptions: MTLResourceOptions) -> MTLBuffer? {
        get {
            objc_sync_enter(monitor)
            defer { objc_sync_exit(monitor) }
            
            var availableBuffer = pool[length, default: [:]][resourceOptions.rawValue, default: []]
            if availableBuffer.isEmpty {
                return device.makeBuffer(length: length, options: resourceOptions)
                
            } else {
                defer { pool[length, default: [:]][resourceOptions.rawValue] = availableBuffer }
                return availableBuffer.removeLast()
            }
        }
        set {
            objc_sync_enter(monitor)
            defer { objc_sync_exit(monitor) }
            
            guard let newValue = newValue else { return }
            pool[length, default: [:]][resourceOptions.rawValue, default: []].append(newValue)
        }
    }
}
