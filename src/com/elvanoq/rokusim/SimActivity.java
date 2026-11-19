package com.elvanoq.rokusim;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.graphics.Color;
import android.media.AudioManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.KeyEvent;
import android.view.View;
import android.view.WindowManager;
import android.webkit.ConsoleMessage;
import android.webkit.JavascriptInterface;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

/**
 * Roku simulada dentro do app (WebView). O motor precisa de SharedArrayBuffer;
 * se a WebView não liberar, a página avisa e o app abre o Chrome.
 */
public class SimActivity extends Activity {
    private WebView web;
    private final Handler ui = new Handler(Looper.getMainLooper());
    private boolean editing = false;

    @SuppressLint({"SetJavaScriptEnabled", "AddJavascriptInterface"})
    @Override
    protected void onCreate(Bundle b) {
        super.onCreate(b);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON | WindowManager.LayoutParams.FLAG_FULLSCREEN);
        setVolumeControlStream(AudioManager.STREAM_MUSIC);
        String url;
        try { url = LocalServer.get(this).baseUrl(); }
        catch (Exception e) {
            Sim.log("Sim", "servidor não abriu: " + e.getMessage());
            finish();
            return;
        }
        WebView.setWebContentsDebuggingEnabled(true);
        web = new WebView(this);
        web.setBackgroundColor(Color.BLACK);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setMediaPlaybackRequiresUserGesture(false);
        s.setUseWideViewPort(true);
        s.setLoadWithOverviewMode(true);
        s.setSupportZoom(false);
        s.setTextZoom(100);
        s.setCacheMode(WebSettings.LOAD_NO_CACHE);
        web.setFocusable(true);
        web.setFocusableInTouchMode(true);
        web.addJavascriptInterface(new Bridge(), "SimBridge");
        web.setWebViewClient(new WebViewClient());
        web.setWebChromeClient(new WebChromeClient() {
            @Override public boolean onConsoleMessage(ConsoleMessage m) {
                if (m.messageLevel() == ConsoleMessage.MessageLevel.ERROR) {
                    String src = m.sourceId() == null ? "" : m.sourceId();
                    Sim.log("console.error", m.message() + " @ " + src.substring(src.lastIndexOf('/') + 1) + ":" + m.lineNumber());
                }
                return true;
            }
        });
        setContentView(web);
        hideSystemUi();
        web.loadUrl(url + "?host=webview&t=" + System.currentTimeMillis());
    }

    private void hideSystemUi() {
        getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY | View.SYSTEM_UI_FLAG_FULLSCREEN
            | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            | View.SYSTEM_UI_FLAG_LAYOUT_STABLE);
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) hideSystemUi();
    }

    @Override
    protected void onDestroy() {
        if (web != null) { web.loadUrl("about:blank"); web.destroy(); }
        super.onDestroy();
    }

    /* ---------------- controle físico ---------------- */

    private static String mapKey(int k) {
        switch (k) {
            case KeyEvent.KEYCODE_DPAD_LEFT: return "left";
            case KeyEvent.KEYCODE_DPAD_UP: return "up";
            case KeyEvent.KEYCODE_DPAD_RIGHT: return "right";
            case KeyEvent.KEYCODE_DPAD_DOWN: return "down";
            case KeyEvent.KEYCODE_DPAD_CENTER: case KeyEvent.KEYCODE_ENTER: case KeyEvent.KEYCODE_NUMPAD_ENTER: case KeyEvent.KEYCODE_BUTTON_A: return "select";
            case KeyEvent.KEYCODE_BACK: case KeyEvent.KEYCODE_ESCAPE: case KeyEvent.KEYCODE_BUTTON_B: return "back";
            case KeyEvent.KEYCODE_HOME: case KeyEvent.KEYCODE_MOVE_HOME: return "home";
            case KeyEvent.KEYCODE_DEL: case KeyEvent.KEYCODE_BUTTON_X: return "instantreplay";
            case KeyEvent.KEYCODE_INFO: case KeyEvent.KEYCODE_MENU: case KeyEvent.KEYCODE_INSERT: case KeyEvent.KEYCODE_BUTTON_Y: return "info";
            case KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE: case KeyEvent.KEYCODE_MEDIA_PLAY: case KeyEvent.KEYCODE_MEDIA_PAUSE: return "play";
            case KeyEvent.KEYCODE_MEDIA_REWIND: case KeyEvent.KEYCODE_PAGE_UP: case KeyEvent.KEYCODE_BUTTON_L1: return "rev";
            case KeyEvent.KEYCODE_MEDIA_FAST_FORWARD: case KeyEvent.KEYCODE_PAGE_DOWN: case KeyEvent.KEYCODE_BUTTON_R1: return "fwd";
            default: return null;
        }
    }

    @Override
    public boolean dispatchKeyEvent(KeyEvent e) {
        int k = e.getKeyCode();
        if (k == KeyEvent.KEYCODE_VOLUME_UP || k == KeyEvent.KEYCODE_VOLUME_DOWN || k == KeyEvent.KEYCODE_VOLUME_MUTE) return super.dispatchKeyEvent(e);
        if (editing && k != KeyEvent.KEYCODE_BACK) return super.dispatchKeyEvent(e);
        String key = mapKey(k);
        if (key == null) return super.dispatchKeyEvent(e);
        if (e.getAction() == KeyEvent.ACTION_DOWN && e.getRepeatCount() == 0) js("window.__sim&&__sim.key('" + key + "',true)");
        else if (e.getAction() == KeyEvent.ACTION_UP) js("window.__sim&&__sim.key('" + key + "',false)");
        return true;
    }

    @Override
    public void onBackPressed() { js("window.__sim&&__sim.key('back',true);setTimeout(function(){__sim.key('back',false)},80)"); }

    private void js(final String code) {
        ui.post(new Runnable() { @Override public void run() { if (web != null) web.evaluateJavascript(code, null); } });
    }

    /* ---------------- ponte JS ---------------- */

    private class Bridge {
        @JavascriptInterface public void closeApp() {
            ui.post(new Runnable() { @Override public void run() { finish(); } });
        }
        @JavascriptInterface public void setEditing(boolean on) { editing = on; }
        @JavascriptInterface public void share() {
            ui.post(new Runnable() { @Override public void run() { MainActivity.shareLog(SimActivity.this); } });
        }
        /** A WebView não liberou SharedArrayBuffer: oferece abrir no Chrome. */
        @JavascriptInterface public void noIsolation() {
            ui.post(new Runnable() { @Override public void run() {
                Sim.log("Sim", "a WebView do Android não liberou SharedArrayBuffer (crossOriginIsolated=false); o motor precisa dele");
                new AlertDialog.Builder(SimActivity.this).setTitle("A WebView não roda o motor")
                    .setMessage("A WebView do Android não libera SharedArrayBuffer, que o motor da Roku simulada precisa para as tarefas (Task) e o controle. No Chrome funciona.\n\nAbrir no Chrome agora? (Dá para deixar o Chrome como padrão em \"Onde rodar\".)")
                    .setPositiveButton("Abrir no Chrome", new DialogInterface.OnClickListener() {
                        @Override public void onClick(DialogInterface d, int w) {
                            Sim.prefs(SimActivity.this).edit().putInt("browser", 0).apply();
                            MainActivity.openChrome(SimActivity.this);
                            finish();
                        }
                    })
                    .setNegativeButton("Voltar", new DialogInterface.OnClickListener() {
                        @Override public void onClick(DialogInterface d, int w) { finish(); }
                    })
                    .setCancelable(false).show();
            } });
        }
    }
}
