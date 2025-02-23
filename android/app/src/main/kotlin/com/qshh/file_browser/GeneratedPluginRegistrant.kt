package com.qshh.file_browser

import androidx.annotation.Keep
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine

@Keep
class GeneratedPluginRegistrant {
    companion object {
        fun registerWith(@NonNull flutterEngine: FlutterEngine) {
            flutterEngine.plugins.add(FileOpenerPlugin())
        }
    }
}