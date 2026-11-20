package com.elvanoq.rokusim;

import android.content.Context;
import android.content.SharedPreferences;
import android.net.Uri;

import org.json.JSONArray;
import org.json.JSONObject;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;
import java.util.zip.ZipOutputStream;

import javax.xml.parsers.DocumentBuilderFactory;

/**
 * Pacote do canal Roku: baixa uma branch do GitHub ou importa um ZIP de sideload,
 * monta o ZIP que a Roku receberia e confere o que a Roku recusaria ou não acharia.
 */
final class Pkg {
    private Pkg() {}

    private static final String[] WORKFLOW_DIRS = {"source/", "components/", "images/", "fonts/", "locale/"};

    static File file(Context c) { return new File(new File(c.getFilesDir(), "pkg"), "current.zip"); }

    static JSONObject current(SharedPreferences p) {
        String s = p.getString("pkg", null);
        if (s == null) return null;
        try { return new JSONObject(s); } catch (Exception e) { return null; }
    }

    /* ---------------- GitHub ---------------- */

    static String httpText(String url, int timeoutMs) throws Exception {
        return new String(httpBytes(url, timeoutMs, null), "UTF-8");
    }

    static byte[] httpBytes(String url, int timeoutMs, Progress prog) throws Exception {
        HttpURLConnection c = (HttpURLConnection) new URL(url).openConnection();
        c.setConnectTimeout(15000);
        c.setReadTimeout(timeoutMs);
        c.setRequestProperty("User-Agent", "ELVANOQ-Roku-Sim/" + Sim.VERSION);
        c.setRequestProperty("Accept", "application/vnd.github+json, */*");
        int st = c.getResponseCode();
        InputStream in = st >= 400 ? c.getErrorStream() : c.getInputStream();
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        if (in != null) {
            byte[] buf = new byte[32768];
            int n;
            long total = 0;
            while ((n = in.read(buf)) > 0) {
                out.write(buf, 0, n);
                total += n;
                if (prog != null) prog.on(total);
            }
            in.close();
        }
        c.disconnect();
        if (st >= 400) {
            String body = new String(out.toByteArray(), "UTF-8");
            if (st == 403 && body.contains("rate limit")) throw new Exception("O GitHub limitou as consultas sem login (60 por hora). Tente de novo mais tarde.");
            if (st == 404) throw new Exception("Não encontrado no GitHub (" + url + ")");
            throw new Exception("GitHub respondeu " + st);
        }
        return out.toByteArray();
    }

    interface Progress { void on(long bytes); }

    static List<String> branches() throws Exception {
        JSONArray a = new JSONArray(httpText("https://api.github.com/repos/" + Sim.REPO + "/branches?per_page=100", 20000));
        List<String> out = new ArrayList<>();
        for (int i = 0; i < a.length(); i++) out.add(a.getJSONObject(i).getString("name"));
        if (out.remove("main")) out.add(0, "main");
        out.remove("roku-sim");
        out.remove("roku-sim-apk");
        return out;
    }

    /** Baixa a branch, monta o pacote e grava como pacote atual. */
    static JSONObject fromGitHub(Context ctx, String branch, int packMode, Progress prog) throws Exception {
        String sha = "", msg = "", date = "";
        try {
            JSONObject c = new JSONObject(httpText("https://api.github.com/repos/" + Sim.REPO + "/commits/" + Uri.encode(branch), 20000));
            sha = c.optString("sha");
            JSONObject cm = c.optJSONObject("commit");
            if (cm != null) {
                msg = cm.optString("message").split("\n")[0];
                JSONObject au = cm.optJSONObject("committer");
                if (au != null) date = au.optString("date");
            }
        } catch (Exception e) {
            Sim.log("Pacote", "não deu para ler o último commit: " + e.getMessage());
        }
        String ref = sha.length() > 0 ? sha : "refs/heads/" + branch;
        byte[] zip = httpBytes("https://codeload.github.com/" + Sim.REPO + "/zip/" + ref, 120000, prog);
        Map<String, byte[]> files = readZip(zip);
        Map<String, byte[]> app = pick(files, packMode);
        JSONObject info = build(ctx, app);
        info.put("source", "github");
        info.put("branch", branch);
        info.put("sha", sha);
        info.put("commitMsg", msg);
        info.put("commitDate", date);
        info.put("packMode", packMode);
        info.put("label", branch + (sha.length() >= 7 ? " @ " + sha.substring(0, 7) : ""));
        return info;
    }

    /** Importa um ZIP (sideload, artefato do workflow ou zip do repositório). */
    static JSONObject fromUri(Context ctx, Uri u, String name, int packMode) throws Exception {
        InputStream in = ctx.getContentResolver().openInputStream(u);
        if (in == null) throw new Exception("Não deu para abrir o arquivo.");
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        byte[] buf = new byte[32768];
        int n;
        while ((n = in.read(buf)) > 0) out.write(buf, 0, n);
        in.close();
        Map<String, byte[]> files = readZip(out.toByteArray());
        // artefato do GitHub Actions: um zip com o zip do canal dentro
        if (findManifestPrefix(files) == null) {
            for (Map.Entry<String, byte[]> e : files.entrySet()) {
                if (e.getKey().toLowerCase(Locale.US).endsWith(".zip")) {
                    Map<String, byte[]> inner = readZip(e.getValue());
                    if (findManifestPrefix(inner) != null) { files = inner; break; }
                }
            }
        }
        String prefix = findManifestPrefix(files);
        if (prefix == null) throw new Exception("O ZIP não tem o arquivo manifest. Um pacote Roku precisa do manifest na raiz.");
        // sideload: usa o conteúdo como veio (é isso que a Roku recebe); zip do repositório: aplica o modo escolhido
        boolean repoZip = files.containsKey(prefix + "tests/roku_preflight_simulator.py") || files.containsKey(prefix + "README.md");
        Map<String, byte[]> app = repoZip ? pick(files, packMode) : strip(files, prefix);
        JSONObject info = build(ctx, app);
        info.put("source", "zip");
        info.put("fileName", name == null ? "pacote.zip" : name);
        info.put("label", (name == null ? "pacote.zip" : name) + (repoZip ? " (repositório)" : ""));
        return info;
    }

    static Map<String, byte[]> readZip(byte[] data) throws Exception {
        Map<String, byte[]> out = new LinkedHashMap<>();
        ZipInputStream z = new ZipInputStream(new ByteArrayInputStream(data));
        ZipEntry e;
        byte[] buf = new byte[32768];
        while ((e = z.getNextEntry()) != null) {
            if (e.isDirectory()) continue;
            String name = e.getName().replace('\\', '/');
            if (name.contains("../")) continue;
            ByteArrayOutputStream b = new ByteArrayOutputStream();
            int n;
            while ((n = z.read(buf)) > 0) b.write(buf, 0, n);
            out.put(name, b.toByteArray());
        }
        z.close();
        if (out.isEmpty()) throw new Exception("ZIP vazio ou inválido.");
        return out;
    }

    private static String findManifestPrefix(Map<String, byte[]> files) {
        String best = null;
        for (String k : files.keySet()) {
            if (k.equals("manifest") || k.endsWith("/manifest")) {
                String pre = k.substring(0, k.length() - "manifest".length());
                if (best == null || pre.length() < best.length()) best = pre;
            }
        }
        return best;
    }

    private static Map<String, byte[]> strip(Map<String, byte[]> files, String prefix) {
        Map<String, byte[]> out = new LinkedHashMap<>();
        for (Map.Entry<String, byte[]> e : files.entrySet()) {
            if (!e.getKey().startsWith(prefix)) continue;
            String rel = e.getKey().substring(prefix.length());
            if (rel.length() == 0 || rel.startsWith("__MACOSX/") || rel.endsWith(".DS_Store")) continue;
            out.put(rel, e.getValue());
        }
        return out;
    }

    /** Escolhe os arquivos do repositório como o workflow faz (ou tudo menos testes e docs). */
    private static Map<String, byte[]> pick(Map<String, byte[]> files, int packMode) throws Exception {
        String prefix = findManifestPrefix(files);
        if (prefix == null) throw new Exception("A branch não tem o arquivo manifest na raiz.");
        Map<String, byte[]> all = strip(files, prefix);
        Map<String, byte[]> out = new LinkedHashMap<>();
        for (Map.Entry<String, byte[]> e : all.entrySet()) {
            String k = e.getKey();
            boolean keep;
            if (packMode == 0) {
                keep = k.equals("manifest");
                for (String d : WORKFLOW_DIRS) if (k.startsWith(d)) keep = true;
            } else {
                keep = !k.startsWith("tests/") && !k.startsWith(".github/") && !k.startsWith("out/")
                    && !k.toLowerCase(Locale.US).endsWith(".md") && !k.startsWith(".");
            }
            if (keep) out.put(k, e.getValue());
        }
        return out;
    }

    /** Grava o ZIP do canal e devolve o resumo com os avisos. */
    private static JSONObject build(Context ctx, Map<String, byte[]> app) throws Exception {
        File f = file(ctx);
        f.getParentFile().mkdirs();
        ZipOutputStream z = new ZipOutputStream(new FileOutputStream(f));
        long size = 0;
        for (Map.Entry<String, byte[]> e : app.entrySet()) {
            z.putNextEntry(new ZipEntry(e.getKey()));
            z.write(e.getValue());
            z.closeEntry();
            size += e.getValue().length;
        }
        z.close();
        JSONObject info = check(app);
        info.put("files", app.size());
        info.put("bytes", size);
        info.put("zipBytes", f.length());
        info.put("stamp", System.currentTimeMillis());
        return info;
    }

    /* ---------------- conferência do pacote ---------------- */

    static Map<String, String> manifest(byte[] data) {
        Map<String, String> m = new HashMap<>();
        if (data == null) return m;
        String s;
        try { s = new String(data, "UTF-8"); } catch (Exception e) { return m; }
        for (String line : s.split("\r?\n")) {
            line = line.trim();
            if (line.length() == 0 || line.startsWith("#")) continue;
            int eq = line.indexOf('=');
            if (eq > 0) m.put(line.substring(0, eq).trim(), line.substring(eq + 1).trim());
        }
        return m;
    }

    private static final Pattern PKG_REF = Pattern.compile("\"(pkg:/[^\"\\s]+?\\.[A-Za-z0-9]{2,5})\"");

    static JSONObject check(Map<String, byte[]> app) throws Exception {
        JSONObject info = new JSONObject();
        JSONArray warn = new JSONArray();
        Set<String> lower = new HashSet<>();
        for (String k : app.keySet()) lower.add(k.toLowerCase(Locale.US));

        Map<String, String> mf = manifest(app.get("manifest"));
        info.put("title", mf.containsKey("title") ? mf.get("title") : "?");
        String mm = mf.get("major_version") + "." + mf.get("minor_version") + "." + mf.get("build_version");
        info.put("version", mm);
        info.put("versionName", mf.containsKey("version_name") ? mf.get("version_name") : "");
        info.put("rsgVersion", mf.containsKey("rsg_version") ? mf.get("rsg_version") : "");
        info.put("uiResolutions", mf.containsKey("ui_resolutions") ? mf.get("ui_resolutions") : "");
        if (!mf.containsKey("title")) warn.put("manifest sem title");
        if (!mf.containsKey("major_version") || !mf.containsKey("minor_version") || !mf.containsKey("build_version"))
            warn.put("manifest sem major_version/minor_version/build_version");
        if (mf.containsKey("version_name") && !mf.get("version_name").equals(mm))
            warn.put("version_name (" + mf.get("version_name") + ") diferente de major.minor.build (" + mm + "); a loja mostra " + mm);
        if ("1.3".equals(mf.get("rsg_version"))) info.put("minOs", "15.1");
        for (String key : new String[]{"mm_icon_focus_fhd", "mm_icon_focus_hd", "mm_icon_focus_sd", "splash_screen_fhd", "splash_screen_hd", "splash_screen_sd"}) {
            String v = mf.get(key);
            if (v == null) { if (key.startsWith("mm_icon_focus_hd")) warn.put("manifest sem " + key + " (obrigatório na loja)"); continue; }
            String rel = v.replaceFirst("^pkg:/", "");
            if (!app.containsKey(rel)) warn.put("manifest " + key + " aponta para " + v + ", que não está no pacote");
        }

        // código de entrada
        boolean hasMain = false;
        for (Map.Entry<String, byte[]> e : app.entrySet()) {
            if (e.getKey().startsWith("source/") && e.getKey().endsWith(".brs")) {
                String s = new String(e.getValue(), "UTF-8").toLowerCase(Locale.US);
                if (s.matches("(?s).*\\b(sub|function)\\s+(main|runuserinterface)\\s*\\(.*")) hasMain = true;
            }
        }
        if (!hasMain) warn.put("nenhum Main() ou RunUserInterface() em source/");

        // componentes
        DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
        int comps = 0;
        Set<String> names = new TreeSet<>();
        for (Map.Entry<String, byte[]> e : app.entrySet()) {
            String k = e.getKey();
            if (!k.startsWith("components/") || !k.endsWith(".xml")) continue;
            try {
                Document d = dbf.newDocumentBuilder().parse(new ByteArrayInputStream(e.getValue()));
                Element root = d.getDocumentElement();
                if (!"component".equals(root.getTagName())) continue;
                comps++;
                String nm = root.getAttribute("name");
                if (!names.add(nm.toLowerCase(Locale.US))) warn.put("componente " + nm + " declarado duas vezes (" + k + ")");
                NodeList scripts = root.getElementsByTagName("script");
                for (int i = 0; i < scripts.getLength(); i++) {
                    String uri = ((Element) scripts.item(i)).getAttribute("uri");
                    if (uri.length() == 0) continue;
                    String rel = uri.startsWith("pkg:/") ? uri.substring(5) : k.substring(0, k.lastIndexOf('/') + 1) + uri;
                    if (!app.containsKey(rel)) warn.put(k + ": script " + uri + " não está no pacote");
                }
            } catch (Exception ex) {
                warn.put(k + ": XML inválido (" + ex.getMessage() + ")");
            }
        }
        info.put("components", comps);

        // caminhos pkg:/ escritos no código
        Map<String, String> missing = new LinkedHashMap<>();
        for (Map.Entry<String, byte[]> e : app.entrySet()) {
            String k = e.getKey();
            if (!(k.endsWith(".brs") || k.endsWith(".xml"))) continue;
            Matcher m = PKG_REF.matcher(new String(e.getValue(), "UTF-8"));
            while (m.find()) {
                String ref = m.group(1);
                String rel = ref.substring(5);
                if (!app.containsKey(rel) && !missing.containsKey(ref)) {
                    missing.put(ref, k);
                    if (lower.contains(rel.toLowerCase(Locale.US))) missing.put(ref, k + " (existe com outra caixa de letras)");
                }
            }
        }
        for (Map.Entry<String, String> e : missing.entrySet()) warn.put(e.getKey() + " é usado em " + e.getValue() + ", mas não está no pacote");

        long big = 0;
        for (byte[] b : app.values()) big += b.length;
        if (big > 4L * 1024 * 1024) warn.put("pacote com " + (big / 1024 / 1024) + " MB descompactado; confira o limite de tamanho de canal da Roku");
        info.put("warnings", warn);
        return info;
    }

    static String summary(JSONObject w) {
        if (w == null) return "Nenhum pacote carregado.";
        StringBuilder sb = new StringBuilder();
        sb.append(w.optString("title")).append(" · versão ").append(w.optString("version"));
        if (w.optString("versionName").length() > 0) sb.append(" (version_name ").append(w.optString("versionName")).append(")");
        sb.append('\n');
        if ("github".equals(w.optString("source"))) {
            sb.append("Branch: ").append(w.optString("branch"));
            if (w.optString("sha").length() >= 7) sb.append(" @ ").append(w.optString("sha").substring(0, 7));
            sb.append('\n');
            if (w.optString("commitMsg").length() > 0) sb.append("Commit: ").append(w.optString("commitMsg")).append('\n');
            if (w.optString("commitDate").length() > 0) sb.append("Data: ").append(w.optString("commitDate").replace('T', ' ').replace("Z", " UTC")).append('\n');
            sb.append("Montagem: ").append(Sim.PACK_LABELS[w.optInt("packMode", 0)]).append('\n');
        } else {
            sb.append("Arquivo: ").append(w.optString("fileName")).append('\n');
        }
        sb.append("rsg_version ").append(w.optString("rsgVersion"));
        if (w.optString("minOs").length() > 0) sb.append(" (exige Roku OS ").append(w.optString("minOs")).append("+)");
        sb.append(" · ui_resolutions ").append(w.optString("uiResolutions")).append('\n');
        sb.append(w.optInt("files")).append(" arquivos · ").append(w.optInt("components")).append(" componentes · ")
            .append(String.format(Locale.US, "%.1f MB (zip %.1f MB)", w.optLong("bytes") / 1048576.0, w.optLong("zipBytes") / 1048576.0)).append('\n');
        JSONArray wn = w.optJSONArray("warnings");
        if (wn == null || wn.length() == 0) sb.append("\nNenhum aviso.");
        else {
            sb.append("\nAvisos (").append(wn.length()).append("):\n");
            for (int i = 0; i < wn.length(); i++) sb.append("⚠ ").append(wn.optString(i)).append('\n');
        }
        return sb.toString();
    }
}
