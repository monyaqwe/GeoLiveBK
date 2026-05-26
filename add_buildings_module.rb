require 'xcodeproj'

project_path = 'GeoLive.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# 1. Find or create the Modules group
modules_group = project.main_group['Modules'] || project.main_group.new_group('Modules')

# 2. Find or create the Buildings group inside Modules
buildings_group = modules_group['Buildings'] || modules_group.new_group('Buildings')

# 3. Add files to the group
# Make sure path is relative to project main group
models_file = buildings_group.new_file('Modules/Buildings/BuildingModels.swift')
views_file = buildings_group.new_file('Modules/Buildings/BuildingViews.swift')

# 4. Add files to the target
target = project.targets.find { |t| t.name == 'GeoLive' }
if target
  # Make sure we don't add duplicate file references to the sources build phase
  sources_phase = target.source_build_phase
  
  unless sources_phase.files.any? { |f| f.file_ref.path == models_file.path }
    target.add_file_references([models_file])
    puts "Added BuildingModels.swift to GeoLive sources!"
  end

  unless sources_phase.files.any? { |f| f.file_ref.path == views_file.path }
    target.add_file_references([views_file])
    puts "Added BuildingViews.swift to GeoLive sources!"
  end
else
  puts "Error: Target GeoLive not found!"
end

project.save
puts "Project saved successfully!"
