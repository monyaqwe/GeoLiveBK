platform :ios, '14.0'

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
      
      # Разрешаем подпись для Подов, чтобы приложение запускалось на реальном устройстве
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'YES'
      config.build_settings['DEVELOPMENT_TEAM'] = 'R6VTAQ7R5H'
    end
  end
end
