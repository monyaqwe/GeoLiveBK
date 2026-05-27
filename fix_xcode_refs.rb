require 'xcodeproj'

project_path = 'GeoLive.xcodeproj'
unless File.exist?(project_path)
  puts "Error: project file not found!"
  exit 1
end

project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'GeoLive' }
sources_phase = target.source_build_phase

puts "--- Xcode Clean-Up Phase ---"

# Remove all bad duplicate build files from the compile sources phase
sources_phase.files.each do |bf|
  if bf.file_ref && (bf.file_ref.path.to_s.include?("Modules/Auth/Modules") || bf.file_ref.path.to_s.include?("Modules/Modules") || bf.file_ref.path.to_s.include?("Modules/Shop/Modules") || bf.file_ref.path.to_s.include?("Modules/Inventory/Modules") || bf.file_ref.path.to_s.include?("Modules/Store/Modules"))
    puts "Removing bad build file reference: #{bf.file_ref.path}"
    sources_phase.remove_build_file(bf)
  end
end

# Clean up PBXFileReference objects from project
bad_refs = []
project.objects.each do |obj|
  if obj.isa == 'PBXFileReference' && (obj.path.to_s.include?("Modules/Auth/Modules") || obj.path.to_s.include?("Modules/Modules") || obj.path.to_s.include?("Modules/Shop/Modules") || obj.path.to_s.include?("Modules/Inventory/Modules") || obj.path.to_s.include?("Modules/Store/Modules"))
    puts "Marking bad reference object for deletion: #{obj.path}"
    bad_refs << obj
  end
end

bad_refs.each do |ref|
  ref.remove_from_project
end

puts "--- Xcode Pure Re-Linking Phase ---"

# Clears the physical path properties of the target groups so they function as clean logical folders
def clear_group_paths(group)
  group.path = nil
  group.source_tree = '<group>'
  group.children.each do |child|
    if child.isa == 'PBXGroup'
      clear_group_paths(child)
    end
  end
end

# Recursively re-link files relative to source root
def link_files_cleanly(project, parent_group, target, sources_phase, current_dir)
  Dir.each_child(current_dir) do |child|
    full_path = File.join(current_dir, child)
    
    if File.directory?(full_path)
      next if child.start_with?('.')
      sub_group = parent_group[child] || parent_group.new_group(child)
      sub_group.path = nil # Reset physical path mapping so it doesn't double-nest children
      sub_group.source_tree = '<group>'
      link_files_cleanly(project, sub_group, target, sources_phase, full_path)
    elsif File.file?(full_path) && child.end_with?('.swift')
      relative_path = full_path.sub(/^\.\//, '')
      
      # 1. Create file reference under the main group so it gets clean path relative to SOURCE_ROOT
      file_ref = project.main_group.files.find { |f| f.path == relative_path }
      if file_ref.nil?
        file_ref = project.main_group.new_file(relative_path)
      end
      
      # 2. Move file reference inside its nested parent group
      unless parent_group.children.include?(file_ref)
        parent_group.children << file_ref
      end
      
      # 3. Add to target source compilation build phase
      build_file_exists = sources_phase.files.any? { |bf| bf.file_ref && bf.file_ref.path == relative_path }
      unless build_file_exists
        sources_phase.add_file_reference(file_ref)
        puts "Linked #{child} successfully to target!"
      end
    end
  end
end

# Reset any physical folder mappings of our target folders to keep them purely logical
['Core', 'Modules', 'UIComponents'].each do |dir_name|
  next unless File.directory?(dir_name)
  group = project.main_group[dir_name] || project.main_group.new_group(dir_name)
  clear_group_paths(group)
  link_files_cleanly(project, group, target, sources_phase, dir_name)
end

project.save
puts "Xcode project re-linked, cleaned, and synchronized successfully!"
