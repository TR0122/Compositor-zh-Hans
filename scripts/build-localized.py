import pathlib, subprocess, os, plistlib, shutil

ROOT = pathlib.Path(__file__).resolve().parents[1]
SRC = ROOT
BUILD = ROOT / 'build-zh'
BUILD.mkdir(exist_ok=True)
APP = ROOT / 'dist' / 'Compositor 中文版.app'
APP.parent.mkdir(exist_ok=True)
BASE = pathlib.Path('/Applications/Compositor.app')
SDK = '/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk'

def run(args):
    print('Running:', args[0], flush=True)
    subprocess.run(args, check=True, cwd=SRC)

objects = []
for source in sorted((SRC/'Compositor').rglob('*.c')):
    target = BUILD / (source.stem + '.o')
    run(['xcrun','clang','-O3','-arch','arm64','-isysroot',SDK,'-mmacosx-version-min=26.0','-c',str(source),'-o',str(target)])
    objects.append(str(target))
swift = sorted(str(p) for p in (SRC/'Compositor').rglob('*.swift'))
run(['xcrun','swiftc','-parse-as-library','-module-name','Compositor','-swift-version','5',
     '-default-isolation','MainActor','-enable-upcoming-feature','NonisolatedNonsendingByDefault',
     '-enable-upcoming-feature','MemberImportVisibility','-target','arm64-apple-macosx26.0',
     '-sdk',SDK,'-O','-whole-module-optimization',
     '-import-objc-header',str(SRC/'Compositor/Compositor-Bridging-Header.h'),
     '-Xlinker','-rpath','-Xlinker','@executable_path/../Frameworks',
     *swift,*objects,'-o',str(BUILD/'Compositor')])
if not APP.exists():
    shutil.copytree(BASE, APP, symlinks=True)
if (APP/'Contents/Frameworks').exists():
    shutil.rmtree(APP/'Contents/Frameworks')
shutil.copy2(BUILD/'Compositor', APP/'Contents/MacOS/Compositor')
info = APP/'Contents/Info.plist'
data=plistlib.load(info.open('rb'))
data.update(CFBundleIdentifier='com.local.compositor.zh-Hans',CFBundleName='Compositor 中文版',
            CFBundleDisplayName='Compositor 中文版',CFBundleDevelopmentRegion='zh-Hans',
            CFBundleLocalizations=['zh-Hans'],SUEnableAutomaticChecks=False,SUAutomaticallyUpdate=False)
for key in list(data):
    if key.startswith('SU'):
        data.pop(key)
data['CFBundleDocumentTypes'][0]['CFBundleTypeName']='图像'
data['CFBundleDocumentTypes'][1]['CFBundleTypeName']='Compositor 项目'
data['NSHumanReadableCopyright']='Compositor © 2026 Wonder Assembly LLC · MIT License · 本地简体中文版本'
plistlib.dump(data,info.open('wb'))
shutil.copy2(SRC/'LICENSE',APP/'Contents/Resources/LICENSE.txt')
resources=SRC/'Compositor/zh-Hans.lproj'
if resources.exists():
    shutil.copytree(resources,APP/'Contents/Resources/zh-Hans.lproj',dirs_exist_ok=True)
entitlements=plistlib.load((SRC/'Config/Compositor.entitlements').open('rb'))
entitlements.pop('com.apple.security.temporary-exception.mach-lookup.global-name',None)
plistlib.dump(entitlements,(BUILD/'entitlements.plist').open('wb'))
run(['codesign','--force','--sign','-','--entitlements',str(BUILD/'entitlements.plist'),str(APP)])
run(['codesign','--verify','--deep','--strict',str(APP)])
print('Built:', APP, flush=True)
