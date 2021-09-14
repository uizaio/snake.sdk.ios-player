Pod::Spec.new do |s|
    s.name = 'UZPlayer'
    s.version = '2.2.0'
    s.summary = 'UZPlayer'
    s.homepage = 'https://uiza.io/'
    s.documentation_url = 'https://docs.uiza.io'
    s.author = { 'UIZA' => 'developer@uiza.io' }
    s.license = { :type => "BSD", :file => "LICENSE" }
    s.source = { :git => "https://github.com/uizaio/snake.sdk.ios-player", :tag => "v" + s.version.to_s }
    s.source_files = 'UZPlayer/**/*.swift'
    s.resource_bundles = { 'Fonts' => ['UZPlayer/Fonts/*.ttf'],
                           'Icons' => ['UZPlayer/Themes/UZIcons.bundle'] }
    s.ios.deployment_target = '9.0'
    s.requires_arc  = true
    s.swift_version = '5.2'
    
    s.ios.dependency "NKModalPresenter"
    s.ios.dependency "FrameLayoutKit"
    s.ios.dependency "UZM3U8Kit"
    
end
