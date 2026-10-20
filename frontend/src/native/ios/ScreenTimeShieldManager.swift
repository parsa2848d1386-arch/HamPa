// ============================================================================
// بخش ۵.۲: ماژول بومی iOS و iPadOS جهت قفل سخت‌گیرانه (Screen Time API)
// پیاده‌سازی FamilyControls، ManagedSettings، DeviceActivity و اشتراک داده با App Groups
// ============================================================================

import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import ActivityKit

@available(iOS 16.0, *)
public class ScreenTimeShieldManager: ObservableObject {
    public static let shared = ScreenTimeShieldManager()
    
    // شناسه استور محافظت شده
    private let store = ManagedSettingsStore()
    
    // اشتراک داده میان اپلیکیشن اصلی و Extension از طریق App Group
    private let appGroupSuite = "group.ir.hampa.app"
    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupSuite)
    }
    
    // نام اکتیویتی اختصاصی تمرکز
    private let focusActivityName = DeviceActivityName("ir.hampa.focusSession")
    
    private init() {}
    
    /**
     ۱. درخواست دسترسی مجوز رسمی Screen Time به صورت انفرادی (Individual Authorization)
     */
    public func requestAuthorization() async throws {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            print("✅ دسترسی Screen Time با موفقیت تأیید شد.")
        } catch {
            print("❌ خطا در اخذ دسترسی Screen Time: \(error.localizedDescription)")
            throw error
        }
    }
    
    /**
     ۲. اعمال قفل و شیلد بومی (ManagedSettings Shield) روی برنامه‌های غیرمجاز
     */
    public func applyShield(for selection: FamilyActivitySelection, durationMinutes: Int) {
        // اعمال مسدودسازی برنامه‌ها و وب‌سایت‌های انتخاب شده
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        
        // ذخیره اطلاعات وضعیت در App Group جهت تطبیق بعدی در صورت بسته شدن برنامه
        sharedDefaults?.set(true, forKey: "is_strict_lock_active")
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "lock_start_timestamp")
        sharedDefaults?.set(durationMinutes, forKey: "lock_duration_minutes")
        
        // ۳. ثبت مانیتور DeviceActivity در پس‌زمینه سیستم‌عامل
        scheduleDeviceActivityMonitor(durationMinutes: durationMinutes)
    }
    
    /**
     ۴. برداشتن قفل و بازگردانی دسترسی عادی
     */
    public func liftShield() {
        store.shield.applications = nil
        store.shield.webDomains = nil
        
        let center = DeviceActivityCenter()
        center.stopMonitoring([focusActivityName])
        
        sharedDefaults?.set(false, forKey: "is_strict_lock_active")
        print("🔓 قفل برنامه‌ها با موفقیت باز شد.")
    }
    
    /**
     ۵. زمان‌بندی دقیق جهت برداشته شدن خودکار شیلد در پس‌زمینه حتی در صورت بسته بودن اپلیکیشن
     */
    private func scheduleDeviceActivityMonitor(durationMinutes: Int) {
        let center = DeviceActivityCenter()
        
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        let event = DeviceActivityEvent(
            applications: store.shield.applications ?? Set(),
            threshold: DateComponents(minute: durationMinutes)
        )
        
        do {
            try center.startMonitoring(
                focusActivityName,
                during: schedule,
                events: [DeviceActivityEvent.Name("focusThreshold"): event]
            )
        } catch {
            print("❌ خطا در ثبت DeviceActivityCenter: \(error)")
        }
    }
}

// ============================================================================
// DeviceActivityMonitorExtension (اجرا شونده به صورت مستقل در هسته iOS)
// ============================================================================
@available(iOS 16.0, *)
public class HamPADeviceActivityMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore()
    let sharedDefaults = UserDefaults(suiteName: "group.ir.hampa.app")
    
    public override func eventDidReachThreshold(
        event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event: event, activity: activity)
        
        // وقتی مدت زمان سشن به پایان رسید، شیلد به صورت خودکار در هسته سیستم‌عامل برداشته می‌شود
        store.shield.applications = nil
        store.shield.webDomains = nil
        
        // ثبت رکورد پایان سشن برای بارگذاری مجدد بعدی
        sharedDefaults?.set(true, forKey: "pending_session_reconciliation_needed")
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "session_finished_at")
    }
}
