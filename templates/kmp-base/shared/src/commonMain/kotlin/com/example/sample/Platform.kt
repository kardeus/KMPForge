package com.example.sample

interface Platform {
    val name: String
}

expect fun getPlatform(): Platform