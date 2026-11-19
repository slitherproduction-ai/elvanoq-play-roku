/* ELVANOQ Roku Sim – página que hospeda o motor brs-engine (BrightScript + SceneGraph). */
(function () {
    "use strict";

    var bridge = window.SimBridge || null; // só existe na WebView do app
    var $ = function (id) { return document.getElementById(id); };
    var cfg = null;
    var running = false;
    var starting = false;
    var engineReady = false;
    var pkgData = null;
    var logShown = false;
    var logNext = 0;
    var heldKeys = {};

    /* ---------------- log (vai para o app: log ao vivo e compartilhável) ---------------- */
    var logQueue = [];
    function log(tag, msg) {
        logQueue.push(tag + "\t" + String(msg).replace(/[\r\n]+$/, "").replace(/\n/g, "\n    "));
        if (logQueue.length > 400) logQueue.splice(0, logQueue.length - 400);
    }
    setInterval(function () {
        if (!logQueue.length) return;
        var body = logQueue.join("\n");
        logQueue = [];
        fetch("/sim/log", { method: "POST", body: body }).catch(function () {});
    }, 400);
    window.addEventListener("error", function (e) { log("Página", "erro JS: " + e.message + " @ " + (e.filename || "").split("/").pop() + ":" + e.lineno); });
    window.addEventListener("unhandledrejection", function (e) { log("Página", "promise rejeitada: " + (e.reason && e.reason.message || e.reason)); });

    /* ---------------- layout ---------------- */
    function layout() {
        var wrap = $("tvwrap");
        var portrait = window.innerHeight > window.innerWidth;
        if (portrait) wrap.style.height = Math.round(window.innerWidth * 9 / 16) + "px";
        else wrap.style.height = "";
        var W = wrap.clientWidth, H = wrap.clientHeight;
        var w = W, h = Math.floor(W * 9 / 16);
        if (h > H) { h = H; w = Math.floor(H * 16 / 9); }
        var tv = $("tv");
        tv.style.width = w + "px";
        tv.style.height = h + "px";
        if (engineReady) brs.redraw(false, w, h, window.devicePixelRatio);
    }
    window.addEventListener("resize", function () { setTimeout(layout, 50); });

    function homeMsg(t) { $("homeMsg").textContent = t; }
    function showHome(on) { $("home").classList.toggle("hidden", !on); }
    function fatal(t) {
        $("fatalMsg").textContent = t;
        $("fatal").classList.remove("hidden");
        log("Sim", t.replace(/\n+/g, " "));
    }

    /* ---------------- teclas ---------------- */
    function keyName(k) { return k === "play" ? "play" : k; }

    window.__sim = {
        key: function (k, down) {
            if (!$("menu").classList.contains("hidden") && down) { if (k === "back") closeMenu(); return; }
            if (!running) {
                if (down && (k === "select" || k === "play")) launch();
                return;
            }
            if (k === "home") {
                if (down) { log("Tecla", "Home"); brs.sendKeyDown("home"); }
                else brs.sendKeyUp("home");
                return;
            }
            if (down) brs.sendKeyDown(keyName(k)); else brs.sendKeyUp(keyName(k));
        }
    };

    function bindRemote() {
        var buttons = document.querySelectorAll("#remote button[data-key]");
        Array.prototype.forEach.call(buttons, function (b) {
            var k = b.getAttribute("data-key");
            var down = function (e) {
                e.preventDefault();
                if (heldKeys[k]) return;
                heldKeys[k] = true;
                b.classList.add("down");
                if (navigator.vibrate) try { navigator.vibrate(8); } catch (x) {}
                __sim.key(k, true);
            };
            var up = function (e) {
                if (e) e.preventDefault();
                if (!heldKeys[k]) return;
                heldKeys[k] = false;
                b.classList.remove("down");
                __sim.key(k, false);
            };
            b.addEventListener("pointerdown", down);
            b.addEventListener("pointerup", up);
            b.addEventListener("pointercancel", up);
            b.addEventListener("pointerleave", up);
            b.addEventListener("contextmenu", function (e) { e.preventDefault(); });
        });
        Array.prototype.forEach.call(document.querySelectorAll("#remote button[data-act]"), function (b) {
            b.addEventListener("click", function () {
                var a = b.getAttribute("data-act");
                if (a === "menu") openMenu();
                else if (a === "log") toggleLog();
                else if (a === "full") toggleFull();
                else if (a === "type") openTyper();
            });
        });
        // teclado físico quando o motor não está ouvindo (tela inicial)
        document.addEventListener("keydown", function (e) {
            if (!$("typer").classList.contains("hidden")) return;
            if (!running && (e.key === "Enter" || e.key === " ")) { e.preventDefault(); launch(); }
        });
    }

    /* ---------------- digitar ---------------- */
    function openTyper() {
        if (!running) return;
        $("typer").classList.remove("hidden");
        var inp = $("typerInput");
        inp.value = "";
        if (bridge) bridge.setEditing(true);
        setTimeout(function () { inp.focus(); }, 50);
    }
    function closeTyper() {
        $("typer").classList.add("hidden");
        $("typerInput").blur();
        if (bridge) bridge.setEditing(false);
    }
    function typeText(t) {
        var chars = Array.from(t);
        var i = 0;
        (function next() {
            if (i >= chars.length) return;
            brs.sendKeyPress("lit_" + chars[i++], 40);
            setTimeout(next, 90);
        })();
        log("Tecla", "texto digitado (" + chars.length + " caracteres)");
    }
    function bindTyper() {
        var inp = $("typerInput");
        $("typerSend").addEventListener("click", function () { typeText(inp.value); inp.value = ""; closeTyper(); });
        $("typerBksp").addEventListener("click", function () { brs.sendKeyPress("backspace", 40); });
        $("typerClose").addEventListener("click", closeTyper);
        inp.addEventListener("keydown", function (e) {
            e.stopPropagation();
            if (e.key === "Enter") { e.preventDefault(); typeText(inp.value); inp.value = ""; closeTyper(); }
            if (e.key === "Escape") { e.preventDefault(); closeTyper(); }
        });
        inp.addEventListener("keyup", function (e) { e.stopPropagation(); });
    }

    /* ---------------- menu ---------------- */
    function openMenu() { $("menu").classList.remove("hidden"); }
    function closeMenu() { $("menu").classList.add("hidden"); }
    function bindMenu() {
        $("menu").addEventListener("click", function (e) { if (e.target.id === "menu") closeMenu(); });
        Array.prototype.forEach.call(document.querySelectorAll("#menu button"), function (b) {
            b.addEventListener("click", function () {
                closeMenu();
                var m = b.getAttribute("data-m");
                if (m === "restart") restart();
                else if (m === "deeplink") sendDeepLink();
                else if (m === "remote") { document.body.classList.toggle("no-remote"); setTimeout(layout, 30); }
                else if (m === "stats") { cfg.showStats = !cfg.showStats; brs.enableStats(cfg.showStats); }
                else if (m === "share") { if (bridge) bridge.share(); else fetch("/sim/share"); }
                else if (m === "settings") { if (bridge) bridge.closeApp(); else fetch("/sim/settings"); }
                else if (m === "info") info();
                else if (m === "close") { if (running) brs.terminate("EXIT_USER_NAV"); if (bridge) bridge.closeApp(); else window.close(); }
            });
        });
    }

    function sendDeepLink() {
        var id = window.prompt("contentId (ex.: movie:123:mp4, channel:45)", cfg.deepLink || "");
        if (!id) return;
        var type = window.prompt("mediaType (ex.: movie, episode, series, live)", cfg.deepLinkType || "movie") || "";
        if (!running) { cfg.deepLink = id; cfg.deepLinkType = type; launch(); return; }
        brs.sendInput({ contentId: id, mediaType: type, source: "sim" });
        log("Sim", "roInput enviado: contentId=" + id + " mediaType=" + type);
    }

    function info() {
        var d = cfg.device;
        alert("Roku: " + cfg.preset + " (" + d.deviceModel + ")\nRoku OS " + cfg.os + " · firmware " + d.firmwareVersion
            + "\nInterface: " + d.displayMode + " · " + d.locale
            + "\nCódigo na ativação: " + cfg.deviceCode
            + "\nCanal: " + cfg.pkgName
            + "\nMotor: brs-engine " + (brs.getVersion ? brs.getVersion() : "?")
            + "\ncrossOriginIsolated: " + window.crossOriginIsolated
            + "\nNavegador: " + navigator.userAgent);
    }

    /* ---------------- log ao vivo ---------------- */
    function toggleLog() {
        logShown = !logShown;
        $("logpanel").classList.toggle("hidden", !logShown);
        if (logShown) pollLog(true);
    }
    function pollLog(scroll) {
        if (!logShown) return;
        fetch("/sim/log?since=" + logNext).then(function (r) { return r.json(); }).then(function (o) {
            logNext = o.next;
            if (o.lines && o.lines.length) {
                var pre = $("logtext");
                var panel = $("logpanel");
                var atEnd = scroll || panel.scrollTop + panel.clientHeight >= panel.scrollHeight - 30;
                pre.textContent += o.lines.join("\n") + "\n";
                if (pre.textContent.length > 120000) pre.textContent = pre.textContent.slice(-90000);
                if (atEnd) panel.scrollTop = panel.scrollHeight;
            }
        }).catch(function () {});
    }
    setInterval(function () { pollLog(false); }, 700);

    function toggleFull() {
        if (document.fullscreenElement) document.exitFullscreen().catch(function () {});
        else document.documentElement.requestFullscreen().then(function () {
            if (screen.orientation && screen.orientation.lock) screen.orientation.lock("landscape").catch(function () {});
        }).catch(function () {});
    }

    /* ---------------- motor ---------------- */
    function resetRegistryIfAsked() {
        try {
            var token = String(cfg.resetToken);
            var saved = localStorage.getItem("__rokusim_reset");
            if (saved !== token) {
                if (saved !== null) log("Sim", "registro apagado (pedido nas configurações)");
                localStorage.clear();
                localStorage.setItem("__rokusim_reset", token);
            }
        } catch (e) { log("Sim", "localStorage indisponível: " + e.message); }
    }

    function subscribe() {
        brs.subscribe("rokusim", function (event, data) {
            if (event === "loaded") {
                log("Canal", "pacote lido: " + (data.title || "") + " " + (data.version || ""));
            } else if (event === "started") {
                running = true;
                starting = false;
                showHome(false);
                log("Canal", "rodando");
            } else if (event === "closed") {
                running = false;
                starting = false;
                log("Canal", "encerrado: " + data);
                showHome(true);
                homeMsg("Canal encerrado (" + data + ").");
            } else if (event === "error") {
                log("Motor", "ERRO " + data);
                if (starting) { starting = false; showHome(true); homeMsg("Erro ao abrir: " + data); }
            } else if (event === "debug") {
                if (!data) return;
                var lvl = data.level, c = String(data.content || "").replace(/\r?\n$/, "");
                if (!c) return;
                var tag = lvl === "print" ? "BrightScript" : lvl === "beacon" ? "Beacon" : lvl === "error" ? "BrightScript ERRO" : lvl === "warning" ? "Aviso" : "Motor";
                log(tag, c);
            } else if (event === "control") {
                if (data && data.mod === 0 && data.key && data.key.indexOf("lit_") !== 0) log("Tecla", data.key);
            } else if (event === "launch") {
                log("Canal", "pediu para abrir outro canal: " + JSON.stringify(data));
            } else if (event === "browser") {
                log("Canal", "pediu para abrir o navegador: " + (data && data.url));
            } else if (event === "resolution") {
                log("Canal", "resolução: " + JSON.stringify(data));
            } else if (event === "version") {
                log("Motor", "interpretador brs-engine " + data);
            }
        });
    }

    function deepLinkMap() {
        if (!cfg.deepLink) return undefined;
        var m = new Map();
        m.set("contentId", cfg.deepLink);
        if (cfg.deepLinkType) m.set("mediaType", cfg.deepLinkType);
        return m;
    }

    function loadPkg() {
        return fetch("/pkg/current.zip?s=" + cfg.pkgStamp).then(function (r) {
            if (!r.ok) throw new Error("sem pacote (" + r.status + ")");
            return r.arrayBuffer();
        }).then(function (b) { pkgData = b; return b; });
    }

    function launch() {
        if (running || starting || !engineReady) return;
        if (!pkgData) { homeMsg("Nenhum canal carregado. Baixe a branch ou importe o ZIP nas configurações."); return; }
        starting = true;
        homeMsg("Abrindo o canal…");
        var dl = deepLinkMap();
        if (dl) log("Sim", "deep link na abertura: contentId=" + cfg.deepLink + " mediaType=" + cfg.deepLinkType);
        // o motor consome o ArrayBuffer: manda uma cópia para poder reabrir
        brs.execute("elvanoq-play.zip", pkgData.slice(0), { clearDisplayOnExit: true, debugOnCrash: false, entryPoint: true }, dl);
        cfg.deepLink = "";
    }

    function restart() {
        if (running) brs.terminate("EXIT_USER_NAV");
        setTimeout(launch, 400);
    }

    function start() {
        layout();
        if (!window.crossOriginIsolated || typeof SharedArrayBuffer === "undefined") {
            log("Sim", "crossOriginIsolated=" + window.crossOriginIsolated + " · SharedArrayBuffer=" + (typeof SharedArrayBuffer));
            if (bridge) { bridge.noIsolation(); return; }
            fatal("Este navegador não liberou SharedArrayBuffer (crossOriginIsolated = false).\n\nO motor da Roku simulada precisa dele. Abra pelo Chrome atualizado, a partir do app ELVANOQ Roku Sim.");
            return;
        }
        resetRegistryIfAsked();
        subscribe();
        var d = cfg.device;
        d.extensions = new Map([[brs.SupportedExtension.SceneGraph, "./brs-sg.js"]]);
        homeMsg("Iniciando o motor…");
        brs.initialize(d, { debugToConsole: false, showStats: !!cfg.showStats, disableKeys: false }).then(function () {
            engineReady = true;
            layout();
            log("Motor", "pronto · brs-engine " + (brs.getVersion ? brs.getVersion() : "?") + " · " + d.deviceModel + " · " + d.displayMode + " · " + d.locale);
            return loadPkg();
        }).then(function () {
            homeMsg(cfg.belowMin ? "Atenção: esta Roku tem OS " + cfg.os + "; o canal exige 15.1+ (a loja não instalaria)." : "");
            launch();
        }).catch(function (e) {
            starting = false;
            homeMsg("Não deu para abrir: " + e.message);
            log("Sim", "falha ao iniciar: " + e.message);
        });
    }

    fetch("/sim/config").then(function (r) { return r.json(); }).then(function (c) {
        cfg = c;
        document.body.classList.toggle("no-remote", !cfg.showRemote);
        $("tileSub").textContent = cfg.pkgName || "nenhum canal";
        $("menuTitle").textContent = cfg.preset + " · OS " + cfg.os;
        $("remoteInfo").textContent = cfg.preset + " · OS " + cfg.os + " · " + cfg.device.displayMode + "\n" + cfg.deviceCode + "\n" + (cfg.pkgName || "");
        log("Sim", "página aberta em " + (bridge ? "WebView" : "navegador") + " · " + navigator.userAgent);
        bindRemote();
        bindTyper();
        bindMenu();
        if (cfg.showLog) toggleLog();
        start();
    }).catch(function (e) {
        fatal("O servidor do simulador não respondeu (" + e.message + ").\n\nAbra o app ELVANOQ Roku Sim e toque em Abrir na Roku simulada.");
    });
})();
