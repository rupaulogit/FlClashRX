package com.follow.clashx;

import android.app.Application
import android.content.Context

class FlClashRApplication : Application() {
    companion object {
        private lateinit var instance: FlClashRApplication
        fun getAppContext(): Context {
            return instance.applicationContext
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
    }
}