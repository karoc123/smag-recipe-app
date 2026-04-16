package de.karoc.smag

import android.content.Intent
import android.util.Patterns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val INTENT_CHANNEL = "de.karoc.smag/intent"
    private var pendingUrl: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(NextcloudSsoPlugin())
        
        // Setup intent channel to forward URLs to Dart
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INTENT_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialUrl" -> {
                        val url = consumeIncomingUrl()
                        result.success(url)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        pendingUrl = extractIncomingUrl(intent)
    }

    private fun consumeIncomingUrl(): String? {
        val fromPending = pendingUrl
        if (!fromPending.isNullOrBlank()) {
            pendingUrl = null
            return fromPending
        }
        return extractIncomingUrl(intent)
    }

    private fun extractIncomingUrl(intent: Intent?): String? {
        if (intent == null) return null

        if (intent.action == Intent.ACTION_VIEW) {
            val data = intent.dataString
            if (data != null && (data.startsWith("http://") || data.startsWith("https://"))) {
                return data
            }
        }

        if (intent.action == Intent.ACTION_SEND && intent.type == "text/plain") {
            val text = intent.getStringExtra(Intent.EXTRA_TEXT) ?: return null
            val matcher = Patterns.WEB_URL.matcher(text)
            while (matcher.find()) {
                val candidate = text.substring(matcher.start(), matcher.end())
                if (candidate.startsWith("http://") || candidate.startsWith("https://")) {
                    return candidate
                }
            }
        }

        return null
    }
}
