# Uncomment the next line to define a global platform for your project
platform :ios, '12'

inhibit_all_warnings!

def component(name)
  pod "ComponentsHub/#{name}", :git => 'git@github.com:alexgarbarev/ios-hub.git'
end

target 'NightwavePlaza' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  
  pod 'BugfenderSDK', '~> 1.9'
  pod 'GestureRecognizerClosures', '~> 5'
  
  
  component "SingletonStorage"
  
  # Pods for NightwavePlaza
  pod 'RxBiBinding'
  pod 'RxDataSources'
  pod 'RxSwift'
  pod 'RxCocoa'
  
  pod 'TRCAPIClient', :git => 'git@github.com:alexgarbarev/TRCAPIClient.git'
  pod 'TyphoonRestClient'
  pod 'PureLayout'
  
  pod 'ReachabilitySwift'
  
  pod 'NSString-Hash'

  
  target 'NightwavePlazaTests' do
    inherit! :search_paths
    # Pods for testing
  end

end
