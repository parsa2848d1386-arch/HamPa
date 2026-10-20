// ============================================================================
// بخش ۵.۲: ماژول بومی اندروید جهت مدیریت لیست سفید برنامه‌های مجاز (Android Whitelist)
// پیاده‌سازی سرویس پایش با AccessibilityService / UsageStatsManager و پنجره مسدودکننده
// ============================================================================

package ir.hampa.app.native

import android.accessibilityservice.AccessibilityService
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.widget.Button
import android.widget.TextView

class HamPAAccessibilityBlockerService : AccessibilityService() {

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var isStrictFocusActive: Boolean = false

    // لیست سفید برنامه‌های مجاز حین مطالعه (برنامه‌های درسی، ماشین‌حساب، هم‌پا)
    private val allowedPackageWhitelist = mutableSetOf(
        "ir.hampa.app",
        "com.android.calculator2",
        "com.google.android.calculator",
        "com.google.android.apps.docs",
        "com.adobe.reader"
    )

    override fun onServiceConnected() {
        super.onServiceConnected()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!isStrictFocusActive || event == null) return

        // پایش بسته‌ای که در فوکوس کاربر باز شده است
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val foregroundPackage = event.packageName?.toString() ?: return

            // اگر بسته جاری در لیست سفید مجاز نباشد، شیلد مسدودکننده ظاهر می‌شود
            if (!allowedPackageWhitelist.contains(foregroundPackage)) {
                showBlockerOverlay(foregroundPackage)
            } else {
                hideBlockerOverlay()
            }
        }
    }

    private fun showBlockerOverlay(blockedPackage: String) {
        if (overlayView != null) return // قبلاً باز است

        val layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER
        }

        // ساخت ویجت تمام‌صفحه مسدودسازی
        val view = View(this).apply {
            setBackgroundColor(0xF0161412.toInt()) // بوم تیره هم‌پا
        }

        try {
            windowManager?.addView(view, layoutParams)
            overlayView = view

            // بازگردانی کاربر به اپلیکیشن هم‌پا
            val returnIntent = packageManager.getLaunchIntentForPackage("ir.hampa.app")?.apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            }
            if (returnIntent != null) {
                startActivity(returnIntent)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun hideBlockerOverlay() {
        overlayView?.let {
            windowManager?.removeView(it)
            overlayView = null
        }
    }

    public fun setStrictFocus(active: Boolean) {
        isStrictFocusActive = active
        if (!active) {
            hideBlockerOverlay()
        }
    }

    public fun updateWhitelist(packages: List<String>) {
        allowedPackageWhitelist.clear()
        allowedPackageWhitelist.addAll(packages)
        allowedPackageWhitelist.add("ir.hampa.app")
    }

    override fun onInterrupt() {
        hideBlockerOverlay()
    }
}
