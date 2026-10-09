import pathlib,subprocess,plistlib,shutil
root=pathlib.Path(__file__).resolve().parents[1]
src=root/'Compositor'
test=root/'build-zh/Smoke.app'
(test/'Contents/MacOS').mkdir(parents=True,exist_ok=True)
shutil.copytree(src/'zh-Hans.lproj',test/'Contents/Resources/zh-Hans.lproj',dirs_exist_ok=True)
plistlib.dump(dict(CFBundleIdentifier='com.local.compositor.smoke',CFBundleDevelopmentRegion='zh-Hans',
                  CFBundleExecutable='Smoke',CFBundlePackageType='APPL'),(test/'Contents/Info.plist').open('wb'))
swift=[str(p) for p in sorted(src.rglob('*.swift')) if p.name!='CompositorApp.swift']
objects=sorted(str(p) for p in (root/'build-zh').glob('*.o'))
args=['xcrun','swiftc','-parse-as-library','-module-name','Compositor','-swift-version','5',
      '-default-isolation','MainActor','-enable-upcoming-feature','NonisolatedNonsendingByDefault',
      '-enable-upcoming-feature','MemberImportVisibility','-target','arm64-apple-macosx26.0',
      '-sdk','/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk','-Onone','-whole-module-optimization',
      '-import-objc-header',str(src/'Compositor-Bridging-Header.h'),
      *swift,str(root/'scripts/LocalizationSmoke.swift'),*objects,'-o',str(test/'Contents/MacOS/Smoke')]
subprocess.run(args,check=True)
subprocess.run([str(test/'Contents/MacOS/Smoke')],check=True)
