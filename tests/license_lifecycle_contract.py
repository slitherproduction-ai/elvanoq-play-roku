from pathlib import Path
root=Path(__file__).resolve().parents[1]
s=(root/'components/MainScene.brs').read_text();p=(root/'components/PortalService.brs').read_text();main=(root/'source/main.brs').read_text()
assert 'if m.licenseState = "active" or m.catalogAuthenticated = true then return' in s
active=s[s.index('    if state = "active" then',s.index('sub showActivationState')):s.index('    if (state = "expired"',s.index('sub showActivationState'))]
assert 'm.licenseTimer.control = "stop"' in active and 'm.registerTimer.control = "stop"' in active
assert 'now - m.lastLicenseOkAt <= 86400' in s
assert 'm.lastLicenseOkAt = 0' in s
assert 'result.httpStatus = 429 or result.httpStatus >= 500' in p
assert 'result.httpStatus = 401 or result.httpStatus = 403 or result.httpStatus = 409' in p
assert 'deviceInfo.EnableAppFocusEvent(true)' in main and 'scene.appResumed = true' in main
assert 'onChange="onAppResumed"' in (root/'components/MainScene.xml').read_text()
print('Roku: launch/resume, no active polling, bounded grace and explicit denial contracts OK')
