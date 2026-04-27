package com.example.better_brushing

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.KeyEvent

class MainActivity : FlutterActivity() {
    private val channelName = "better_brushing/volume_buttons"
    private var channel: MethodChannel? = null
    private var volumePauseEnabled = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "setEnabled" -> {
                    volumePauseEnabled = call.arguments == true
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (
            volumePauseEnabled &&
            event?.repeatCount == 0 &&
            (keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN)
        ) {
            channel?.invokeMethod("volumeButtonPressed", keyCode)
            return true
        }
        return super.onKeyDown(keyCode, event)
    }
}
