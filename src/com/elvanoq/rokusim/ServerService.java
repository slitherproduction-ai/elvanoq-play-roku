package com.elvanoq.rokusim;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.content.pm.ServiceInfo;
import android.os.Build;
import android.os.IBinder;

/**
 * Mantém o servidor local vivo enquanto o simulador roda no Chrome
 * (com o Chrome na frente, o Android pode encerrar o app em segundo plano).
 */
public class ServerService extends Service {
    static final String STOP = "com.elvanoq.rokusim.STOP";

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && STOP.equals(intent.getAction())) {
            Sim.log("Sim", "servidor parado pela notificação");
            stopForeground(true);
            stopSelf();
            return START_NOT_STICKY;
        }
        try { LocalServer.get(this); } catch (Exception e) { Sim.log("Sim", "servidor não abriu: " + e.getMessage()); }
        NotificationManager nm = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
        Notification.Builder b;
        if (Build.VERSION.SDK_INT >= 26) {
            NotificationChannel ch = new NotificationChannel("server", "Servidor do simulador", NotificationManager.IMPORTANCE_LOW);
            nm.createNotificationChannel(ch);
            b = new Notification.Builder(this, "server");
        } else {
            b = new Notification.Builder(this);
        }
        int piFlags = Build.VERSION.SDK_INT >= 23 ? PendingIntent.FLAG_IMMUTABLE : 0;
        PendingIntent open = PendingIntent.getActivity(this, 1, new Intent(this, MainActivity.class), piFlags);
        PendingIntent stop = PendingIntent.getService(this, 2, new Intent(this, ServerService.class).setAction(STOP), piFlags);
        b.setSmallIcon(android.R.drawable.ic_media_play)
            .setContentTitle("ELVANOQ Roku Sim")
            .setContentText("Roku simulada rodando no Chrome")
            .setContentIntent(open)
            .setOngoing(true)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Parar", stop);
        Notification n = b.build();
        if (Build.VERSION.SDK_INT >= 34) startForeground(7, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE);
        else startForeground(7, n);
        return START_STICKY;
    }

    @Override
    public IBinder onBind(Intent intent) { return null; }
}
