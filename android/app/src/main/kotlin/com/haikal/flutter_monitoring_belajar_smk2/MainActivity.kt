package com.haikal.flutter_monitoring_belajar_smk2

import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.haikal.monitoring/secure_screen"
    private val PICK_PDF_REQUEST_CODE = 9921
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableSecure" -> {
                    runOnUiThread {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(true)
                }
                "disableSecure" -> {
                    runOnUiThread {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(true)
                }
                "pickPdf" -> {
                    pendingResult = result
                    try {
                        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                            type = "application/pdf"
                            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                            addCategory(Intent.CATEGORY_OPENABLE)
                        }
                        startActivityForResult(intent, PICK_PDF_REQUEST_CODE)
                    } catch (e: Exception) {
                        pendingResult?.error("PICK_PDF_ERROR", e.message, null)
                        pendingResult = null
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == PICK_PDF_REQUEST_CODE) {
            if (resultCode == RESULT_OK && data != null) {
                val paths = mutableListOf<String>()
                if (data.clipData != null) {
                    val count = data.clipData!!.itemCount
                    for (i in 0 until count) {
                        val uri = data.clipData!!.getItemAt(i).uri
                        val path = getPathFromUri(uri)
                        if (path != null) paths.add(path)
                    }
                } else if (data.data != null) {
                    val path = getPathFromUri(data.data!!)
                    if (path != null) paths.add(path)
                }
                pendingResult?.success(paths)
            } else {
                pendingResult?.success(emptyList<String>())
            }
            pendingResult = null
        }
    }

    private fun getPathFromUri(uri: Uri): String? {
        return try {
            val inputStream = contentResolver.openInputStream(uri) ?: return null
            val fileName = getFileName(uri) ?: "picked_document.pdf"
            val file = File(cacheDir, fileName)
            val outputStream = FileOutputStream(file)
            inputStream.copyTo(outputStream)
            inputStream.close()
            outputStream.close()
            file.absolutePath
        } catch (e: Exception) {
            null
        }
    }

    private fun getFileName(uri: Uri): String? {
        var name: String? = null
        val cursor = contentResolver.query(uri, null, null, null, null)
        cursor?.use {
            if (it.moveToFirst()) {
                val index = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (index != -1) {
                    name = it.getString(index)
                }
            }
        }
        return name
    }
}
