package com.qshh.file_browser

import android.content.Context
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

class FileOpenerPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.qshh.file_brower/file_opener")
        context = binding.applicationContext
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "openFile" -> {
                try {
                    val filePath = call.argument<String>("filePath")
                    val mimeType = call.argument<String>("mimeType")

                    if (filePath == null || mimeType == null) {
                        result.error("INVALID_ARGUMENTS", "File path or mime type is null", null)
                        return
                    }

                    val file = File(filePath)
                    if (!file.exists()) {
                        result.error("FILE_NOT_FOUND", "The file does not exist", null)
                        return
                    }

                    val uri = FileProvider.getUriForFile(
                        context,
                        "com.qshh.file_brower.fileprovider",
                        file
                    )

                    val viewIntent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(uri, mimeType)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }

                    if (viewIntent.resolveActivity(context.packageManager) != null) {
                        context.startActivity(viewIntent)
                        result.success(true)
                    } else {
                        // 如果没有默认应用，使用ACTION_CHOOSER让用户选择应用
                        val chooserIntent = Intent.createChooser(viewIntent, "选择打开方式").apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        context.startActivity(chooserIntent)
                        result.success(true)
                    }
                } catch (e: Exception) {
                    result.error("OPEN_ERROR", e.toString(), null)
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}