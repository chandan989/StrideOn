package com.strideon.app.utils

fun String.safeTrim(): String = this.trim()

fun Int.clamp(min: Int, max: Int): Int = when {
    this < min -> min
    this > max -> max
    else -> this
}
