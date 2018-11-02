Pod::Spec.new do |s|
  s.name            =  'Weaver'
  s.version         =  '0.1.2'
  s.summary         =  'Remote debugging for Texture apps using Chrome DevTools.'
  s.homepage        =  'https://github.com/TextureGroup/Weaver'
  s.description     =  'Weaver is a remote debugging toolset. It is a client library and gateway server combination that uses Chrome DevTools on your browser to debug applications that use Texture framework'
  s.author          =  { 'Huy Nguyen' => 'huy@pinterest.com', 'Garrett Moon' => 'garrett@excitedpixel.com', 'Michael Schneider' => 'schneider@pinterest.com', 'Adlai Holler' => 'adlai@pinterest.com', 'Square' => 'https://squareup.com/' }
  s.source          =  { :git => 'https://github.com/TextureGroup/Weaver.git', :tag => s.version.to_s }
  s.license         =  'Apache License, Version 2.0'

  s.requires_arc = true
  s.ios.deployment_target = '8.0'
  s.source_files = 'ObjC/{DerivedSources,PonyDebugger,Weaver}/**/*.{h,m,mm}'
  s.dependency 'Texture', '>= 2.3.4'
  s.dependency 'SocketRocket', '0.5.1'
  s.xcconfig = { 'ENABLE_NS_ASSERTIONS' => 'YES' }
end
