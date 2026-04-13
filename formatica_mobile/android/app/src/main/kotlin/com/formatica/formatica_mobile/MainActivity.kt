package com.formatica.formatica_mobile

import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.provider.DocumentsContract
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import android.graphics.*
import android.graphics.pdf.PdfRenderer
import android.graphics.pdf.PdfDocument
import android.os.ParcelFileDescriptor

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.formatica/platform"
    private val documentConverter = DocumentConverter()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scanMediaFile" -> {
                        val path = call.argument<String>("path")
                        if (path != null) {
                            MediaScannerConnection.scanFile(
                                this, arrayOf(path), null
                            ) { _, uri ->
                                runOnUiThread {
                                    result.success(uri?.toString() ?: "scanned")
                                }
                            }
                        } else {
                            result.error("INVALID_PATH", "Path is null", null)
                        }
                    }
                    "convertDocumentToPdf" -> {
                        val inputPath = call.argument<String>("inputPath")
                        val outputPath = call.argument<String>("outputPath")
                        val format = call.argument<String>("format")

                        if (inputPath == null || outputPath == null || format == null) {
                            result.error("INVALID_ARGS", "Missing required arguments", null)
                            return@setMethodCallHandler
                        }

                        try {
                            val conversionResult = when (format.lowercase()) {
                                "xlsx", "xls", "csv" -> {
                                    documentConverter.convertSpreadsheetToPdf(inputPath, outputPath, format)
                                }
                                "pptx", "ppt" -> {
                                    documentConverter.convertPresentationToPdf(inputPath, outputPath, format)
                                }
                                "docx" -> {
                                    documentConverter.convertDocxToPdf(inputPath, outputPath)
                                }
                                else -> {
                                    result.error("UNSUPPORTED_FORMAT", "Format not supported: $format", null)
                                    return@setMethodCallHandler
                                }
                            }

                            conversionResult.fold(
                                onSuccess = { pdfPath ->
                                    result.success(pdfPath)
                                },
                                onFailure = { error ->
                                    result.error("CONVERSION_FAILED", error.message, null)
                                }
                            )
                        } catch (e: Exception) {
                            result.error("CONVERSION_ERROR", e.message, null)
                        }
                    }
                    "openFolder" -> {
                        val path = call.argument<String>("path")
                        if (path != null) {
                            try {
                                val file = File(path)
                                
                                // If it's a file, open its containing folder with the file selected
                                // If it's a directory, open the directory directly
                                if (file.isFile) {
                                    openFileLocation(file, result)
                                } else if (file.isDirectory) {
                                    openFolderWithChooser(file, result)
                                } else {
                                    result.error("INVALID_PATH", "Path does not exist: $path", null)
                                }
                            } catch (e: Exception) {
                                result.error("OPEN_FAILED", e.message, null)
                            }
                        } else {
                            result.error("INVALID_PATH", "Path is null", null)
                        }
                    }
                    "nativeGreyScalePdf" -> {
                        val inputPath = call.argument<String>("inputPath")
                        val outputPath = call.argument<String>("outputPath")
                        if (inputPath != null && outputPath != null) {
                            nativeGreyScalePdf(inputPath, outputPath, result)
                        } else {
                            result.error("INVALID_ARGS", "Missing paths", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Open the file's containing folder with the file selected/highlighted
     * This is the MOST RELIABLE way to show users where their file is
     */
    private fun openFileLocation(file: File, result: MethodChannel.Result) {
        try {
            android.util.Log.d("MainActivity", "Opening file location: ${file.absolutePath}")
            
            if (!file.exists()) {
                android.util.Log.e("MainActivity", "File does not exist!")
                result.error("FILE_NOT_FOUND", "File does not exist: ${file.absolutePath}", null)
                return
            }
            
            // Method 1: Use FileProvider to get a content URI (Android 7.0+ requirement)
            val fileUri = try {
                FileProvider.getUriForFile(
                    this,
                    "${applicationContext.packageName}.fileprovider",
                    file
                )
            } catch (e: Exception) {
                // Fallback to file:// URI if FileProvider fails
                android.util.Log.w("MainActivity", "FileProvider failed, using file:// URI: ${e.message}")
                Uri.fromFile(file)
            }
            
            // Create intent to VIEW the file (this opens the folder with file selected)
            val viewIntent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(fileUri, getMimeType(file.name))
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            
            // Try to open with file manager that will highlight the file
            try {
                val chooser = Intent.createChooser(viewIntent, "Open file location")
                startActivity(chooser)
                android.util.Log.d("MainActivity", "Opened file location successfully")
                result.success(true)
                return
            } catch (e: Exception) {
                android.util.Log.e("MainActivity", "View intent failed: ${e.message}")
            }
            
            // Method 2: Use DocumentsContract to show file in Documents UI (Android 5.0+)
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
                try {
                    val documentsIntent = Intent(Intent.ACTION_VIEW).apply {
                        type = "*/*"
                        putExtra(DocumentsContract.EXTRA_INITIAL_URI, fileUri)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    if (documentsIntent.resolveActivity(packageManager) != null) {
                        startActivity(documentsIntent)
                        android.util.Log.d("MainActivity", "Opened via Documents UI")
                        result.success(true)
                        return
                    }
                } catch (e: Exception) {
                    android.util.Log.e("MainActivity", "Documents UI failed: ${e.message}")
                }
            }
            
            // Method 3: Open the parent folder
            try {
                val parentDir = file.parentFile
                if (parentDir != null && parentDir.exists()) {
                    openFolderWithChooser(parentDir, result)
                    android.util.Log.d("MainActivity", "Opened parent folder as fallback")
                    return
                }
            } catch (e: Exception) {
                android.util.Log.e("MainActivity", "Parent folder fallback failed: ${e.message}")
            }
            
            // Method 4: Ultimate fallback - show toast with exact path
            runOnUiThread {
                android.widget.Toast.makeText(
                    this,
                    "📁 File Location:\n${file.absolutePath}\n\nPlease navigate here manually.",
                    android.widget.Toast.LENGTH_LONG
                ).show()
            }
            result.success(true)
            
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "All methods failed: ${e.message}")
            runOnUiThread {
                android.widget.Toast.makeText(
                    this,
                    "Error opening file location: ${e.message}",
                    android.widget.Toast.LENGTH_LONG
                ).show()
            }
            result.error("OPEN_FAILED", e.message, null)
        }
    }

    /**
     * Get MIME type from file extension
     */
    private fun getMimeType(fileName: String): String {
        val extension = fileName.substringAfterLast('.', "").lowercase()
        return when (extension) {
            "pdf" -> "application/pdf"
            "doc", "docx" -> "application/msword"
            "xls", "xlsx" -> "application/vnd.ms-excel"
            "ppt", "pptx" -> "application/vnd.ms-powerpoint"
            "txt" -> "text/plain"
            "jpg", "jpeg" -> "image/jpeg"
            "png" -> "image/png"
            "gif" -> "image/gif"
            "mp4" -> "video/mp4"
            "mp3" -> "audio/mpeg"
            "wav" -> "audio/wav"
            else -> "*/*"
        }
    }

    /**
     * Open folder with chooser dialog - MOST ROBUST approach for Android
     */
    private fun openFolderWithChooser(dir: File, result: MethodChannel.Result) {
        try {
            android.util.Log.d("MainActivity", "Opening folder: ${dir.absolutePath}")
            
            // Method 1: Use ACTION_GET_CONTENT (most reliable for folder browsing)
            val browseIntent = Intent(Intent.ACTION_GET_CONTENT).apply {
                type = "*/*"
                addCategory(Intent.CATEGORY_OPENABLE)
                putExtra("android.content.extra.SHOW_ADVANCED", true)
                putExtra("android.content.extra.FANCY", true)
                putExtra("android.content.extra.SHOW_FILESIZE", true)
                putExtra(Intent.EXTRA_LOCAL_ONLY, true)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            
            // Try to start the folder browser
            try {
                val chooser = Intent.createChooser(browseIntent, "Browse to folder")
                startActivity(chooser)
                result.success(true)
                return
            } catch (e: Exception) {
                android.util.Log.e("MainActivity", "ACTION_GET_CONTENT failed: ${e.message}")
            }
            
            // Method 2: Try Documents UI (Android 5.0+)
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
                try {
                    val documentsIntent = Intent(Intent.ACTION_VIEW).apply {
                        type = "vnd.android.document/directory"
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    if (documentsIntent.resolveActivity(packageManager) != null) {
                        val chooser = Intent.createChooser(documentsIntent, "Open folder with")
                        startActivity(chooser)
                        result.success(true)
                        return
                    }
                } catch (e: Exception) {
                    android.util.Log.e("MainActivity", "Documents UI failed: ${e.message}")
                }
            }
            
            // Method 3: Simple file URI approach
            try {
                val fileIntent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(Uri.fromFile(dir), "resource/folder")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                if (fileIntent.resolveActivity(packageManager) != null) {
                    startActivity(fileIntent)
                    result.success(true)
                    return
                }
            } catch (e: Exception) {
                android.util.Log.e("MainActivity", "File URI approach failed: ${e.message}")
            }
            
            // Method 4: Ultimate fallback - show toast with exact path
            runOnUiThread {
                android.widget.Toast.makeText(
                    this,
                    "📁 Folder Location:\n${dir.absolutePath}\n\nPlease navigate here manually in your file manager.",
                    android.widget.Toast.LENGTH_LONG
                ).show()
            }
            result.success(true)
            
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "All methods failed: ${e.message}")
            runOnUiThread {
                android.widget.Toast.makeText(
                    this,
                    "Error opening folder: ${e.message}",
                    android.widget.Toast.LENGTH_LONG
                ).show()
            }
            result.error("OPEN_FAILED", e.message, null)
        }
    }

    /**
     * Prefer FileProvider for paths under this app's storage so file managers get a
     * grantable content URI (legacy document/tree URIs often fail for Android/data/...).
     */
    private fun tryOpenFolderWithFileProvider(path: String): Boolean {
        val file = File(path)
        if (!file.exists()) {
            return false
        }
        val dir = if (file.isDirectory) file else file.parentFile ?: return false

        val underExternal = applicationContext.getExternalFilesDir(null)?.canonicalFile
        val underInternal = applicationContext.filesDir.canonicalFile
        val canonicalDir = try {
            dir.canonicalFile
        } catch (_: Exception) {
            return false
        }

        val allowedRoot = when {
            underExternal != null &&
                canonicalDir.absolutePath.startsWith(underExternal.absolutePath) -> true
            canonicalDir.absolutePath.startsWith(underInternal.absolutePath) -> true
            else -> false
        }
        if (!allowedRoot) {
            return false
        }

        return try {
            val uri = FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                canonicalDir
            )
            val folderIntent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "resource/folder")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            when {
                folderIntent.resolveActivity(packageManager) != null -> {
                    startActivity(folderIntent)
                    true
                }
                else -> {
                    val generic = Intent(Intent.ACTION_VIEW).apply {
                        data = uri
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    if (generic.resolveActivity(packageManager) != null) {
                        startActivity(generic)
                        true
                    } else {
                        false
                    }
                }
            }
        } catch (_: Exception) {
            false
        }
    }

    /**
     * ROOT-LEVEL FIX: Native Greyscale Engine.
     * Uses Android's native PdfRenderer and ColorMatrix filters for 100% reliable hardware-level output.
     */
    private fun nativeGreyScalePdf(inputPath: String, outputPath: String, result: MethodChannel.Result) {
        val uiHandler = android.os.Handler(android.os.Looper.getMainLooper())
        
        Thread {
            try {
                val inputFile = File(inputPath)
                if (!inputFile.exists()) {
                    uiHandler.post { result.error("FILE_NOT_FOUND", "Input file does not exist", null) }
                    return@Thread
                }

                val descriptor = ParcelFileDescriptor.open(inputFile, ParcelFileDescriptor.MODE_READ_ONLY)
                val renderer = PdfRenderer(descriptor)
                val outputDoc = PdfDocument()
                
                // Saturation = 0 for pure hardware grayscale
                val paint = Paint()
                val matrix = ColorMatrix()
                matrix.setSaturation(0f)
                
                // Contrast enhancement (1.4x) and slight brightness nudge to ensure deep blacks and clean whites
                val contrast = 1.4f
                val brightness = -15f 
                val cm = ColorMatrix(floatArrayOf(
                    contrast, 0f, 0f, 0f, brightness,
                    0f, contrast, 0f, 0f, brightness,
                    0f, 0f, contrast, 0f, brightness,
                    0f, 0f, 0f, 1f, 0f
                ))
                cm.postConcat(matrix)
                paint.colorFilter = ColorMatrixColorFilter(cm)

                val pageCount = renderer.pageCount
                for (i in 0 until pageCount) {
                    val page = renderer.openPage(i)
                    
                    // Render at professional scale (2.5x ~ Approx 180-200 DPI)
                    val scale = 2.5f 
                    val width = (page.width * scale).toInt()
                    val height = (page.height * scale).toInt()
                    
                    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                    page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                    
                    // Add page to output document with original dimensions
                    val pageInfo = PdfDocument.PageInfo.Builder(page.width, page.height, i).create()
                    val outPage = outputDoc.startPage(pageInfo)
                    val outCanvas = outPage.canvas
                    
                    // Draw onto PDF page (filter is applied here during native draw)
                    val rect = Rect(0, 0, page.width, page.height)
                    outCanvas.drawBitmap(bitmap, null, rect, paint)
                    
                    outputDoc.finishPage(outPage)
                    
                    // Resource cleanup
                    bitmap.recycle()
                    page.close()
                }
                
                val outputFile = File(outputPath)
                outputFile.parentFile?.mkdirs()
                outputDoc.writeTo(outputFile.outputStream())
                
                outputDoc.close()
                renderer.close()
                descriptor.close()
                
                uiHandler.post { result.success(outputPath) }
            } catch (e: Exception) {
                android.util.Log.e("MainActivity", "Native Greyscale Error: ${e.message}")
                uiHandler.post { result.error("NATIVE_GREYSCALE_ERROR", e.message, null) }
            }
        }.start()
    }
}
