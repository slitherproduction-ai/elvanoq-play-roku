package com.elvanoq.rokusim;

import android.content.Context;
import android.content.SharedPreferences;

import org.json.JSONObject;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.TimeZone;
import java.util.UUID;

/** Presets de aparelhos Roku, preferências e log compartilhado. */
final class Sim {
    private Sim() {}

    static final String VERSION = "1.0.0";
    static final String REPO = "slitherproduction-ai/elvanoq-play-roku";
    static final String DEV_ID = "elvanoqrokusim0000000000000000000000001";

    /** rótulo, código do modelo, Roku OS (major.minor), resolução da interface */
    static final String[][] PRESETS = {
        {"Roku Express (2019) · HD", "3930X", "15.1", "720p"},
        {"Roku Express 4K", "3940X", "15.1", "1080p"},
        {"Roku Streaming Stick 4K", "3820X", "15.1", "1080p"},
        {"Roku Ultra (2024)", "4850X", "15.1", "1080p"},
        {"Roku TV 4K (TCL)", "C000X", "15.1", "1080p"},
        {"Roku TV HD", "D000X", "15.1", "720p"},
        {"Roku Ultra (2024) · OS 16", "4850X", "16.0", "1080p"},
        {"Roku Express antiga · OS 14.6 (abaixo do mínimo)", "3930X", "14.6", "720p"},
    };

    static final String[] SOURCE_LABELS = {
        "Baixar do GitHub (branch do repositório do Roku)",
        "ZIP importado (pacote de sideload)"
    };
    static final String[] PACK_LABELS = {
        "Igual ao ZIP do workflow: manifest, source, components, images, fonts, locale",
        "Repositório inteiro (menos tests, .github e .md)"
    };
    static final String[] BROWSER_LABELS = {
        "Chrome (recomendado: o motor precisa de SharedArrayBuffer)",
        "WebView do app (experimental; se não der, abre o Chrome)"
    };
    static final String[] LOCALE_LABELS = {"Português (pt_BR)", "Inglês (en_US)"};

    static SharedPreferences prefs(Context c) {
        SharedPreferences p = c.getSharedPreferences("sim", Context.MODE_PRIVATE);
        if (!p.contains("clientId")) newIds(p);
        return p;
    }

    static void newIds(SharedPreferences p) {
        p.edit().putString("clientId", UUID.randomUUID().toString())
            .putString("rida", UUID.randomUUID().toString())
            .putString("customerId", UUID.randomUUID().toString().replace("-", ""))
            .putLong("resetToken", System.currentTimeMillis())
            .apply();
    }

    static int preset(SharedPreferences p) {
        int i = p.getInt("preset", 1);
        return i < 0 || i >= PRESETS.length ? 1 : i;
    }

    static double os(String[] pr) { return Double.parseDouble(pr[2]); }

    /** Firmware no formato que o motor lê (3º caractere = versão maior). Ex.: 15.1 → 48G.14E04100A */
    static String firmware(String[] pr) {
        String[] v = pr[2].split("\\.");
        int major = Integer.parseInt(v[0]);
        String letters = "0123456789ACDEFGHJKLMNPRSTUVWXY";
        return "48" + letters.charAt(Math.min(major, letters.length() - 1)) + "." + v[1] + "4E04100A";
    }

    static String userAgent(String[] pr) {
        return "Roku/DVP-" + pr[2] + " (" + pr[2] + ".4.4100-48)";
    }

    /** Código que o app mostra na ativação (mesma regra do MainScene: ROKU-XXXXXXXX-XXXXXXXX). */
    static String deviceCode(String clientId) {
        StringBuilder n = new StringBuilder();
        for (char ch : clientId.toCharArray()) if (Character.isLetterOrDigit(ch)) n.append(Character.toUpperCase(ch));
        if (n.length() < 16) return "ROKU-?";
        return "ROKU-" + n.substring(0, 8) + "-" + n.substring(8, 16);
    }

    static String config(SharedPreferences p, int port) {
        String[] pr = PRESETS[preset(p)];
        JSONObject o = new JSONObject();
        try {
            JSONObject d = new JSONObject();
            d.put("developerId", DEV_ID);
            d.put("friendlyName", "Roku Sim (ELVANOQ)");
            d.put("deviceModel", pr[1]);
            d.put("firmwareVersion", firmware(pr));
            d.put("clientId", p.getString("clientId", ""));
            d.put("RIDA", p.getString("rida", ""));
            d.put("customerId", p.getString("customerId", ""));
            d.put("countryCode", "BR");
            d.put("timeZone", TimeZone.getDefault().getID());
            boolean en = p.getInt("locale", 0) == 1;
            d.put("locale", en ? "en_US" : "pt_BR");
            d.put("captionLanguage", en ? "en" : "pt");
            d.put("audioLanguage", en ? "en" : "pt");
            d.put("clockFormat", "24h");
            d.put("displayMode", pr[3]);
            d.put("maxFps", p.getBoolean("fps60", false) ? 60 : 30);
            d.put("uiTransitions", p.getBoolean("transitions", true));
            d.put("debugOnCrash", false);
            d.put("corsProxy", "http://127.0.0.1:" + port + "/p/");
            o.put("device", d);
            o.put("preset", pr[0]);
            o.put("os", pr[2]);
            o.put("belowMin", os(pr) < 15.1);
            o.put("deviceCode", deviceCode(p.getString("clientId", "")));
            o.put("deepLink", p.getString("deepLink", "").trim());
            o.put("deepLinkType", p.getString("deepLinkType", "").trim());
            o.put("showStats", p.getBoolean("stats", false));
            o.put("showRemote", p.getBoolean("showRemote", true));
            o.put("showLog", p.getBoolean("showLog", false));
            o.put("resetToken", p.getLong("resetToken", 0));
            o.put("simVersion", VERSION);
            JSONObject pkg = Pkg.current(p);
            o.put("pkgName", pkg == null ? "" : pkg.optString("label"));
            o.put("pkgStamp", pkg == null ? 0 : pkg.optLong("stamp"));
        } catch (Exception ignored) {}
        return o.toString();
    }

    /* ---------------- log ---------------- */
    private static final List<String> LOG = new ArrayList<>();
    private static final int MAX = 4000;
    private static long dropped = 0;
    static volatile long logVersion = 0;

    static void log(String tag, String msg) {
        String line = new SimpleDateFormat("HH:mm:ss", Locale.US).format(new Date()) + " [" + tag + "] " + msg;
        synchronized (LOG) {
            LOG.add(line);
            if (LOG.size() > MAX) { LOG.remove(0); dropped++; }
            logVersion++;
        }
        android.util.Log.i("RokuSim", line);
    }

    /** Linhas a partir do número sequencial `since` (para a página consultar o log). */
    static JSONObject logSince(long since) {
        JSONObject o = new JSONObject();
        try {
            synchronized (LOG) {
                long first = dropped;
                long total = dropped + LOG.size();
                long from = Math.max(since, first);
                org.json.JSONArray a = new org.json.JSONArray();
                for (long i = from; i < total; i++) a.put(LOG.get((int) (i - first)));
                o.put("next", total);
                o.put("lines", a);
            }
        } catch (Exception ignored) {}
        return o;
    }

    static String logAll(int maxChars) {
        StringBuilder sb = new StringBuilder();
        synchronized (LOG) { for (String s : LOG) sb.append(s).append('\n'); }
        String all = sb.toString();
        return all.length() > maxChars ? all.substring(all.length() - maxChars) : all;
    }

    static void clearLog() {
        synchronized (LOG) { dropped += LOG.size(); LOG.clear(); logVersion++; }
    }
}
