Pod::Spec.new do |s|
s.name = 'HDWindowLoggerSwift'
s.swift_version = '5.0'
s.version = '2.4.1'
s.license= { :type => "MIT", :file => "LICENSE" }
s.summary = 'The iOS side displays the output log log on the screen, and can generate log file sharing, which is convenient for debugging information'
s.homepage = 'https://github.com/DamonHu/HDWindowLoggerSwift'
s.authors = { 'DamonHu' => 'dong765@qq.com' }
s.source = { :git => "https://github.com/DamonHu/HDWindowLoggerSwift.git", :tag => s.version}
s.requires_arc = true
s.ios.deployment_target = '10.0'
s.documentation_url = 'http://blog.hudongdong.com/ios/952.html'
s.subspec 'Core' do |cs|
    cs.library = 'sqlite3'
    cs.source_files = "HDWindowLoggerSwift/HDWindowLoggerSwift/*.swift","HDWindowLoggerSwift/HDWindowLoggerSwift/**/*.strings"
    cs.dependency 'SnapKit'
    cs.dependency 'HDCommonToolsSwift'
end
s.subspec 'WCDB' do |cs|
    cs.dependency 'HDWindowLoggerSwift/Core'
    cs.dependency 'WCDB.swift'
end
s.default_subspecs = "Core"
end
