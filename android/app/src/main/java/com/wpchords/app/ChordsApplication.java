package com.wpchords.app;

import androidx.multidex.MultiDex;
import android.content.Context;
import io.flutter.app.FlutterApplication;

/**
 * Custom application class that enables MultiDex support
 */
public class ChordsApplication extends FlutterApplication {
    @Override
    protected void attachBaseContext(Context base) {
        super.attachBaseContext(base);
        MultiDex.install(this);
    }
}
