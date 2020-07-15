Pod::Spec.new do |s|
s.name = 'HDWindowLoggerSwift'
s.swift_version = '5.0'
s.version = '2.1.5'
s.license= { :type => "MIT", :file => "LICENSE" }
s.summary = 'The iOS side displays the output log log on the screen, and can generate log file sharing, which is convenient for debugging information'
s.homepage = 'https://github.com/DamonHu/HDWindowLoggerSwift'
s.authors = { 'DamonHu' => 'dong765@qq.com' }
s.source = { :git => "https://github.com/DamonHu/HDWindowLoggerSwift.git", :tag => s.version}
s.requires_arc = true
s.ios.deployment_target = '10.0'
s.source_files = "HDWindowLoggerSwift/HDWindowLoggerSwift/*.swift","HDWindowLoggerSwift/HDWindowLoggerSwift/**/*.strings"
s.dependency 'SnapKit'
s.dependency 'HDSwiftCommonTools'
s.documentation_url = 'http://blog.hudongdong.com/ios/952.html'
end