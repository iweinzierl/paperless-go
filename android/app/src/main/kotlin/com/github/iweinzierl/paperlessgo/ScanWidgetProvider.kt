package com.github.iweinzierl.paperlessgo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/** Home screen widget that opens the scan screen with one tap. */
class ScanWidgetProvider : AppWidgetProvider() {
	override fun onUpdate(
		context: Context,
		appWidgetManager: AppWidgetManager,
		appWidgetIds: IntArray,
	) {
		val launchIntent = Intent(context, MainActivity::class.java).apply {
			action = MainActivity.ACTION_SCAN_DOCUMENT
			flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
		}
		val pendingIntent = PendingIntent.getActivity(
			context,
			0,
			launchIntent,
			PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
		)

		appWidgetIds.forEach { appWidgetId ->
			val views = RemoteViews(context.packageName, R.layout.scan_widget).apply {
				setOnClickPendingIntent(R.id.scan_widget_root, pendingIntent)
			}
			appWidgetManager.updateAppWidget(appWidgetId, views)
		}
	}
}
