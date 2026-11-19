package com.elvanoq.rokusim;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.OpenableColumns;
import android.text.InputType;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.CookieManager;
import android.webkit.WebStorage;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.List;
import java.util.Locale;

public class MainActivity extends Activity {
    static final int BG = 0xFF100A1A, CARD = 0xFF1E1730, PURPLE = 0xFF6C2BD9, TXT = 0xFFEDE8F7, SUB = 0xFFA79DBD, WARN = 0xFFFFC857;
    private static final int PICK_ZIP = 51;

    private SharedPreferences p;
    private LinearLayout col;
    private Button presetBtn, localeBtn, sourceBtn, branchBtn, packBtn, fetchBtn, importBtn, browserBtn, pkgInfoBtn;
    private TextView pkgLabel;
    private EditText deepLink, deepType;

    @Override
    protected void onCreate(Bundle b) {
        super.onCreate(b);
        p = Sim.prefs(this);
        buildUi();
        handleIncoming(getIntent());
    }

    @Override
    protected void onNewIntent(Intent i) {
        super.onNewIntent(i);
        setIntent(i);
        handleIncoming(i);
    }

    @Override
    protected void onResume() {
        super.onResume();
        refresh();
    }

    private void handleIncoming(Intent i) {
        if (i == null) return;
        Uri u = null;
        if (Intent.ACTION_VIEW.equals(i.getAction())) u = i.getData();
        else if (Intent.ACTION_SEND.equals(i.getAction())) u = i.getParcelableExtra(Intent.EXTRA_STREAM);
        if (u != null) { i.setAction(Intent.ACTION_MAIN); importZip(u); }
    }

    /* ---------------- pacote ---------------- */

    private void pickZip() {
        Intent i = new Intent(Intent.ACTION_OPEN_DOCUMENT);
        i.addCategory(Intent.CATEGORY_OPENABLE);
        i.setType("*/*");
        try { startActivityForResult(i, PICK_ZIP); }
        catch (Exception e) {
            Intent g = new Intent(Intent.ACTION_GET_CONTENT);
            g.addCategory(Intent.CATEGORY_OPENABLE);
            g.setType("*/*");
            try { startActivityForResult(Intent.createChooser(g, "Escolha o ZIP do canal"), PICK_ZIP); }
            catch (Exception e2) { toast("Nenhum seletor de arquivos disponível."); }
        }
    }

    @Override
    protected void onActivityResult(int req, int res, Intent data) {
        super.onActivityResult(req, res, data);
        if (req == PICK_ZIP && res == RESULT_OK && data != null && data.getData() != null) importZip(data.getData());
    }

    private String displayName(Uri u) {
        String name = u.getLastPathSegment();
        try {
            Cursor c = getContentResolver().query(u, new String[]{OpenableColumns.DISPLAY_NAME}, null, null, null);
            if (c != null) {
                if (c.moveToFirst() && !c.isNull(0)) name = c.getString(0);
                c.close();
            }
        } catch (Exception ignored) {}
        return name;
    }

    private interface Job { JSONObject run(ProgressDialog pd) throws Exception; }

    private void runJob(final String title, final Job job, final String logLabel) {
        final ProgressDialog pd = new ProgressDialog(this);
        pd.setMessage(title);
        pd.setCancelable(false);
        pd.show();
        new Thread(new Runnable() {
            @Override public void run() {
                String err = null;
                JSONObject info = null;
                try { info = job.run(pd); }
                catch (Throwable t) { err = t.getMessage() == null ? t.toString() : t.getMessage(); }
                final String fErr = err;
                final JSONObject fi = info;
                runOnUiThread(new Runnable() {
                    @Override public void run() {
                        try { pd.dismiss(); } catch (Exception ignored) {}
                        if (fErr != null) {
                            Sim.log("Pacote", "falha (" + logLabel + "): " + fErr);
                            new AlertDialog.Builder(MainActivity.this).setTitle("Não deu para carregar o canal")
                                .setMessage(fErr).setPositiveButton("OK", null).show();
                            return;
                        }
                        p.edit().putString("pkg", fi.toString()).apply();
                        Sim.log("Pacote", "carregado " + fi.optString("label") + " · v" + fi.optString("version")
                            + " · " + fi.optJSONArray("warnings").length() + " aviso(s)");
                        refresh();
                        new AlertDialog.Builder(MainActivity.this).setTitle("Canal pronto")
                            .setMessage(Pkg.summary(fi))
                            .setPositiveButton("Abrir na Roku simulada", new DialogInterface.OnClickListener() {
                                @Override public void onClick(DialogInterface d, int w) { launch(); }
                            })
                            .setNegativeButton("Depois", null).show();
                    }
                });
            }
        }).start();
    }

    private void importZip(final Uri u) {
        final String name = displayName(u);
        p.edit().putInt("source", 1).apply();
        runJob("Importando " + (name == null ? "pacote" : name) + "…", new Job() {
            @Override public JSONObject run(ProgressDialog pd) throws Exception {
                return Pkg.fromUri(MainActivity.this, u, name, p.getInt("pack", 0));
            }
        }, name);
    }

    private void fetchBranch() {
        save();
        final String branch = p.getString("branch", "main");
        p.edit().putInt("source", 0).apply();
        runJob("Baixando a branch " + branch + " do GitHub…", new Job() {
            @Override public JSONObject run(final ProgressDialog pd) throws Exception {
                return Pkg.fromGitHub(MainActivity.this, branch, p.getInt("pack", 0), new Pkg.Progress() {
                    long last = 0;
                    @Override public void on(final long bytes) {
                        if (bytes - last < 200000) return;
                        last = bytes;
                        runOnUiThread(new Runnable() { @Override public void run() {
                            pd.setMessage(String.format(Locale.US, "Baixando %s do GitHub… %.1f MB", branch, bytes / 1048576.0));
                        } });
                    }
                });
            }
        }, "branch " + branch);
    }

    private void pickBranch() {
        final ProgressDialog pd = ProgressDialog.show(this, null, "Lendo as branches do GitHub…", true, false);
        new Thread(new Runnable() {
            @Override public void run() {
                List<String> list = null;
                String err = null;
                try { list = Pkg.branches(); } catch (Exception e) { err = e.getMessage(); }
                final List<String> fl = list;
                final String fe = err;
                runOnUiThread(new Runnable() {
                    @Override public void run() {
                        try { pd.dismiss(); } catch (Exception ignored) {}
                        if (fe != null) { toast(fe); return; }
                        final String[] items = fl.toArray(new String[0]);
                        int sel = fl.indexOf(p.getString("branch", "main"));
                        new AlertDialog.Builder(MainActivity.this).setTitle("Branch do " + Sim.REPO.split("/")[1])
                            .setSingleChoiceItems(items, sel, new DialogInterface.OnClickListener() {
                                @Override public void onClick(DialogInterface d, int i) {
                                    p.edit().putString("branch", items[i]).apply();
                                    d.dismiss();
                                    refresh();
                                }
                            }).show();
                    }
                });
            }
        }).start();
    }

    /* ---------------- abrir ---------------- */

    private void launch() {
        save();
        JSONObject pkg = Pkg.current(p);
        if (pkg == null) {
            new AlertDialog.Builder(this).setTitle("Nenhum canal carregado")
                .setMessage("Baixe a branch do GitHub ou importe o ZIP do canal primeiro.")
                .setPositiveButton("Baixar " + p.getString("branch", "main"), new DialogInterface.OnClickListener() {
                    @Override public void onClick(DialogInterface d, int w) { fetchBranch(); }
                })
                .setNegativeButton("Importar ZIP", new DialogInterface.OnClickListener() {
                    @Override public void onClick(DialogInterface d, int w) { pickZip(); }
                }).show();
            return;
        }
        String[] pr = Sim.PRESETS[Sim.preset(p)];
        Sim.clearLog();
        Sim.log("Sim", "ELVANOQ Roku Sim " + Sim.VERSION + " · " + pr[0] + " (" + pr[1] + ") · Roku OS " + pr[2] + " · " + pr[3]);
        Sim.log("Sim", "canal: " + pkg.optString("label") + " · v" + pkg.optString("version"));
        JSONArray wn = pkg.optJSONArray("warnings");
        if (wn != null) for (int i = 0; i < wn.length(); i++) Sim.log("Pacote", "⚠ " + wn.optString(i));
        if (pkg.optString("minOs").length() > 0 && Sim.os(pr) < Double.parseDouble(pkg.optString("minOs")))
            Sim.log("Pacote", "⚠ o canal exige Roku OS " + pkg.optString("minOs") + "+; nesta Roku (OS " + pr[2] + ") a loja não instalaria. O simulador abre mesmo assim.");
        if (p.getInt("browser", 0) == 1) {
            startActivity(new Intent(this, SimActivity.class));
        } else {
            openChrome(this);
        }
    }

    /** Abre a Roku simulada no Chrome (Custom Tab), com o servidor num serviço em primeiro plano. */
    static void openChrome(Activity a) {
        if (Build.VERSION.SDK_INT >= 33 && a.checkSelfPermission("android.permission.POST_NOTIFICATIONS") != PackageManager.PERMISSION_GRANTED) {
            a.requestPermissions(new String[]{"android.permission.POST_NOTIFICATIONS"}, 9);
        }
        Intent svc = new Intent(a, ServerService.class);
        if (Build.VERSION.SDK_INT >= 26) a.startForegroundService(svc); else a.startService(svc);
        int port = LocalServer.BASE_PORT;
        try { port = LocalServer.get(a).port(); } catch (Exception e) { Sim.log("Sim", "servidor: " + e.getMessage()); }
        Uri uri = Uri.parse("http://127.0.0.1:" + port + "/?t=" + System.currentTimeMillis());
        Intent i = new Intent(Intent.ACTION_VIEW, uri);
        Bundle extras = new Bundle();
        extras.putBinder("android.support.customtabs.extra.SESSION", null);
        i.putExtras(extras);
        i.putExtra("android.support.customtabs.extra.TOOLBAR_COLOR", 0xFF1E1730);
        i.putExtra("android.support.customtabs.extra.ENABLE_URLBAR_HIDING", true);
        i.putExtra("androidx.browser.customtabs.extra.SHARE_STATE", 2);
        if (hasChrome(a)) i.setPackage("com.android.chrome");
        Sim.log("Sim", "abrindo no " + (hasChrome(a) ? "Chrome" : "navegador padrão") + ": " + uri);
        try { a.startActivity(i); }
        catch (Exception e) {
            i.setPackage(null);
            try { a.startActivity(i); } catch (Exception e2) { Toast.makeText(a, "Nenhum navegador encontrado.", Toast.LENGTH_LONG).show(); }
        }
    }

    static boolean hasChrome(Context c) {
        try { c.getPackageManager().getPackageInfo("com.android.chrome", 0); return true; }
        catch (Exception e) { return false; }
    }

    /* ---------------- interface ---------------- */

    private int dp(int v) {
        return (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v, getResources().getDisplayMetrics());
    }

    private TextView text(String s, int sp, int color, boolean bold) {
        TextView t = new TextView(this);
        t.setText(s);
        t.setTextSize(TypedValue.COMPLEX_UNIT_SP, sp);
        t.setTextColor(color);
        if (bold) t.setTypeface(Typeface.DEFAULT_BOLD);
        return t;
    }

    private GradientDrawable round(int color, int radiusDp) {
        GradientDrawable g = new GradientDrawable();
        g.setColor(color);
        g.setCornerRadius(dp(radiusDp));
        return g;
    }

    private Button button(String s, boolean primary, View.OnClickListener l) {
        Button bt = new Button(this);
        bt.setText(s);
        bt.setAllCaps(false);
        bt.setTextColor(primary ? Color.WHITE : TXT);
        bt.setTextSize(TypedValue.COMPLEX_UNIT_SP, 15);
        bt.setGravity(Gravity.CENTER_VERTICAL | (primary ? Gravity.CENTER_HORIZONTAL : Gravity.START));
        bt.setPadding(dp(14), dp(10), dp(14), dp(10));
        bt.setBackground(round(primary ? PURPLE : CARD, 10));
        bt.setOnClickListener(l);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        lp.topMargin = dp(8);
        bt.setLayoutParams(lp);
        col.addView(bt);
        return bt;
    }

    private void section(String s) {
        TextView t = text(s, 13, SUB, true);
        t.setPadding(0, dp(18), 0, dp(2));
        col.addView(t);
    }

    private EditText field(String hint, String value) {
        EditText e = new EditText(this);
        e.setHint(hint);
        e.setText(value);
        e.setSingleLine(true);
        e.setTextColor(TXT);
        e.setHintTextColor(0xFF6B6280);
        e.setTextSize(TypedValue.COMPLEX_UNIT_SP, 15);
        e.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_URI);
        e.setBackground(round(CARD, 10));
        e.setPadding(dp(14), dp(12), dp(14), dp(12));
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        lp.topMargin = dp(8);
        e.setLayoutParams(lp);
        col.addView(e);
        return e;
    }

    private CheckBox check(String s, boolean v, final String key) {
        CheckBox c = new CheckBox(this);
        c.setText(s);
        c.setTextColor(TXT);
        c.setTextSize(TypedValue.COMPLEX_UNIT_SP, 14);
        c.setChecked(v);
        c.setPadding(dp(4), dp(6), 0, dp(6));
        c.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override public void onCheckedChanged(CompoundButton bt, boolean on) { p.edit().putBoolean(key, on).apply(); }
        });
        col.addView(c);
        return c;
    }

    private void buildUi() {
        ScrollView sv = new ScrollView(this);
        sv.setBackgroundColor(BG);
        sv.setFillViewport(true);
        col = new LinearLayout(this);
        col.setOrientation(LinearLayout.VERTICAL);
        col.setPadding(dp(20), dp(24), dp(20), dp(32));
        sv.addView(col);

        col.addView(text("ELVANOQ Roku Sim", 24, TXT, true));
        TextView sub = text("Simulador de Roku para testar o canal do ELVANOQ Play sem o aparelho. Roda o próprio código BrightScript/SceneGraph do repositório. Versão " + Sim.VERSION, 13, SUB, false);
        sub.setPadding(0, dp(4), 0, 0);
        col.addView(sub);

        section("APARELHO ROKU");
        presetBtn = button("", false, new View.OnClickListener() { @Override public void onClick(View v) { pickPreset(); } });
        localeBtn = button("", false, new View.OnClickListener() { @Override public void onClick(View v) {
            choose("Idioma da Roku", Sim.LOCALE_LABELS, "locale");
        } });

        section("CANAL");
        sourceBtn = button("", false, new View.OnClickListener() { @Override public void onClick(View v) {
            choose("De onde vem o canal", Sim.SOURCE_LABELS, "source");
        } });
        branchBtn = button("", false, new View.OnClickListener() { @Override public void onClick(View v) { pickBranch(); } });
        packBtn = button("", false, new View.OnClickListener() { @Override public void onClick(View v) {
            choose("Como montar o pacote", Sim.PACK_LABELS, "pack");
        } });
        fetchBtn = button("⬇  Baixar / atualizar do GitHub", false, new View.OnClickListener() { @Override public void onClick(View v) { fetchBranch(); } });
        importBtn = button("📦  Importar ZIP do canal (sideload ou artefato do workflow)", false, new View.OnClickListener() { @Override public void onClick(View v) { save(); pickZip(); } });
        pkgLabel = text("", 13, SUB, false);
        pkgLabel.setPadding(dp(4), dp(10), dp(4), 0);
        col.addView(pkgLabel);
        pkgInfoBtn = button("Ver manifest e avisos do pacote", false, new View.OnClickListener() { @Override public void onClick(View v) {
            new AlertDialog.Builder(MainActivity.this).setTitle("Pacote do canal").setMessage(Pkg.summary(Pkg.current(p)))
                .setPositiveButton("OK", null).show();
        } });

        section("DEEP LINK NA ABERTURA (OPCIONAL)");
        deepLink = field("contentId (ex.: movie:123:mp4, channel:45, series:9)", p.getString("deepLink", ""));
        deepType = field("mediaType (ex.: movie, episode, series, live)", p.getString("deepLinkType", ""));

        section("ONDE RODAR");
        browserBtn = button("", false, new View.OnClickListener() { @Override public void onClick(View v) {
            choose("Onde rodar", Sim.BROWSER_LABELS, "browser");
        } });

        section("OPÇÕES");
        check("Mostrar controle Roku na tela", p.getBoolean("showRemote", true), "showRemote");
        check("Mostrar log ao vivo", p.getBoolean("showLog", false), "showLog");
        check("Mostrar desempenho (FPS e memória)", p.getBoolean("stats", false), "stats");
        check("Animações da interface (como na Roku)", p.getBoolean("transitions", true), "transitions");
        check("60 FPS (pesa mais no celular; padrão 30)", p.getBoolean("fps60", false), "fps60");

        Button open = button("Abrir na Roku simulada", true, new View.OnClickListener() { @Override public void onClick(View v) { launch(); } });
        ((LinearLayout.LayoutParams) open.getLayoutParams()).topMargin = dp(22);
        open.setTextSize(TypedValue.COMPLEX_UNIT_SP, 17);

        section("FERRAMENTAS");
        button("Apagar dados salvos do canal (registro: login, listas, licença)", false, new View.OnClickListener() { @Override public void onClick(View v) { confirmClear(); } });
        button("Gerar novo ID do aparelho (outro código ROKU-…)", false, new View.OnClickListener() { @Override public void onClick(View v) {
            Sim.newIds(p);
            toast("Novo código: " + Sim.deviceCode(p.getString("clientId", "")) + ". O registro também foi zerado.");
            Sim.log("Sim", "novo ID do aparelho: " + Sim.deviceCode(p.getString("clientId", "")));
        } });
        button("Info do aparelho simulado", false, new View.OnClickListener() { @Override public void onClick(View v) { info(); } });
        button("Compartilhar último log", false, new View.OnClickListener() { @Override public void onClick(View v) { shareLog(MainActivity.this); } });
        button("Parar o servidor local", false, new View.OnClickListener() { @Override public void onClick(View v) {
            startService(new Intent(MainActivity.this, ServerService.class).setAction(ServerService.STOP));
            toast("Servidor parado. Ele abre de novo ao tocar em Abrir.");
        } });
        button("Dicas", false, new View.OnClickListener() { @Override public void onClick(View v) { tips(); } });

        setContentView(sv);
    }

    private void refresh() {
        String[] pr = Sim.PRESETS[Sim.preset(p)];
        presetBtn.setText("Modelo: " + pr[0] + " (" + pr[1] + ") · OS " + pr[2] + " · " + pr[3]);
        localeBtn.setText("Idioma: " + Sim.LOCALE_LABELS[p.getInt("locale", 0)]);
        int src = p.getInt("source", 0);
        sourceBtn.setText(Sim.SOURCE_LABELS[src]);
        branchBtn.setText("Branch: " + p.getString("branch", "main") + "  (tocar para trocar)");
        packBtn.setText("Montagem: " + Sim.PACK_LABELS[p.getInt("pack", 0)]);
        branchBtn.setVisibility(src == 0 ? View.VISIBLE : View.GONE);
        fetchBtn.setVisibility(src == 0 ? View.VISIBLE : View.GONE);
        importBtn.setVisibility(src == 1 ? View.VISIBLE : View.GONE);
        browserBtn.setText(Sim.BROWSER_LABELS[p.getInt("browser", 0)]);
        JSONObject w = Pkg.current(p);
        pkgInfoBtn.setVisibility(w == null ? View.GONE : View.VISIBLE);
        if (w == null) {
            pkgLabel.setText("Nenhum canal carregado ainda.");
            pkgLabel.setTextColor(SUB);
        } else {
            JSONArray wn = w.optJSONArray("warnings");
            int n = wn == null ? 0 : wn.length();
            pkgLabel.setText("Canal: " + w.optString("title") + " v" + w.optString("version") + " · " + w.optString("label")
                + (n > 0 ? "\n⚠ " + n + " aviso(s) no pacote" : "\nSem avisos no pacote"));
            pkgLabel.setTextColor(n > 0 ? WARN : SUB);
        }
    }

    private void save() {
        p.edit()
            .putString("deepLink", deepLink.getText().toString().trim())
            .putString("deepLinkType", deepType.getText().toString().trim())
            .apply();
    }

    private void choose(String title, String[] items, final String key) {
        new AlertDialog.Builder(this).setTitle(title)
            .setSingleChoiceItems(items, p.getInt(key, 0), new DialogInterface.OnClickListener() {
                @Override public void onClick(DialogInterface d, int i) { p.edit().putInt(key, i).apply(); d.dismiss(); refresh(); }
            }).show();
    }

    private void pickPreset() {
        String[] items = new String[Sim.PRESETS.length];
        for (int i = 0; i < items.length; i++) items[i] = Sim.PRESETS[i][0] + " · " + Sim.PRESETS[i][1] + " · OS " + Sim.PRESETS[i][2] + " · " + Sim.PRESETS[i][3];
        new AlertDialog.Builder(this).setTitle("Escolha a Roku")
            .setSingleChoiceItems(items, Sim.preset(p), new DialogInterface.OnClickListener() {
                @Override public void onClick(DialogInterface d, int i) { p.edit().putInt("preset", i).apply(); d.dismiss(); refresh(); }
            }).show();
    }

    private void confirmClear() {
        new AlertDialog.Builder(this).setTitle("Apagar dados salvos?")
            .setMessage("Zera o registro da Roku simulada (login, listas, licença local, preferências do canal). Na próxima abertura o canal começa do zero, como recém-instalado.\n\nO código ROKU-… continua o mesmo; para parecer outra Roku, use \"Gerar novo ID\".")
            .setPositiveButton("Apagar", new DialogInterface.OnClickListener() {
                @Override public void onClick(DialogInterface d, int w) {
                    p.edit().putLong("resetToken", System.currentTimeMillis()).apply();
                    try { WebStorage.getInstance().deleteAllData(); } catch (Throwable ignored) {}
                    try { CookieManager.getInstance().removeAllCookies(null); } catch (Throwable ignored) {}
                    Sim.log("Sim", "registro marcado para apagar na próxima abertura");
                    toast("Pronto. O registro é apagado na próxima abertura do canal.");
                }
            })
            .setNegativeButton("Cancelar", null).show();
    }

    private void info() {
        String[] pr = Sim.PRESETS[Sim.preset(p)];
        String msg = "Modelo: " + pr[0] + " (" + pr[1] + ")\nRoku OS: " + pr[2] + " (firmware " + Sim.firmware(pr) + ")\n"
            + "Interface: " + pr[3] + "\nIdioma: " + (p.getInt("locale", 0) == 1 ? "en_US" : "pt_BR") + " · País: BR\n\n"
            + "GetChannelClientId: " + p.getString("clientId", "") + "\nCódigo na ativação: " + Sim.deviceCode(p.getString("clientId", "")) + "\n"
            + "RIDA: " + p.getString("rida", "") + "\n\n"
            + "User-Agent das requisições: " + Sim.userAgent(pr) + "\n\n"
            + "Motor: brs-engine 2.7.0 + brs-scenegraph 0.7.0 (MIT)";
        new AlertDialog.Builder(this).setTitle("Roku simulada").setMessage(msg).setPositiveButton("OK", null).show();
    }

    private void tips() {
        String msg = "• O simulador roda o código do canal (BrightScript e SceneGraph) num interpretador, o brs-engine. Ele é muito fiel, mas não é a Roku: confira o resultado final no aparelho antes de enviar à loja.\n\n"
            + "• Baixar do GitHub monta o pacote igual ao ZIP do workflow (manifest, source, components, images, fonts). Assim, um arquivo que ficou de fora do ZIP também falta aqui, e a lista de avisos mostra o caminho pkg:/ que não foi achado.\n\n"
            + "• Dá para testar a branch de um PR antes do merge: toque em Branch e escolha.\n\n"
            + "• Todas as requisições do canal passam pelo servidor do simulador, com o User-Agent da Roku e sem CORS (como na Roku). O log mostra cada chamada com as senhas mascaradas; imagens e segmentos de vídeo aparecem somados a cada 15 s.\n\n"
            + "• Vídeo: HLS (.m3u8) e MP4 tocam. TS direto (.ts) não toca no navegador; o canal deve trocar para HLS sozinho, como faz quando a Roku não abre o formato.\n\n"
            + "• O motor precisa de SharedArrayBuffer, que a WebView do Android não libera. Por isso o padrão é abrir no Chrome, com o servidor local preso numa notificação. Toque em Parar na notificação quando terminar.\n\n"
            + "• Controle: segure ▲▼◀▶ para repetir. ⌨ digita texto direto no teclado do canal (como o app Roku do celular). Home fecha o canal; OK na tela inicial abre de novo.\n\n"
            + "• Teclado físico ou controle de TV box: setas, Enter = OK, Esc = Voltar, Home, Backspace = ↺, Insert = ✱, PageUp/PageDown = ⏪/⏩.";
        new AlertDialog.Builder(this).setTitle("Dicas").setMessage(msg).setPositiveButton("OK", null).show();
    }

    static void shareLog(Activity a) {
        String log = Sim.logAll(150000);
        if (log.length() == 0) log = "(log vazio)";
        Intent i = new Intent(Intent.ACTION_SEND);
        i.setType("text/plain");
        i.putExtra(Intent.EXTRA_SUBJECT, "ELVANOQ Roku Sim – log");
        i.putExtra(Intent.EXTRA_TEXT, log);
        try { a.startActivity(Intent.createChooser(i, "Compartilhar log")); } catch (Exception e) { Toast.makeText(a, "Nada para compartilhar", Toast.LENGTH_SHORT).show(); }
    }

    private void toast(String s) { Toast.makeText(this, s, Toast.LENGTH_LONG).show(); }
}
