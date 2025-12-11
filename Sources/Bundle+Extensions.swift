import Foundation

#if !SWIFT_PACKAGE
extension Bundle {
    static var module: Bundle { Bundle.main }
}
#endif
