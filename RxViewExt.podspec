Pod::Spec.new do |s|
  s.name             = 'RxViewExt'
  s.version          = '0.1.0'
  s.summary          = 'A short description of RxViewExt.'

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/mattadatta/RxViewExt'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Matthew Brown' => 'me.matt.brown@gmail.com' }
  s.source           = { :git => 'https://github.com/mattadatta/RxViewExt.git', :tag => "v/#{s.version}" }

  s.ios.deployment_target = '11.0'

  s.source_files = 'RxViewExt/Classes/**/*'

  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'RxSwiftExt'
  s.dependency 'RxGesture'
end
