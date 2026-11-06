package com.aeh.fjelia

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import android.net.Uri
import android.content.Context
import java.io.File

class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine? = ActivityRecordingService.engine
    // The service retains the same isolate if Android destroys just the UI.
    override fun shouldDestroyEngineWithHost(): Boolean = false
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ActivityRecordingService.engine = flutterEngine
        val recordingChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fjelia/activity_recording")
        ActivityRecordingService.channel = recordingChannel
        recordingChannel.setMethodCallHandler { call, result ->
            if (call.method == "clock") {
                result.success(android.os.SystemClock.elapsedRealtime())
            } else if (call.method == "configure" && call.arguments is Map<*, *>) {
                ActivityRecordingService.configure(this, call.arguments as Map<*, *>, result)
            } else {
                result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fjelia/workout_text")
            .setMethodCallHandler { call, result ->
                val path = call.arguments as? String
                if (call.method != "recognize" || path == null) {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                try {
                    val image = InputImage.fromFilePath(this, Uri.fromFile(File(path)))
                    recognizer.process(image)
                        .addOnSuccessListener { text ->
                            val rotated = image.rotationDegrees == 90 || image.rotationDegrees == 270
                            val width = (if (rotated) image.height else image.width).toDouble()
                            val height = (if (rotated) image.width else image.height).toDouble()
                            val lines = text.textBlocks.flatMap { block -> block.lines }.mapNotNull { line ->
                                line.boundingBox?.let { box ->
                                    mapOf("text" to line.text,
                                        "left" to box.left / width, "top" to box.top / height,
                                        "width" to box.width() / width, "height" to box.height() / height)
                                }
                            }
                            result.success(lines)
                        }
                        .addOnFailureListener {
                            result.error("workout_photo", "Could not read this photo. Try a clearer image or enter the values.", null)
                        }
                        .addOnCompleteListener { recognizer.close() }
                } catch (_: Exception) {
                    recognizer.close()
                    result.error("workout_photo", "Could not open this photo.", null)
                }
            }
    }
}
