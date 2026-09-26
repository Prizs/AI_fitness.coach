package com.example.mobile_app

import android.content.Intent
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.mobile_app/app_update"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAppInfo" -> result.success(appInfo())
                    "getCacheDir" -> result.success(cacheDir.absolutePath)
                    "installApk" -> result.success(installApk(call.argument<String>("path")))
                    else -> result.notImplemented()
                }
            }
    }

    /** Nombre y codigo de version de la app instalada. */
    private fun appInfo(): Map<String, Any> {
        val info = packageManager.getPackageInfo(packageName, 0)
        val code = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            info.versionCode.toLong()
        }
        return mapOf<String, Any>(
            "versionName" to (info.versionName ?: "desconocida"),
            "versionCode" to code,
            "packageName" to packageName,
        )
    }

    /** Abre el instalador del sistema con el APK descargado. */
    private fun installApk(path: String?): Boolean {
        if (path.isNullOrBlank()) return false
        val file = File(path)
        if (!file.exists()) return false
        return try {
            val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            true
        } catch (error: Exception) {
            false
        }
    }
}
