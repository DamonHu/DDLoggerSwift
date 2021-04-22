Pod::Spec.new do |s|
s.name = 'ZXKitLogger'
s.swift_version = '5.0'
s.version = '2.5.1'
s.license= { :type => "Apache-2.0", :file => "LICENSE" }
s.summary = 'The iOS side displays the output log log on the screen, and can generate log file sharing, which is convenient for debugging information'
s.homepage = 'https://github.com/ZXKitCode/logger'
s.authors = { 'ZXKitCode' => 'dong765@qq.com' }
s.source = { :git => "https://github.com/ZXKitCode/logger.git", :tag => s.version}
s.requires_arc = true
s.ios.deployment_target = '10.0'
s.documentation_url = 'http://blog.hudongdong.com/ios/952.html'
s.subspec 'core' do |cs|
    cs.library = 'sqlite3'
    cs.source_files = "pod/*.swift","pod/**/*.strings"
    cs.dependency 'SnapKit'
    cs.dependency 'ZXKitUtil'
end
s.subspec 'wcdb' do |cs|
    cs.dependency 'ZXKitLogger/core'
    cs.dependency 'WCDB.swift'
end
s.default_subspecs = "Core"
end
