package com.smartschedule.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import java.util.Calendar

class ScheduleWidgetProvider : AppWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_DATE_CHANGED,
            -> refresh(context)
            else -> super.onReceive(context, intent)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val views = buildViews(context)
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, views)
        }
        scheduleBoundary(context)
    }

    override fun onDisabled(context: Context) {
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarm.cancel(boundaryIntent(context))
    }

    companion object {
        private const val prefsName = "schedule_widget"
        private const val payloadKey = "payload"

        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, ScheduleWidgetProvider::class.java)
            val ids = manager.getAppWidgetIds(component)
            if (ids.isEmpty()) return
            val intent = Intent(context, ScheduleWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(intent)
        }

        fun saveAndRefresh(context: Context, payload: String) {
            context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
                .edit()
                .putString(payloadKey, payload)
                .apply()
            refresh(context)
        }
    }
}

private fun buildViews(context: Context): RemoteViews {
    val views = RemoteViews(context.packageName, R.layout.schedule_widget)
    val launch = PendingIntent.getActivity(
        context,
        0,
        Intent(context, MainActivity::class.java),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
    views.setOnClickPendingIntent(R.id.widget_root, launch)

    val raw = context
        .getSharedPreferences("schedule_widget", Context.MODE_PRIVATE)
        .getString("payload", null)
    if (raw.isNullOrEmpty()) {
        showEmpty(views, "Smart Schedule")
        return views
    }
    try {
        val json = JSONObject(raw)
        val lessons = json.optJSONArray("lessons")
        val now = System.currentTimeMillis()
        var index = -1
        if (lessons != null) {
            for (i in 0 until lessons.length()) {
                val end = lessons.getJSONObject(i).optLong("end")
                if (end > now) {
                    index = i
                    break
                }
            }
        }
        if (lessons == null || index < 0) {
            showEmpty(views, json.optString("empty", "Smart Schedule"))
            return views
        }
        val lesson = lessons.getJSONObject(index)
        val start = lesson.optLong("start")
        val end = lesson.optLong("end")
        val status = when {
            now in start until end -> json.optString("now")
            sameDay(start, now) -> json.optString("today")
            isTomorrow(start, now) -> json.optString("tomorrow")
            else -> lesson.optString("date")
        }
        views.setTextViewText(R.id.widget_status, status)
        views.setViewVisibility(R.id.widget_status, View.VISIBLE)
        views.setTextViewText(R.id.widget_subject, lesson.optString("subject"))
        views.setTextViewText(R.id.widget_time, lesson.optString("time"))
        views.setViewVisibility(R.id.widget_time, View.VISIBLE)
        val room = lesson.optString("room")
        if (room.isBlank()) {
            views.setViewVisibility(R.id.widget_room, View.GONE)
        } else {
            views.setViewVisibility(R.id.widget_room, View.VISIBLE)
            views.setTextViewText(R.id.widget_room, room)
        }
        if (index + 1 < lessons.length()) {
            val next = lessons.getJSONObject(index + 1)
            val prefix = json.optString("next")
            views.setViewVisibility(R.id.widget_next, View.VISIBLE)
            views.setTextViewText(
                R.id.widget_next,
                "$prefix: ${next.optString("subject")} ${next.optString("time")}",
            )
        } else {
            views.setViewVisibility(R.id.widget_next, View.GONE)
        }
    } catch (_: Exception) {
        showEmpty(views, "Smart Schedule")
    }
    return views
}

private fun showEmpty(views: RemoteViews, message: String) {
    views.setViewVisibility(R.id.widget_status, View.GONE)
    views.setTextViewText(R.id.widget_subject, message)
    views.setViewVisibility(R.id.widget_time, View.GONE)
    views.setViewVisibility(R.id.widget_room, View.GONE)
    views.setViewVisibility(R.id.widget_next, View.GONE)
}

private fun sameDay(a: Long, b: Long): Boolean {
    val left = Calendar.getInstance().apply { timeInMillis = a }
    val right = Calendar.getInstance().apply { timeInMillis = b }
    return left.get(Calendar.YEAR) == right.get(Calendar.YEAR) &&
        left.get(Calendar.DAY_OF_YEAR) == right.get(Calendar.DAY_OF_YEAR)
}

private fun isTomorrow(start: Long, now: Long): Boolean {
    val tomorrow = Calendar.getInstance().apply {
        timeInMillis = now
        add(Calendar.DAY_OF_YEAR, 1)
    }
    return sameDay(start, tomorrow.timeInMillis)
}

/// Local midnight a few seconds past 00:00, so "today" is already the new day.
/// Calendar, not a fixed 24 hours, so a daylight-saving change does not skip it.
private fun nextMidnightMillis(now: Long): Long {
    val calendar = Calendar.getInstance().apply { timeInMillis = now }
    calendar.add(Calendar.DAY_OF_YEAR, 1)
    calendar.set(Calendar.HOUR_OF_DAY, 0)
    calendar.set(Calendar.MINUTE, 0)
    calendar.set(Calendar.SECOND, 5)
    calendar.set(Calendar.MILLISECOND, 0)
    return calendar.timeInMillis
}

private fun scheduleBoundary(context: Context) {
    val now = System.currentTimeMillis()
    var boundary = nextMidnightMillis(now)
    val raw = context.getSharedPreferences("schedule_widget", Context.MODE_PRIVATE)
        .getString("payload", null)
    if (!raw.isNullOrEmpty()) {
        try {
            val lessons = JSONObject(raw).optJSONArray("lessons")
            if (lessons != null) {
                for (i in 0 until lessons.length()) {
                    val lesson = lessons.getJSONObject(i)
                    for (key in arrayOf("start", "end")) {
                        val at = lesson.optLong(key)
                        if (at > now + 5_000 && at < boundary) boundary = at
                    }
                }
            }
        } catch (_: Exception) {
        }
    }
    val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    val pending = boundaryIntent(context)
    try {
        alarm.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, boundary, pending)
    } catch (_: SecurityException) {
        alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, boundary, pending)
    }
}

private fun boundaryIntent(context: Context): PendingIntent {
    val manager = AppWidgetManager.getInstance(context)
    val component = ComponentName(context, ScheduleWidgetProvider::class.java)
    val ids = manager.getAppWidgetIds(component)
    val intent = Intent(context, ScheduleWidgetProvider::class.java).apply {
        action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
    }
    return PendingIntent.getBroadcast(
        context,
        42,
        intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
}
