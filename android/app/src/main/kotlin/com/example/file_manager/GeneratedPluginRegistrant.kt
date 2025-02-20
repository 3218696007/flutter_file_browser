package com.example.file_manager

import androidx.annotation.Keep
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.shim.ShimPluginRegistry

@Keep
public final class GeneratedPluginRegistrant {
    companion object {
        fun registerWith(@NonNull flutterEngine: FlutterEngine) {
            flutterEngine.plugins.add(FileOpenerPlugin())
        }
    }
}