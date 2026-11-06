package com.aeh.fjelia

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Lives independently of the screen/activity. No sticky, unattended restart:
 * after process death the durable Dart checkpoint is recovered explicitly. */
class ActivityRecordingService : Service(), LocationListener {
    companion object {
        var engine: FlutterEngine? = null
        var channel: MethodChannel? = null
        private var pending: MethodChannel.Result? = null
        private var running = false
        private const val CHANNEL = "fjelia_activity_recording"
        private const val ID = 61921
        private const val PAUSE = "com.aeh.fjelia.RECORDING_PAUSE"
        private const val STOP = "com.aeh.fjelia.RECORDING_STOP"

        fun configure(context: Context, args: Map<*, *>, result: MethodChannel.Result) {
            if (args["active"] != true) {
                context.stopService(Intent(context, ActivityRecordingService::class.java))
                result.success(null)
                return
            }
            val intent = Intent(context, ActivityRecordingService::class.java)
                .putExtra("gps", args["gps"] == true)
                .putExtra("bluetooth", args["bluetooth"] == true)
                .putExtra("name", args["name"] as? String ?: "Fjelia")
                .putExtra("notification", args["notification"] as? String ?: "")
                .putExtra("pause", args["pause"] as? String ?: "Pause")
                .putExtra("stop", args["stop"] as? String ?: "Stop")
            pending = result
            try {
                if (Build.VERSION.SDK_INT >= 26 && !running) context.startForegroundService(intent)
                else context.startService(intent)
            } catch (_: Exception) {
                pending = null
                result.error("recording_service", "Could not start background recording. Start with Fjelia open.", null)
            }
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var wakeLock: PowerManager.WakeLock? = null
    private var gps = false
    private lateinit var locations: LocationManager
    private val renew = object : Runnable {
        override fun run() {
            // Renew a bounded, non-reference-counted lock only while recording.
            wakeLock?.acquire(10 * 60 * 1000L)
            handler.postDelayed(this, 5 * 60 * 1000L)
        }
    }

    override fun onCreate() {
        super.onCreate()
        locations = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        wakeLock = (getSystemService(Context.POWER_SERVICE) as PowerManager)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "fjelia:activity_recording")
            .apply { setReferenceCounted(false) }
        if (Build.VERSION.SDK_INT >= 26) {
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(NotificationChannel(CHANNEL, "Activity recording", NotificationManager.IMPORTANCE_LOW))
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == PAUSE || intent?.action == STOP) {
            channel?.invokeMethod("action", if (intent.action == PAUSE) "pause" else "stop")
            return START_NOT_STICKY
        }
        if (intent == null) { stopSelf(); return START_NOT_STICKY }
        val result = pending
        pending = null
        try {
            val wantsGPS = intent.getBooleanExtra("gps", false)
            var types = 0
            if (Build.VERSION.SDK_INT >= 34) types = ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH
            if (Build.VERSION.SDK_INT >= 29 && wantsGPS) types = types or ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
            if (Build.VERSION.SDK_INT >= 29 && intent.getBooleanExtra("bluetooth", false)) {
                types = types or ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE
            }
            val notification = notification(intent)
            if (Build.VERSION.SDK_INT >= 29) startForeground(ID, notification, types)
            else startForeground(ID, notification)
            running = true
            if (wantsGPS != gps) {
                locations.removeUpdates(this)
                gps = wantsGPS
                if (gps) startLocations()
            }
            handler.removeCallbacks(renew)
            renew.run()
            result?.success(null)
        } catch (_: Exception) {
            result?.error("recording_service", "Could not start background recording. Check location and Bluetooth permissions.", null)
            stopSelf()
        }
        return START_NOT_STICKY
    }

    private fun startLocations() {
        if (checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED &&
            checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            throw SecurityException("Location permission required")
        }
        var available = false
        for (provider in listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)) {
            if (locations.isProviderEnabled(provider)) {
                locations.requestLocationUpdates(provider, 1000L, 2f, this, Looper.getMainLooper())
                available = true
            }
        }
        if (!available) throw IllegalStateException("Enable location services")
    }

    private fun notification(intent: Intent): Notification {
        val open = PendingIntent.getActivity(this, 0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        fun action(action: String, request: Int) = PendingIntent.getService(this, request,
            Intent(this, ActivityRecordingService::class.java).setAction(action),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, CHANNEL) else Notification.Builder(this)
        return builder.setSmallIcon(android.R.drawable.ic_media_play)
            .setContentTitle("Fjelia · ${intent.getStringExtra("name") ?: "Fjelia"}")
            .setContentText(intent.getStringExtra("notification"))
            .setContentIntent(open).setOngoing(true).setOnlyAlertOnce(true)
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            .setCategory(Notification.CATEGORY_SERVICE)
            .addAction(Notification.Action.Builder(null, intent.getStringExtra("pause"), action(PAUSE, 1)).build())
            .addAction(Notification.Action.Builder(null, intent.getStringExtra("stop"), action(STOP, 2)).build())
            .build()
    }

    override fun onLocationChanged(location: Location) {
        if (!gps || !location.hasAccuracy()) return
        val fix = mutableMapOf<String, Any>("t" to location.time, "lat" to location.latitude,
            "lng" to location.longitude, "accuracy" to location.accuracy.toDouble())
        if (location.hasAltitude() && (Build.VERSION.SDK_INT < 26 ||
                location.hasVerticalAccuracy() && location.verticalAccuracyMeters <= 20)) fix["altitude"] = location.altitude
        if (location.hasSpeed()) fix["speed"] = location.speed.toDouble()
        channel?.invokeMethod("location", fix)
    }

    override fun onProviderDisabled(provider: String) {
        if (!locations.isProviderEnabled(LocationManager.GPS_PROVIDER) &&
            !locations.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
            channel?.invokeMethod("error", "location_unavailable")
        }
    }
    override fun onProviderEnabled(provider: String) {}
    @Deprecated("Legacy LocationListener callback")
    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
    override fun onBind(intent: Intent?): IBinder? = null
    override fun onDestroy() {
        gps = false
        running = false
        locations.removeUpdates(this)
        handler.removeCallbacks(renew)
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }
}
