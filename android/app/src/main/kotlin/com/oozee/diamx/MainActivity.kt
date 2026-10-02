package com.oozee.diamx

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
    private val downloadsChannel = "com.oozee.diamxpro/downloads"
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            downloadsChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSdkInt" -> {
                    result.success(Build.VERSION.SDK_INT)
                }

                "saveToDownloads" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val fileName = call.argument<String>("fileName")
                    if (sourcePath.isNullOrBlank() || fileName.isNullOrBlank()) {
                        result.error(
                            "invalid_args",
                            "sourcePath and fileName are required",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    Thread {
                        try {
                            val savedPath = savePdfToPublicDownloads(sourcePath, fileName)
                            mainHandler.post { result.success(savedPath) }
                        } catch (error: Exception) {
                            mainHandler.post {
                                result.error(
                                    "save_failed",
                                    error.message ?: "Unable to save PDF to Downloads",
                                    null,
                                )
                            }
                        }
                    }.start()
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun savePdfToPublicDownloads(sourcePath: String, fileName: String): String {
        val source = File(sourcePath)
        if (!source.exists() || source.length() <= 0L) {
            throw IllegalArgumentException("Source PDF not found or empty")
        }

        val safeName = sanitizeFileName(fileName)

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            saveWithMediaStore(source, safeName)
        } else {
            saveWithLegacyFileApi(source, safeName)
        }
    }

    private fun saveWithMediaStore(source: File, fileName: String): String {
        val resolver = applicationContext.contentResolver
        val collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI

        // Remove prior pending/failed entry with same name if possible.
        try {
            resolver.delete(
                collection,
                "${MediaStore.MediaColumns.DISPLAY_NAME}=?",
                arrayOf(fileName),
            )
        } catch (_: Exception) {
            // Ignore — not critical.
        }

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
            put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }

        val itemUri = resolver.insert(collection, values)
            ?: throw IllegalStateException("Unable to create Downloads MediaStore entry")

        try {
            resolver.openOutputStream(itemUri)?.use { output ->
                FileInputStream(source).use { input ->
                    input.copyTo(output)
                    output.flush()
                }
            } ?: throw IllegalStateException("Unable to open Downloads output stream")

            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            resolver.update(itemUri, values, null, null)
        } catch (error: Exception) {
            try {
                resolver.delete(itemUri, null, null)
            } catch (_: Exception) {
            }
            throw error
        }

        return "${Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)}/$fileName"
    }

    @Suppress("DEPRECATION")
    private fun saveWithLegacyFileApi(source: File, fileName: String): String {
        val downloadsDir =
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        if (!downloadsDir.exists() && !downloadsDir.mkdirs()) {
            throw IllegalStateException("Unable to create Downloads folder")
        }
        val dest = File(downloadsDir, fileName)
        source.copyTo(dest, overwrite = true)
        if (!dest.exists() || dest.length() <= 0L) {
            throw IllegalStateException("PDF was not written to Downloads")
        }
        return dest.absolutePath
    }

    private fun sanitizeFileName(raw: String): String {
        val cleaned = raw.replace(Regex("""[\\/:*?"<>|]"""), "_").trim()
        return if (cleaned.isEmpty()) {
            "Diamx_${System.currentTimeMillis()}.pdf"
        } else if (cleaned.lowercase().endsWith(".pdf")) {
            cleaned
        } else {
            "$cleaned.pdf"
        }
    }
}
