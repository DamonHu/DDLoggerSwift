Pod::Spec.new do |s|
s.name = 'DDLoggerSwift'
s.swift_version = '5.0'
s.version = '5.3.3'
s.license= { :type => "MIT", :file => "LICENSE" }
s.summary = 'The iOS side displays the output log log on the screen, and can generate log file sharing, which is convenient for debugging information'
s.homepage = 'https://github.com/DamonHu/DDLoggerSwift'
s.authors = { 'DamonHu' => 'dong765@qq.com' }
s.source = { :git => "https://github.com/DamonHu/DDLoggerSwift.git", :tag => s.version}
s.requires_arc = true
s.ios.deployment_target = '12.0'
s.documentation_url = 'https://dongge.org/blog/1305.html'
s.subspec 'core' do |cs|
    cs.resource_bundles = {
      'DDLoggerSwift' => ['pod/assets/**/*']
    }
    cs.library = 'sqlite3'
    cs.source_files = "pod/*.swift", "pod/view/*.swift", "pod/model/*.swift"
    cs.dependency 'DDUtils/ui', '~>5'
    cs.dependency 'DDUtils/utils', '~>5'
end
s.default_subspecs = "core"
end
