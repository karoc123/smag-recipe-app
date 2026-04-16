package de.karoc.smag

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val INTENT_CHANNEL = "de.karoc.smag/intent"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(NextcloudSsoPlugin())
        
        // Setup intent channel to forward URLs to Dart
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INTENT_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialUrl" -> {
                        val url = getInitialUrl()
                        result.success(url)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.action == Intent.ACTION_VIEW) {
            val url = intent.dataString
            // The URL will be fetched when Dart calls getInitialUrl()
        }
    }

    private fun getInitialUrl(): String? {
        val intent = intent
        val action = intent?.action
        val data = intent?.dataString
        
        return if (action == Intent.ACTION_VIEW && data != null) {
            data
        } else {
            null
        }
    }
}
