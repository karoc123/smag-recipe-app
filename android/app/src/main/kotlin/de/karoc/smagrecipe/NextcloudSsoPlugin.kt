package de.karoc.smagrecipe

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.util.Log
import com.google.gson.GsonBuilder
import com.nextcloud.android.sso.AccountImporter
import com.nextcloud.android.sso.api.NextcloudAPI
import com.nextcloud.android.sso.aidl.NextcloudRequest
import com.nextcloud.android.sso.exceptions.NextcloudFilesAppNotInstalledException
import com.nextcloud.android.sso.exceptions.AndroidGetAccountsPermissionNotGranted
import com.nextcloud.android.sso.exceptions.NoCurrentAccountSelectedException
import com.nextcloud.android.sso.exceptions.NextcloudFilesAppAccountNotFoundException
import com.nextcloud.android.sso.helper.SingleAccountHelper
import com.nextcloud.android.sso.model.SingleSignOnAccount
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.ByteArrayInputStream
import java.io.BufferedReader
import java.io.InputStreamReader

/**
 * Flutter platform channel that bridges the Nextcloud Android-SingleSignOn
 * library so Dart code can authenticate and make API calls.
 */
class NextcloudSsoPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
    ActivityAware, PluginRegistry.ActivityResultListener {

    companion object {
        private const val CHANNEL = "de.karoc.smagrecipe/nextcloud_sso"
        private const val TAG = "NextcloudSsoPlugin"
        private const val PICK_ACCOUNT_REQUEST = 38571
    }

    private var channel: MethodChannel? = null
    private var activity: Activity? = null
    private var pendingResult: MethodChannel.Result? = null
    private var nextcloudApi: NextcloudAPI? = null

    // -------------------------------------------------------------------------
    // FlutterPlugin
    // -------------------------------------------------------------------------

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        nextcloudApi?.close()
        nextcloudApi = null
    }

    // -------------------------------------------------------------------------
    // ActivityAware
    // -------------------------------------------------------------------------

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() { activity = null }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() { activity = null }

    // -------------------------------------------------------------------------
    // MethodChannel handler
    // -------------------------------------------------------------------------

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickAccount" -> pickAccount(result)
            "getCurrentAccount" -> getCurrentAccount(result)
            "resetAccount" -> resetAccount(result)
            "performRequest" -> {
                val method = call.argument<String>("method") ?: "GET"
                val url = call.argument<String>("url") ?: ""
                val body = call.argument<String>("body")
                performRequest(method, url, body, result)
            }
            "performBinaryRequest" -> {
                val url = call.argument<String>("url") ?: ""
                performBinaryRequest(url, result)
            }
            "performBinaryUpload" -> {
                val method = call.argument<String>("method") ?: "PUT"
                val url = call.argument<String>("url") ?: ""
                val body = call.argument<ByteArray>("body") ?: ByteArray(0)
                val contentType = call.argument<String>("contentType")
                    ?: "application/octet-stream"
                @Suppress("UNCHECKED_CAST")
                val headers = call.argument<Map<String, String>>("headers")
                    ?: emptyMap()
                performBinaryUpload(method, url, body, contentType, headers, result)
            }
            else -> result.notImplemented()
        }
    }

    // -------------------------------------------------------------------------
    // Account management
    // -------------------------------------------------------------------------

    private fun pickAccount(result: MethodChannel.Result) {
        val act = activity
        if (act == null) {
            result.error("NO_ACTIVITY", "No attached activity", null)
            return
        }
        pendingResult = result
        try {
            AccountImporter.pickNewAccount(act)
        } catch (e: NextcloudFilesAppNotInstalledException) {
            pendingResult = null
            result.error("NC_NOT_INSTALLED",
                "Nextcloud app is not installed", null)
        } catch (e: AndroidGetAccountsPermissionNotGranted) {
            pendingResult = null
            result.error("NO_PERMISSION",
                "Account permission not granted", null)
        }
    }

    private fun getCurrentAccount(result: MethodChannel.Result) {
        try {
            val ctx = activity ?: run {
                result.error("NO_ACTIVITY", "No attached activity", null)
                return
            }
            val account = SingleAccountHelper.getCurrentSingleSignOnAccount(ctx)
            result.success(mapOf(
                "name" to account.name,
                "userId" to account.userId,
                "url" to account.url
            ))
        } catch (e: NextcloudFilesAppAccountNotFoundException) {
            result.success(null)
        } catch (e: NoCurrentAccountSelectedException) {
            result.success(null)
        }
    }

    private fun resetAccount(result: MethodChannel.Result) {
        val ctx = activity ?: run {
            result.error("NO_ACTIVITY", "No attached activity", null)
            return
        }
        SingleAccountHelper.commitCurrentAccount(ctx, "")
        nextcloudApi?.close()
        nextcloudApi = null
        result.success(null)
    }

    // -------------------------------------------------------------------------
    // Authenticated API calls
    // -------------------------------------------------------------------------

    private fun getOrCreateApi(): NextcloudAPI? {
        if (nextcloudApi != null) return nextcloudApi
        val ctx = activity ?: return null
        val account: SingleSignOnAccount
        try {
            account = SingleAccountHelper.getCurrentSingleSignOnAccount(ctx)
        } catch (e: Exception) {
            return null
        }
        nextcloudApi = NextcloudAPI(ctx, account, GsonBuilder().create())
        return nextcloudApi
    }

    private fun performRequest(
        method: String, url: String, body: String?,
        result: MethodChannel.Result
    ) {
        Thread {
            try {
                val api = getOrCreateApi()
                if (api == null) {
                    activity?.runOnUiThread {
                        result.error("NO_ACCOUNT", "No Nextcloud account", null)
                    }
                    return@Thread
                }
                val builder = NextcloudRequest.Builder()
                    .setMethod(method)
                    .setUrl(Uri.encode(url, "/?&="))
                if (body != null) builder.setRequestBody(body)

                val response = api.performNetworkRequestV2(builder.build())
                val reader = BufferedReader(InputStreamReader(response.body))
                val text = reader.readText()
                reader.close()

                activity?.runOnUiThread { result.success(text) }
            } catch (e: Exception) {
                Log.e(TAG, "Request failed: ${e.message}", e)
                activity?.runOnUiThread {
                    result.error("REQUEST_FAILED", e.message, null)
                }
            }
        }.start()
    }

    private fun performBinaryRequest(url: String, result: MethodChannel.Result) {
        Thread {
            try {
                val api = getOrCreateApi()
                if (api == null) {
                    activity?.runOnUiThread {
                        result.error("NO_ACCOUNT", "No Nextcloud account", null)
                    }
                    return@Thread
                }
                val request = NextcloudRequest.Builder()
                    .setMethod("GET")
                    .setUrl(Uri.encode(url, "/?&="))
                    .build()
                val response = api.performNetworkRequestV2(request)
                val bytes = response.body.readBytes()
                // Skip default SVG placeholder
                if (bytes.size < 500 && String(bytes).trimStart().startsWith("<svg")) {
                    activity?.runOnUiThread { result.success(null) }
                    return@Thread
                }
                activity?.runOnUiThread { result.success(bytes) }
            } catch (e: Exception) {
                Log.e(TAG, "Binary request failed: ${e.message}", e)
                activity?.runOnUiThread { result.success(null) }
            }
        }.start()
    }

    private fun performBinaryUpload(
        method: String,
        url: String,
        body: ByteArray,
        contentType: String,
        headers: Map<String, String>,
        result: MethodChannel.Result
    ) {
        Thread {
            try {
                val api = getOrCreateApi()
                if (api == null) {
                    activity?.runOnUiThread {
                        result.error("NO_ACCOUNT", "No Nextcloud account", null)
                    }
                    return@Thread
                }
                val requestHeaders = mutableMapOf<String, List<String>>()
                requestHeaders["Content-Type"] = listOf(contentType)
                for ((key, value) in headers) {
                    requestHeaders[key] = listOf(value)
                }
                val request = NextcloudRequest.Builder()
                    .setMethod(method)
                    .setUrl(Uri.encode(url, "/?&="))
                    .setHeader(requestHeaders)
                    .setRequestBodyAsStream(ByteArrayInputStream(body))
                    .build()
                api.performNetworkRequestV2(request).body.close()
                activity?.runOnUiThread { result.success(null) }
            } catch (e: Exception) {
                Log.e(TAG, "Binary upload failed: ${e.message}", e)
                activity?.runOnUiThread {
                    result.error("REQUEST_FAILED", e.message, null)
                }
            }
        }.start()
    }

    // -------------------------------------------------------------------------
    // Activity result callback (SSO account picker)
    // -------------------------------------------------------------------------

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        try {
            AccountImporter.onActivityResult(requestCode, resultCode, data, activity) { account ->
                val ctx = activity ?: return@onActivityResult
                SingleAccountHelper.commitCurrentAccount(ctx, account.name)
                // Reset API so it uses the new account.
                nextcloudApi?.close()
                nextcloudApi = null
                pendingResult?.success(mapOf(
                    "name" to account.name,
                    "userId" to account.userId,
                    "url" to account.url
                ))
                pendingResult = null
            }
        } catch (e: Exception) {
            Log.e(TAG, "onActivityResult error: ${e.message}", e)
            pendingResult?.error("ACCOUNT_ERROR", e.message, null)
            pendingResult = null
        }
        return pendingResult == null
    }
}
