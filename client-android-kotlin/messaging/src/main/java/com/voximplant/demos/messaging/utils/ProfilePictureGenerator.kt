package com.voximplant.demos.messaging.utils

import android.graphics.*

object ProfilePictureGenerator {
    fun createTextImage(text: String): Bitmap {
        val bitmap = Bitmap.createBitmap(140, 140, Bitmap.Config.ARGB_8888)

        val canvas = Canvas(bitmap)

        val colorPaint = Paint()

        colorPaint.color = randomColor
        colorPaint.isAntiAlias = true

        canvas.drawRect(0f, 0f, 140f, 140F, colorPaint)

        val textPaint = Paint()
        textPaint.isAntiAlias = true
        textPaint.color = Color.WHITE
        textPaint.textSize = 76F
        textPaint.textAlign = Paint.Align.CENTER
        textPaint.typeface = Typeface.DEFAULT_BOLD

        val xPos = canvas.width / 2
        val yPos = (canvas.height / 2 - (textPaint.descent() + textPaint.ascent()) / 2).toInt()
        canvas.drawText(text, xPos.toFloat(), yPos.toFloat(), textPaint)

        return bitmap
    }

    private val randomColor: Int
        get() {
            Color()
            val colors =
                listOf(
                    Color.parseColor("#8E5AF7"),
                    Color.parseColor("#5D11F7"),
                    Color.parseColor("#2D7FC1"),
                    Color.parseColor("#EF5931"),
                    Color.parseColor("#F5B433"),
                    Color.parseColor("#579F2B"),
                    Color.parseColor("#1F036C"),
                    Color.parseColor("#CE0755"),
                )
            val randomInt = (colors.indices).random()
            return colors[randomInt]
        }
}