platform :ios, '14.0'
inhibit_all_warnings!

target 'GeoLive' do
  use_frameworks!

  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  
  # Add other dependencies here
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      config.build_settings['GCC_TREAT_WARNINGS_AS_ERRORS'] = 'NO'
      config.build_settings['CLANG_USE_EXPLICIT_MODULES'] = 'NO'
      config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
      
      # Разрешаем подпись для Подов, чтобы приложение запускалось на реальном устройстве
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'YES'
      config.build_settings['DEVELOPMENT_TEAM'] = 'R6VTAQ7R5H'
    end
  end
end

