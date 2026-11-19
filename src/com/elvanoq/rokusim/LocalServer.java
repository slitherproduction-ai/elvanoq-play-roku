package com.elvanoq.rokusim;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;

import org.json.JSONObject;

import java.io.BufferedOutputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.URL;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Servidor HTTP em 127.0.0.1:
 *  - entrega a página do simulador e o motor (com COOP/COEP, para o SharedArrayBuffer funcionar);
 *  - entrega o pacote do canal (/pkg/current.zip);
 *  - faz o papel de proxy (/p/&lt;url&gt;) para as requisições do canal: na Roku não existe CORS,
 *    então tudo que o canal pede sai daqui, com o User-Agent da Roku.
 */
final class LocalServer {
    static final int BASE_PORT = 6502;
    private static LocalServer instance;

    private final Context app;
    private ServerSocket server;
    private int port;
    private final ExecutorService pool = Executors.newCachedThreadPool();

    // contadores para não inundar o log com imagens e segmentos de vídeo
    private int quietCount = 0;
    private long quietBytes = 0;
    private long lastQuietFlush = 0;
    private final java.util.Set<String> seenPlaylists = new java.util.HashSet<>();

    private LocalServer(Context c) { app = c.getApplicationContext(); }

    static synchronized LocalServer get(Context c) throws IOException {
        if (instance == null) instance = new LocalServer(c);
        instance.ensureStarted();
        return instance;
    }

    static synchronized boolean running() { return instance != null && instance.server != null && !instance.server.isClosed(); }

    int port() { return port; }

    String baseUrl() { return "http://127.0.0.1:" + port + "/"; }

    private synchronized void ensureStarted() throws IOException {
        if (server != null && !server.isClosed()) return;
        IOException last = null;
        for (int pt = BASE_PORT; pt < BASE_PORT + 8; pt++) {
            try {
                ServerSocket s = new ServerSocket(pt, 64, InetAddress.getByName("127.0.0.1"));
                s.setReuseAddress(true);
                server = s;
                port = pt;
                break;
            } catch (IOException e) { last = e; }
        }
        if (server == null) throw last != null ? last : new IOException("sem porta livre");
        if (port != BASE_PORT) Sim.log("Sim", "porta " + BASE_PORT + " ocupada; usando " + port + " (o registro da Roku simulada fica separado nessa porta)");
        Sim.log("Sim", "servidor local em " + baseUrl());
        final ServerSocket s = server;
        Thread t = new Thread(new Runnable() {
            @Override public void run() {
                while (!s.isClosed()) {
                    try {
                        final Socket sock = s.accept();
                        pool.execute(new Runnable() { @Override public void run() { handle(sock); } });
                    } catch (IOException e) {
                        if (!s.isClosed()) Sim.log("Sim", "servidor: " + e.getMessage());
                    }
                }
            }
        }, "roku-sim-server");
        t.setDaemon(true);
        t.start();
    }

    synchronized void stop() {
        try { if (server != null) server.close(); } catch (IOException ignored) {}
        server = null;
    }

    /* ---------------- HTTP ---------------- */

    private static final class Req {
        String method, target;
        final Map<String, String> headers = new LinkedHashMap<>();
        byte[] body = new byte[0];
    }

    private static String readLine(InputStream in) throws IOException {
        ByteArrayOutputStream b = new ByteArrayOutputStream();
        int c;
        while ((c = in.read()) != -1) {
            if (c == '\n') break;
            if (c != '\r') b.write(c);
            if (b.size() > 65536) throw new IOException("linha grande demais");
        }
        if (c == -1 && b.size() == 0) return null;
        return new String(b.toByteArray(), "ISO-8859-1");
    }

    private Req parse(InputStream in) throws IOException {
        String first = readLine(in);
        if (first == null || first.length() == 0) return null;
        String[] parts = first.split(" ");
        if (parts.length < 2) return null;
        Req r = new Req();
        r.method = parts[0].toUpperCase(Locale.US);
        r.target = parts[1];
        String line;
        while ((line = readLine(in)) != null && line.length() > 0) {
            int c = line.indexOf(':');
            if (c > 0) r.headers.put(line.substring(0, c).trim().toLowerCase(Locale.US), line.substring(c + 1).trim());
        }
        String cl = r.headers.get("content-length");
        if (cl != null) {
            int len = Integer.parseInt(cl.trim());
            byte[] b = new byte[len];
            int off = 0;
            while (off < len) {
                int n = in.read(b, off, len - off);
                if (n < 0) break;
                off += n;
            }
            r.body = b;
        }
        return r;
    }

    private void handle(Socket sock) {
        try {
            sock.setSoTimeout(60000);
            InputStream in = sock.getInputStream();
            OutputStream out = new BufferedOutputStream(sock.getOutputStream(), 65536);
            Req r = parse(in);
            if (r == null) { sock.close(); return; }
            String path = r.target;
            if (path.startsWith("/p/")) proxy(r, path.substring(3), out, false);
            else if (path.startsWith("/s/")) proxy(r, path.substring(3), out, true);
            else if (path.startsWith("/sim/")) sim(r, path, out);
            else if (path.startsWith("/pkg/current.zip")) sendFile(out, Pkg.file(app), "application/zip");
            else asset(path, out);
            out.flush();
        } catch (Throwable t) {
            // conexão cortada pelo navegador (troca de canal, etc.): normal
        } finally {
            try { sock.close(); } catch (IOException ignored) {}
        }
    }

    private static void head(OutputStream out, int status, String reason, String type, long length, Map<String, String> extra, boolean local) throws IOException {
        StringBuilder sb = new StringBuilder();
        sb.append("HTTP/1.1 ").append(status).append(' ').append(reason).append("\r\n");
        if (type != null) sb.append("Content-Type: ").append(type).append("\r\n");
        if (length >= 0) sb.append("Content-Length: ").append(length).append("\r\n");
        sb.append("Connection: close\r\n");
        if (local) {
            sb.append("Cross-Origin-Opener-Policy: same-origin\r\n");
            sb.append("Cross-Origin-Embedder-Policy: require-corp\r\n");
            sb.append("Cross-Origin-Resource-Policy: same-origin\r\n");
            sb.append("Cache-Control: no-cache\r\n");
        } else {
            sb.append("Cross-Origin-Resource-Policy: cross-origin\r\n");
            sb.append("Access-Control-Allow-Origin: *\r\n");
            sb.append("Access-Control-Expose-Headers: *\r\n");
        }
        if (extra != null) for (Map.Entry<String, String> e : extra.entrySet()) sb.append(e.getKey()).append(": ").append(e.getValue()).append("\r\n");
        sb.append("\r\n");
        out.write(sb.toString().getBytes("UTF-8"));
    }

    private static void sendBytes(OutputStream out, int status, String type, byte[] body) throws IOException {
        head(out, status, status == 200 ? "OK" : "Error", type, body.length, null, true);
        out.write(body);
    }

    private static String mime(String path) {
        String p = path.toLowerCase(Locale.US);
        if (p.endsWith(".html")) return "text/html; charset=utf-8";
        if (p.endsWith(".js")) return "application/javascript; charset=utf-8";
        if (p.endsWith(".css")) return "text/css; charset=utf-8";
        if (p.endsWith(".json")) return "application/json; charset=utf-8";
        if (p.endsWith(".zip")) return "application/zip";
        if (p.endsWith(".png")) return "image/png";
        if (p.endsWith(".jpg") || p.endsWith(".jpeg")) return "image/jpeg";
        if (p.endsWith(".svg")) return "image/svg+xml";
        if (p.endsWith(".wasm")) return "application/wasm";
        if (p.endsWith(".ttf")) return "font/ttf";
        if (p.endsWith(".txt")) return "text/plain; charset=utf-8";
        return "application/octet-stream";
    }

    private void asset(String path, OutputStream out) throws IOException {
        int q = path.indexOf('?');
        if (q >= 0) path = path.substring(0, q);
        if (path.equals("/") || path.length() == 0) path = "/index.html";
        if (path.contains("..")) { sendBytes(out, 404, "text/plain", "não encontrado".getBytes("UTF-8")); return; }
        InputStream in;
        try { in = app.getAssets().open("web" + path); }
        catch (IOException e) {
            if (!path.endsWith("favicon.ico")) Sim.log("Sim", "arquivo do simulador não encontrado: " + path);
            sendBytes(out, 404, "text/plain", "não encontrado".getBytes("UTF-8"));
            return;
        }
        byte[] data = readAll(in);
        head(out, 200, "OK", mime(path), data.length, null, true);
        out.write(data);
    }

    private static void sendFile(OutputStream out, File f, String type) throws IOException {
        if (!f.exists()) { sendBytes(out, 404, "text/plain", "sem pacote".getBytes("UTF-8")); return; }
        head(out, 200, "OK", type, f.length(), null, true);
        FileInputStream in = new FileInputStream(f);
        byte[] buf = new byte[65536];
        int n;
        while ((n = in.read(buf)) > 0) out.write(buf, 0, n);
        in.close();
    }

    static byte[] readAll(InputStream in) throws IOException {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        byte[] buf = new byte[65536];
        int n;
        while ((n = in.read(buf)) > 0) out.write(buf, 0, n);
        in.close();
        return out.toByteArray();
    }

    /* ---------------- rotas do simulador ---------------- */

    private void sim(Req r, String path, OutputStream out) throws IOException {
        SharedPreferences p = Sim.prefs(app);
        if (path.startsWith("/sim/config")) {
            sendBytes(out, 200, "application/json; charset=utf-8", Sim.config(p, port).getBytes("UTF-8"));
        } else if (path.startsWith("/sim/log") && "POST".equals(r.method)) {
            String body = new String(r.body, "UTF-8");
            for (String line : body.split("\n")) {
                int tab = line.indexOf('\t');
                if (tab > 0) Sim.log(line.substring(0, tab), line.substring(tab + 1));
                else if (line.length() > 0) Sim.log("Página", line);
            }
            sendBytes(out, 200, "text/plain", new byte[0]);
        } else if (path.startsWith("/sim/log")) {
            long since = 0;
            Matcher m = Pattern.compile("since=(\\d+)").matcher(path);
            if (m.find()) since = Long.parseLong(m.group(1));
            sendBytes(out, 200, "application/json; charset=utf-8", Sim.logSince(since).toString().getBytes("UTF-8"));
        } else if (path.startsWith("/sim/share")) {
            Intent i = new Intent(Intent.ACTION_SEND);
            i.setType("text/plain");
            i.putExtra(Intent.EXTRA_SUBJECT, "ELVANOQ Roku Sim – log");
            i.putExtra(Intent.EXTRA_TEXT, Sim.logAll(150000));
            Intent ch = Intent.createChooser(i, "Compartilhar log");
            ch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            try { app.startActivity(ch); } catch (Exception ignored) {}
            sendBytes(out, 200, "text/plain", new byte[0]);
        } else if (path.startsWith("/sim/settings")) {
            Intent i = new Intent(app, MainActivity.class);
            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
            try { app.startActivity(i); } catch (Exception ignored) {}
            sendBytes(out, 200, "text/plain", new byte[0]);
        } else {
            sendBytes(out, 404, "text/plain", new byte[0]);
        }
    }

    /* ---------------- proxy ---------------- */

    private static final Pattern URI_ATTR = Pattern.compile("URI=\"([^\"]+)\"");

    private String proxyPrefix() { return "http://127.0.0.1:" + port + "/p/"; }

    /** Esconde senhas no log: ?password=…, /live/usuario/senha/… */
    static String mask(String url) {
        String s = url.replaceAll("(?i)([?&](password|pass|pwd|senha|token|device_key|key)=)[^&]*", "$1***");
        s = s.replaceAll("(?i)(/(live|movie|series|timeshift)/[^/]+/)[^/]+/", "$1***/");
        return s;
    }

    private static boolean isQuiet(String url) {
        String u = url.toLowerCase(Locale.US);
        int q = u.indexOf('?');
        if (q >= 0) u = u.substring(0, q);
        return u.endsWith(".jpg") || u.endsWith(".jpeg") || u.endsWith(".png") || u.endsWith(".webp") || u.endsWith(".gif")
            || u.contains("image.tmdb.org") || u.contains("media.themoviedb.org");
    }

    private synchronized void quiet(long bytes) {
        quietCount++;
        quietBytes += bytes;
        long now = System.currentTimeMillis();
        if (now - lastQuietFlush > 15000) {
            Sim.log("Rede", "+" + quietCount + " imagens/segmentos (" + String.format(Locale.US, "%.1f", quietBytes / 1048576.0) + " MB) nos últimos " + ((now - lastQuietFlush) / 1000 > 999 ? "?" : String.valueOf((now - lastQuietFlush) / 1000)) + " s");
            quietCount = 0;
            quietBytes = 0;
            lastQuietFlush = now;
        }
    }

    /** @param segment true quando o endereço veio de uma playlist HLS (segmento): não vai para o log um por um. */
    private void proxy(Req r, String target, OutputStream out, boolean segment) throws IOException {
        if (target.startsWith("http:/") && !target.startsWith("http://")) target = "http://" + target.substring(6);
        if (target.startsWith("https:/") && !target.startsWith("https://")) target = "https://" + target.substring(7);
        if ("OPTIONS".equals(r.method)) {
            Map<String, String> h = new LinkedHashMap<>();
            h.put("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, HEAD, OPTIONS");
            h.put("Access-Control-Allow-Headers", r.headers.containsKey("access-control-request-headers") ? r.headers.get("access-control-request-headers") : "*");
            head(out, 204, "No Content", null, 0, h, false);
            return;
        }
        String[] pr = Sim.PRESETS[Sim.preset(Sim.prefs(app))];
        long t0 = System.currentTimeMillis();
        String url = target;
        HttpURLConnection c = null;
        int st = 0;
        boolean quiet = segment || isQuiet(url);
        try {
            for (int hop = 0; hop < 6; hop++) {
                c = (HttpURLConnection) new URL(url).openConnection();
                c.setInstanceFollowRedirects(false);
                c.setConnectTimeout(15000);
                c.setReadTimeout(30000);
                c.setRequestMethod(r.method);
                for (Map.Entry<String, String> e : r.headers.entrySet()) {
                    String k = e.getKey();
                    if (k.equals("host") || k.equals("origin") || k.equals("referer") || k.equals("connection") || k.equals("cookie")
                        || k.startsWith("sec-") || k.equals("accept-encoding") || k.equals("content-length") || k.equals("user-agent")
                        || k.equals("accept-language") || k.equals("pragma") || k.equals("cache-control")) continue;
                    c.setRequestProperty(k, e.getValue());
                }
                c.setRequestProperty("User-Agent", Sim.userAgent(pr));
                c.setRequestProperty("Accept-Encoding", "identity");
                if (r.body.length > 0 && hop == 0 && !"GET".equals(r.method) && !"HEAD".equals(r.method)) {
                    c.setDoOutput(true);
                    c.setFixedLengthStreamingMode(r.body.length);
                    OutputStream os = c.getOutputStream();
                    os.write(r.body);
                    os.close();
                }
                st = c.getResponseCode();
                if (st >= 300 && st < 400 && st != 304 && c.getHeaderField("Location") != null) {
                    String loc = new URL(new URL(url), c.getHeaderField("Location")).toString();
                    if (!quiet) Sim.log("Rede", st + " → " + mask(loc));
                    c.disconnect();
                    url = loc;
                    if (st == 303) { r.method = "GET"; r.body = new byte[0]; }
                    continue;
                }
                break;
            }
            String ctype = c.getContentType();
            InputStream in = st >= 400 ? c.getErrorStream() : c.getInputStream();
            Map<String, String> h = new LinkedHashMap<>();
            for (Map.Entry<String, List<String>> e : c.getHeaderFields().entrySet()) {
                String k = e.getKey();
                if (k == null || e.getValue().isEmpty()) continue;
                String kl = k.toLowerCase(Locale.US);
                if (kl.equals("content-length") || kl.equals("content-type") || kl.equals("connection") || kl.equals("transfer-encoding")
                    || kl.equals("content-encoding") || kl.startsWith("access-control-") || kl.equals("set-cookie")
                    || kl.startsWith("cross-origin-") || kl.equals("keep-alive") || kl.equals("strict-transport-security")) continue;
                h.put(k, e.getValue().get(0));
            }
            String low = url.toLowerCase(Locale.US);
            boolean playlist = (ctype != null && ctype.toLowerCase(Locale.US).contains("mpegurl")) || low.contains(".m3u8");
            if (playlist && in != null) {
                byte[] raw = readAll(in);
                String text = new String(raw, "UTF-8");
                byte[] body = text.startsWith("#EXTM3U") ? rewritePlaylist(text, url).getBytes("UTF-8") : raw;
                head(out, st, c.getResponseMessage() == null ? "OK" : c.getResponseMessage(), ctype == null ? "application/vnd.apple.mpegurl" : ctype, body.length, h, false);
                if (!"HEAD".equals(r.method)) out.write(body);
                // playlists ao vivo são recarregadas a cada poucos segundos: só a primeira vai para o log
                boolean first;
                synchronized (seenPlaylists) { first = seenPlaylists.add(url); if (seenPlaylists.size() > 500) seenPlaylists.clear(); }
                if (first || st >= 400) logReq(r.method, url, st, System.currentTimeMillis() - t0, body.length, ctype, false);
                return;
            }
            long len = c.getContentLength();
            head(out, st, c.getResponseMessage() == null ? "OK" : c.getResponseMessage(), ctype, len, h, false);
            if (!quiet || st >= 400) logReq(r.method, url, st, System.currentTimeMillis() - t0, len, ctype, false);
            long total = 0;
            if (in != null && !"HEAD".equals(r.method)) {
                byte[] buf = new byte[65536];
                int n;
                while ((n = in.read(buf)) > 0) {
                    out.write(buf, 0, n);
                    total += n;
                }
                in.close();
            }
            if (quiet && st < 400) quiet(total);
        } catch (javax.net.ssl.SSLException e) {
            Sim.log("Rede", "ERRO SSL " + mask(url) + ": " + e.getMessage() + " (a Roku também recusaria um certificado inválido)");
            safeError(out, 502);
        } catch (java.net.SocketTimeoutException e) {
            Sim.log("Rede", "TEMPO ESGOTADO " + r.method + " " + mask(url) + " (" + (System.currentTimeMillis() - t0) + " ms)");
            safeError(out, 504);
        } catch (java.net.UnknownHostException e) {
            Sim.log("Rede", "DNS não achou " + e.getMessage() + " (" + mask(url) + ")");
            safeError(out, 502);
        } catch (IOException e) {
            if (st == 0) {
                Sim.log("Rede", "FALHA " + r.method + " " + mask(url) + ": " + e.getMessage());
                safeError(out, 502);
            }
        } finally {
            if (c != null) c.disconnect();
        }
    }

    private void safeError(OutputStream out, int code) {
        try { head(out, code, "Proxy Error", "text/plain", 0, null, false); } catch (IOException ignored) {}
    }

    private void logReq(String method, String url, int st, long ms, long bytes, String ctype, boolean quiet) {
        if (quiet && st < 400) { quiet(bytes); return; }
        String size = bytes < 0 ? "tamanho aberto (stream)" : bytes > 1048576 ? String.format(Locale.US, "%.1f MB", bytes / 1048576.0)
            : bytes > 1024 ? String.format(Locale.US, "%.1f KB", bytes / 1024.0) : bytes + " B";
        Sim.log("Rede", method + " " + mask(url) + " → " + st + " · " + ms + " ms · " + size
            + (ctype != null && ctype.length() > 0 ? " · " + ctype.split(";")[0] : ""));
    }

    /** Reescreve os endereços da playlist HLS para também passarem pelo proxy. */
    private String rewritePlaylist(String text, String base) {
        StringBuilder sb = new StringBuilder();
        for (String line : text.split("\r?\n")) {
            String t = line.trim();
            if (t.length() == 0) { sb.append('\n'); continue; }
            if (t.startsWith("#")) {
                Matcher m = URI_ATTR.matcher(line);
                StringBuffer b = new StringBuffer();
                while (m.find()) m.appendReplacement(b, Matcher.quoteReplacement("URI=\"" + proxied(m.group(1), base) + "\""));
                m.appendTail(b);
                sb.append(b).append('\n');
            } else {
                sb.append(proxied(t, base)).append('\n');
            }
        }
        return sb.toString();
    }

    private String proxied(String ref, String base) {
        try {
            if (ref.startsWith("data:") || ref.startsWith("skd:")) return ref;
            String abs = new URL(new URL(base), ref).toString();
            // sub-playlists continuam em /p/ (são reescritas de novo); segmentos vão por /s/ (log resumido)
            return (abs.toLowerCase(Locale.US).contains(".m3u8") ? proxyPrefix() : "http://127.0.0.1:" + port + "/s/") + abs;
        } catch (Exception e) { return ref; }
    }
}
