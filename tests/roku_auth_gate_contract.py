"""Static regression contracts for the native Roku authentication gate.

Complements compilation; does not replace a test on Roku OS.
"""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
scene = (root / 'components/MainScene.brs').read_text()
catalog = (root / 'components/CatalogService.brs').read_text()

def routine(name):
    return re.search(r'(?ms)^sub ' + re.escape(name) + r'\([^\n]*\).*?^end sub', scene).group()

resolve = routine('handleServerCodeResult')
assert 'openCredentialKeyboard("username")' in resolve
assert 'openAppShell()' not in resolve
username = routine('onUsernameKeyboardSelected')
assert 'openCredentialKeyboard("password")' in username
assert 'openAppShell()' not in username
password = routine('onPasswordKeyboardSelected')
assert 'm.catalogAuthenticated = false' in password
assert 'm.catalogAuthPending = true' in password
assert 'username: m.manualUsername, password: password' in password
gate = routine('openAppShell')
assert gate.count('if m.catalogAuthenticated <> true then') == 2
assert gate.index('m.appShell.visible = false\n    m.top.appendChild') < gate.index('m.appShell.visible = true', gate.index('m.top.appendChild'))
active = routine('showActivationState')
assert active.index('if m.catalogAuthenticated <> true then') < active.index('setActivationVisible(false)')
result = routine('onStoreCatalogState')
assert 'if m.catalogAuthPending <> true then return' in result
assert 'if state.ok = true then\n            m.catalogAuthenticated = true' in result
assert 'else\n            m.catalogAuthenticated = false\n            m.appShell.visible = false' in result
assert scene.count('m.catalogAuthenticated = true') == 1
portal = routine('onPortalResult')
assert portal.index('if m.codeLoginActive = true and result.action <> "roku-server-code-resolve" then return') < portal.index('if result.action = "roku-device-register" then')
assert 'if safeTrim(info.auth) <> "1" then return' in catalog
auth = catalog.index('problem = xtreamAccountProblem(account.user_info)')
assert auth < catalog.index('result.ok = true', auth)
print('8 contratos OK: código, usuário, senha, Home protegida, licença separada, sucesso/erro do catálogo, concorrência e validação Xtream.')
