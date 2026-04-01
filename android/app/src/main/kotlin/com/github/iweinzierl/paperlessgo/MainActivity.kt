package com.github.iweinzierl.paperlessgo

import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import android.util.Log
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.IOException

class MainActivity : FlutterFragmentActivity() {
	private var pendingInitialPdfPath: String? = null
	private var eventSink: EventChannel.EventSink? = null

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		WindowCompat.enableEdgeToEdge(window)
		deliverIncomingPdf(intent, preferPending = true)
	}

	override fun onNewIntent(intent: Intent) {
		super.onNewIntent(intent)
		setIntent(intent)
		deliverIncomingPdf(intent, preferPending = false)
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			CHANNEL_NAME,
		).setMethodCallHandler { call, result ->
			when (call.method) {
				"consumeInitialPdfPath" -> {
					result.success(pendingInitialPdfPath)
					pendingInitialPdfPath = null
				}

				else -> result.notImplemented()
			}
		}

		EventChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			EVENTS_CHANNEL_NAME,
		).setStreamHandler(
			object : EventChannel.StreamHandler {
				override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
					eventSink = events
				}

				override fun onCancel(arguments: Any?) {
					eventSink = null
				}
			},
		)
	}

	private fun deliverIncomingPdf(intent: Intent?, preferPending: Boolean) {
		val pdfPath = extractPdfPath(intent) ?: return
		if (preferPending || eventSink == null) {
			pendingInitialPdfPath = pdfPath
			return
		}

		eventSink?.success(pdfPath)
	}

	private fun extractPdfPath(intent: Intent?): String? {
		if (intent == null) {
			return null
		}

		val uri = when (intent.action) {
			Intent.ACTION_VIEW -> intent.data
			Intent.ACTION_SEND -> extractStreamUri(intent)
			else -> null
		} ?: return null

		if (!isPdfIntent(intent, uri)) {
			return null
		}

		return copyPdfToCache(uri)
	}

	private fun isPdfIntent(intent: Intent, uri: Uri): Boolean {
		val mimeType = intent.type ?: contentResolver.getType(uri)
		if (mimeType?.equals("application/pdf", ignoreCase = true) == true) {
			return true
		}

		return uri.lastPathSegment?.lowercase()?.endsWith(".pdf") == true
	}

	private fun copyPdfToCache(uri: Uri): String? {
		return try {
			val incomingDirectory = File(cacheDir, "incoming-pdf").apply {
				mkdirs()
			}
			val destination = File(
				incomingDirectory,
				"${System.currentTimeMillis()}-${resolveFileName(uri)}",
			)

			openInputStream(uri)?.use { input ->
				destination.outputStream().use { output ->
					input.copyTo(output)
				}
			} ?: return null

			destination.absolutePath
		} catch (error: IOException) {
			Log.e(TAG, "Failed to import PDF", error)
			null
		}
	}

	private fun openInputStream(uri: Uri) = when (uri.scheme?.lowercase()) {
		"file" -> {
			val filePath = uri.path ?: return null
			FileInputStream(filePath)
		}

		else -> contentResolver.openInputStream(uri)
	}

	private fun resolveFileName(uri: Uri): String {
		val displayName = if (uri.scheme.equals("content", ignoreCase = true)) {
			queryDisplayName(uri)
		} else {
			uri.lastPathSegment?.substringAfterLast('/')
		}

		val normalizedName = when {
			displayName.isNullOrBlank() -> "document.pdf"
			displayName.lowercase().endsWith(".pdf") -> displayName
			else -> "$displayName.pdf"
		}

		return normalizedName.replace(Regex("[^A-Za-z0-9._-]"), "_")
	}

	private fun extractStreamUri(intent: Intent): Uri? {
		return if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
			intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
		} else {
			@Suppress("DEPRECATION")
			intent.getParcelableExtra(Intent.EXTRA_STREAM) as? Uri
		}
	}

	private fun queryDisplayName(uri: Uri): String? {
		val cursor: Cursor = contentResolver.query(
			uri,
			arrayOf(OpenableColumns.DISPLAY_NAME),
			null,
			null,
			null,
		) ?: return null

		cursor.use {
			if (!it.moveToFirst()) {
				return null
			}

			val columnIndex = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
			if (columnIndex < 0) {
				return null
			}

			return it.getString(columnIndex)
		}
	}

	companion object {
		private const val TAG = "MainActivity"
		private const val CHANNEL_NAME = "com.github.iweinzierl.paperlessgo/open_document"
		private const val EVENTS_CHANNEL_NAME =
			"com.github.iweinzierl.paperlessgo/open_document/events"
	}
}