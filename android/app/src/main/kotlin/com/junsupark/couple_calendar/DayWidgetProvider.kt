package com.junsupark.couple_calendar

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.text.SpannableString
import android.text.Spanned
import android.text.style.ForegroundColorSpan
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar
import java.util.TimeZone

/**
 * 홈 화면 "D+일수" 위젯. 앱(lib/data/day_widget.dart)이 넘긴 사귄 날짜로 일수를 직접 계산한다.
 * 시작일이 D+1이다 (CoupleProfile.dayCountOn과 같다).
 */
class DayWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val views = RemoteViews(context.packageName, R.layout.day_widget)
        val start = widgetData.getString("startDate", null)?.let(::parseDate)
        val myName = widgetData.getString("myName", null)
        val partnerName = widgetData.getString("partnerName", null)

        if (start == null || myName == null || partnerName == null) {
            views.setTextViewText(R.id.day_widget_names, "데이로그")
            views.setTextViewText(R.id.day_widget_days, "♡")
            views.setTextViewText(R.id.day_widget_next, "앱에서 커플을 연결해 주세요")
        } else {
            val dayCount = daysBetween(start, today()) + 1
            val nextMilestone = (dayCount / 100 + 1) * 100
            views.setTextViewText(R.id.day_widget_names, names(myName, partnerName))
            views.setTextViewText(R.id.day_widget_days, "D+$dayCount")
            views.setTextViewText(
                R.id.day_widget_next,
                "${nextMilestone}일까지 ${nextMilestone - dayCount}일",
            )
        }
        views.setOnClickPendingIntent(
            R.id.day_widget_root,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
        )
        appWidgetIds.forEach { appWidgetManager.updateAppWidget(it, views) }
    }

    /** "준수 ♥ 서진". 하트만 앱의 코랄색(primaryContainer)으로 칠한다. */
    private fun names(myName: String, partnerName: String): CharSequence {
        val heart = "\u2665\uFE0E"
        val text = SpannableString("$myName $heart $partnerName")
        val at = myName.length + 1
        text.setSpan(
            ForegroundColorSpan(Color.parseColor("#E07A5F")),
            at,
            at + heart.length,
            Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
        )
        return text
    }

    /** "yyyy-MM-dd" → 그 날짜의 UTC 자정(ms). 시간대·서머타임과 무관하게 날짜 차이를 세기 위해서다. */
    private fun parseDate(s: String): Long? {
        val parts = s.split("-").mapNotNull { it.toIntOrNull() }
        if (parts.size != 3) return null
        return utcMidnight(parts[0], parts[1] - 1, parts[2])
    }

    private fun today(): Long {
        val now = Calendar.getInstance()
        return utcMidnight(
            now.get(Calendar.YEAR),
            now.get(Calendar.MONTH),
            now.get(Calendar.DAY_OF_MONTH),
        )
    }

    private fun utcMidnight(year: Int, month: Int, day: Int): Long =
        Calendar.getInstance(TimeZone.getTimeZone("UTC")).run {
            clear()
            set(year, month, day)
            timeInMillis
        }

    private fun daysBetween(from: Long, to: Long): Int = ((to - from) / 86_400_000L).toInt()
}
