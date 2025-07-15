package com.example.indocement_apk

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.indocement_apk/fakegps"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "isFakeGpsAppInstalled") {
                result.success(isFakeGpsAppInstalled(this))
            }
        }
    }

    fun isFakeGpsAppInstalled(context: Context): Boolean {
        val fakeGpsPackages = listOf(
            "com.lexa.fakegps", // Fake GPS Location
            "com.fakegps.mock", // Fake GPS
            "com.just4f.fun.gps", // GPS Joystick
            // Tambahkan package lain jika perlu
        )
        val pm = context.packageManager
        return fakeGpsPackages.any {
            try { pm.getPackageInfo(it, 0); true } catch (e: Exception) { false }
        }
    }
}