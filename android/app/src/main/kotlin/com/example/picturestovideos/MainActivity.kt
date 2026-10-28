package com.example.picturestovideos

import android.app.Activity
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val channelName = "picturestovideos/android_saf_folder"
    private val requestCode = 43817
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingFolderResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickImagesFromFolder" -> {
                        if (pendingFolderResult != null) {
                            result.error("picker_busy", "A folder picker is already open.", null)
                            return@setMethodCallHandler
                        }
                        pendingFolderResult = result
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        try {
                            startActivityForResult(intent, requestCode)
                        } catch (error: Exception) {
                            pendingFolderResult = null
                            result.error("picker_unavailable", error.message, null)
                        }
                    }
                    "removeImportedImages" -> removeImportedImages(call.argument("paths") ?: emptyList(), result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun removeImportedImages(paths: List<String>, result: MethodChannel.Result) {
        executor.execute {
            try {
                val importDirectory = File(filesDir, "imported_images").canonicalFile
                for (path in paths) {
                    val file = File(path).canonicalFile
                    if (file.parentFile != importDirectory || !file.exists()) continue
                    if (!file.delete()) {
                        throw IllegalStateException("Could not remove an imported image.")
                    }
                }
                mainHandler.post { result.success(null) }
            } catch (error: Exception) {
                mainHandler.post {
                    result.error("import_cleanup_failed", error.message, null)
                }
            }
        }
    }

    @Deprecated("Deprecated in Android API; retained for FlutterActivity result forwarding")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != this.requestCode) return

        val result = pendingFolderResult ?: return
        pendingFolderResult = null
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result.success(emptyList<Map<String, Any>>())
            return
        }

        val treeUri = data.data!!
        executor.execute {
            try {
                val files = copySupportedImages(treeUri)
                mainHandler.post { result.success(files) }
            } catch (error: Exception) {
                mainHandler.post {
                    result.error("folder_import_failed", error.message, null)
                }
            }
        }
    }

    private fun copySupportedImages(treeUri: Uri): List<Map<String, Any>> {
        val rootId = DocumentsContract.getTreeDocumentId(treeUri)
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
            treeUri,
            rootId,
        )
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_SIZE,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
        )
        val cursor = contentResolver.query(childrenUri, projection, null, null, null)
            ?: throw IllegalStateException("The selected folder could not be read.")
        cursor.use { rows ->
            val imported = mutableListOf<Map<String, Any>>()
            val importDirectory = File(filesDir, "imported_images").apply { mkdirs() }
            while (rows.moveToNext()) {
                val mimeType = rows.string(DocumentsContract.Document.COLUMN_MIME_TYPE)
                if (mimeType == DocumentsContract.Document.MIME_TYPE_DIR) continue
                val name = rows.string(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
                    ?: continue
                if (name.substringAfterLast('.', "").lowercase() !in
                    setOf("jpg", "jpeg", "png", "webp")
                ) continue

                val documentId = rows.string(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
                    ?: continue
                val fileUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, documentId)
                val destination = File(
                    importDirectory,
                    "${sha256(fileUri.toString())}_${safeName(name)}",
                )
                contentResolver.openInputStream(fileUri).use { input ->
                    if (input == null) throw IllegalStateException("Could not read $name.")
                    destination.outputStream().use { output -> input.copyTo(output) }
                }
                val reportedSize = rows.long(DocumentsContract.Document.COLUMN_SIZE)
                val modifiedOn = rows.long(DocumentsContract.Document.COLUMN_LAST_MODIFIED)
                val result = mutableMapOf<String, Any>(
                    "name" to name,
                    "path" to destination.absolutePath,
                    "size" to if (reportedSize > 0) reportedSize else destination.length(),
                )
                if (modifiedOn > 0) result["modifiedOn"] = modifiedOn
                imported.add(result)
            }
            return imported.sortedBy {
                (it["name"] as String).lowercase()
            }
        }
    }

    private fun Cursor.string(columnName: String): String? {
        val index = getColumnIndex(columnName)
        return if (index >= 0 && !isNull(index)) getString(index) else null
    }

    private fun Cursor.long(columnName: String): Long {
        val index = getColumnIndex(columnName)
        return if (index >= 0 && !isNull(index)) getLong(index) else 0L
    }

    private fun safeName(name: String): String =
        name.replace(Regex("[^A-Za-z0-9._-]"), "_").take(100)

    private fun sha256(value: String): String =
        MessageDigest.getInstance("SHA-256")
            .digest(value.toByteArray())
            .joinToString("") { "%02x".format(it) }

    override fun onDestroy() {
        pendingFolderResult = null
        executor.shutdown()
        super.onDestroy()
    }
}
