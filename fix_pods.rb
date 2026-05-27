require 'xcodeproj'

project_path = 'GeoLive.xcodeproj'
unless File.exist?(project_path)
  puts "Error: project file not found!"
  exit 1
end

project = Xcodeproj::Project.open(project_path)

# 1. Reset Pods group path to nil (pure logical group)
# This prevents resolved paths from pointing to "Pods/Pods/..."
pods_group = project.main_group['Pods']
if pods_group
  pods_group.path = nil
  pods_group.source_tree = '<group>'
  puts "Successfully cleared physical path on logical group 'Pods' to ensure correct CocoaPods xcconfig pathing."
end

# 2. Make Check Pods Manifest build phase robust
project.targets.each do |target|
  target.build_phases.each do |phase|
    if phase.respond_to?(:name) && phase.name == '[CP] Check Pods Manifest.lock'
      robust_script = <<~SH
        # Robust fallback path discovery in case Xcode fails to load base configurations
        PODS_PODFILE_DIR_PATH="${PODS_PODFILE_DIR_PATH:-$SRCROOT}"
        PODS_ROOT="${PODS_ROOT:-$SRCROOT/Pods}"
        
        diff "${PODS_PODFILE_DIR_PATH}/Podfile.lock" "${PODS_ROOT}/Manifest.lock" > /dev/null
        if [ $? != 0 ] ; then
            # print error to STDERR
            echo "error: The sandbox is not in sync with the Podfile.lock. Run 'pod install' or update your CocoaPods installation." >&2
            exit 1
        fi
        # This output is used by Xcode 'outputs' to avoid re-running this script phase.
        echo "SUCCESS" > "${SCRIPT_OUTPUT_FILE_0}"
      SH
      phase.shell_script = robust_script
      puts "Configured robust shell script for check manifest phase in target: #{target.name}"
    end
  end
  
  target.build_configurations.each do |config|
    config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
    puts "Disabled User Script Sandboxing in target #{target.name} configuration #{config.name}"
  end
end

# 3. Disable User Script Sandboxing at project level
project.build_configurations.each do |config|
  config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
  puts "Disabled User Script Sandboxing at project level configuration #{config.name}"
end

project.save
puts "Xcode project successfully healed!"
