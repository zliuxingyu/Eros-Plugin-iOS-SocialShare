#
#  Be sure to run `pod spec lint ErosPluginSocialShare.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|


  spec.name         = "ErosPluginSocialShare"
  spec.version      = "1.3.9"
  spec.summary      = "ErosPluginSocialShare Source."


  spec.description  = <<-DESC
			ErosPluginSocialShare SDK Podspec.
                        DESC

  spec.homepage       = "https://github.com/zliuxingyu/Eros-Plugin-iOS-SocialShare"

  # spec.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"


  spec.license        = "MIT"

  # spec.license      = { :type => "MIT", :file => "FILE_LICENSE" }


  spec.author               = { "luke" => "luke.liu@sjfood.com" }

  # Or just: spec.author    = "luke"
  # spec.authors            = { "luke" => "luke.liu@sjfood.com" }
  # spec.social_media_url   = "https://twitter.com/luke"


  spec.platform     = :ios
  spec.ios.deployment_target = '10.0'

  # spec.platform     = :ios, "8.0"
  #  When using multiple platforms
  # spec.ios.deployment_target = "5.0"
  # spec.osx.deployment_target = "10.7"
  # spec.watchos.deployment_target = "2.0"
  # spec.tvos.deployment_target = "9.0"


  spec.source          = { :git => "https://github.com/zliuxingyu/Eros-Plugin-iOS-SocialShare.git", :tag => spec.version.to_s }


  spec.source_files    = "ErosPluginSocialShare", "ErosPluginSocialShare/Source/*.{h,m}"

  # spec.source_files  = "Classes", "Classes/**/*.{h,m}"
  # spec.exclude_files = "Classes/Exclude"
  # spec.public_header_files = "Classes/**/*.h"


  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  # spec.resource  = "icon.png"
  # spec.resources = "Resources/*.png"
  # spec.preserve_paths = "FilesToSave", "MoreFilesToSave"

  spec.resources = "ErosPluginSocialShare/GoogleFramworks/GoogleSignIn.bundle"

  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  
  spec.frameworks = "LocalAuthentication", "SafariServices", "SystemConfiguration"
  spec.vendored_frameworks = "ErosPluginSocialShare/GoogleFramworks/GoogleSignInDependencies.framework", "ErosPluginSocialShare/GoogleFramworks/GoogleSignIn.framework"


  # spec.framework  = "SomeFramework"
  # spec.library   = "iconv"
  # spec.libraries = "iconv", "xml2"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  spec.requires_arc = true

  # spec.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }

  # spec.dependency 'UMCShare/Social/ReducedWeChat' #精简版
  spec.dependency 'UMCShare/Social/WeChat'          #完整版
  spec.dependency 'UMCShare/Social/Facebook'
  spec.dependency 'UMCShare/Social/Twitter'
  spec.dependency 'YYModel'	
  # spec.dependency 'WeexSDK' 
  spec.dependency 'WeexPluginLoader' 
  spec.dependency 'MSAL' 
end
