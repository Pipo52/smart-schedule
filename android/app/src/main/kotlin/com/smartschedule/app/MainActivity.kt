package com.smartschedule.app

import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "smart_schedule/battery",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isIgnoringBatteryOptimizations" -> {
                    val manager = getSystemService(POWER_SERVICE) as PowerManager
                    result.success(manager.isIgnoringBatteryOptimizations(packageName))
                }
                "openBatterySettings" -> {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.parse("package:$packageName")
                    }
                    startActivity(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "smart_schedule/widget",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "update" -> {
                    val payload = call.argument<String>("payload") ?: ""
                    ScheduleWidgetProvider.saveAndRefresh(this, payload)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
