require 'xcodeproj'

project_path = 'GeoLive.xcodeproj'
unless File.exist?(project_path)
  puts "Error: project file not found!"
  exit 1
end

project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'GeoLive' }

unless target
  puts "Error: Target 'GeoLive' not found!"
  exit 1
end

sources_phase = target.source_build_phase
resources_phase = target.resources_build_phase

puts "=== Phase 1: Deep Clean Stale Build Files & File References ==="

build_files_to_remove = []
project.objects.each do |obj|
  if obj.isa == 'PBXBuildFile'
    file_ref = obj.file_ref
    if file_ref.nil?
      build_files_to_remove << obj
    else
      path_str = file_ref.path.to_s
      real_path = ""
      begin
        real_path = file_ref.real_path.to_s
      rescue
      end
      
      is_dead_path = path_str.start_with?("Assets/") || path_str.start_with?("Coordinator/") || path_str.start_with?("Controllers/") || path_str.start_with?("Common/") || path_str == "ShopViewController.swift"
      if is_dead_path || (!real_path.empty? && !File.exist?(real_path))
        puts "Purging Stale Build File: #{path_str}"
        build_files_to_remove << obj
      end
    end
  end
end

build_files_to_remove.uniq.each do |bf|
  sources_phase.remove_build_file(bf) rescue nil
  resources_phase.remove_build_file(bf) rescue nil
  bf.remove_from_project rescue nil
end

file_refs_to_remove = []
project.objects.each do |obj|
  if obj.isa == 'PBXFileReference'
    path_str = obj.path.to_s
    real_path = ""
    begin
      real_path = obj.real_path.to_s
    rescue
    end
    
    is_dead_path = path_str.start_with?("Assets/") || path_str.start_with?("Coordinator/") || path_str.start_with?("Controllers/") || path_str.start_with?("Common/") || path_str == "ShopViewController.swift"
    if is_dead_path || (!real_path.empty? && !File.exist?(real_path))
      puts "Purging Stale File Reference: #{path_str}"
      file_refs_to_remove << obj
    end
  end
end

file_refs_to_remove.uniq.each do |ref|
  ref.remove_from_project rescue nil
end

puts "=== Phase 2: Reset Group Mapping Paths globally (Targeted) ==="

# Restore physical path of the Pods group
pods_group = project.main_group['Pods']
if pods_group
  pods_group.path = 'Pods'
  pods_group.source_tree = '<group>'
  puts "Restored CocoaPods group path to 'Pods'"
end

# Target ONLY our custom directories and their subgroups
def reset_group_paths_targeted(group)
  group.path = nil
  group.source_tree = '<group>'
  group.children.each do |child|
    if child.isa == 'PBXGroup'
      reset_group_paths_targeted(child)
    end
  end
end

['Core', 'Modules', 'UIComponents'].each do |dir_name|
  next unless File.directory?(dir_name)
  group = project.main_group[dir_name] || project.main_group.new_group(dir_name)
  reset_group_paths_targeted(group)
  puts "Reset physical paths recursively for logical group: #{dir_name}"
end

puts "=== Phase 3: Recursive Re-Link of Sources & Resources ==="

def link_files_cleanly(project, parent_group, target, sources_phase, resources_phase, current_dir)
  Dir.each_child(current_dir) do |child|
    full_path = File.join(current_dir, child)
    
    if File.directory?(full_path)
      next if child.start_with?('.')
      sub_group = parent_group[child] || parent_group.new_group(child)
      sub_group.path = nil
      sub_group.source_tree = '<group>'
      link_files_cleanly(project, sub_group, target, sources_phase, resources_phase, full_path)
    elsif File.file?(full_path)
      relative_path = full_path.sub(/^\.\//, '')
      
      is_source = child.end_with?('.swift')
      is_resource = child.end_with?('.png') || child.end_with?('.jpg') || child.end_with?('.json') || child.end_with?('.xcassets')
      
      next unless is_source || is_resource
      
      # 1. Create file reference relative to virtual group path
      file_ref = parent_group.files.find { |f| f.path == relative_path }
      if file_ref.nil?
        file_ref = parent_group.new_file(relative_path)
      end
      
      # 2. Add to build phases
      if is_source
        build_file_exists = sources_phase.files.any? { |bf| bf.file_ref && bf.file_ref.path == relative_path }
        unless build_file_exists
          sources_phase.add_file_reference(file_ref)
          puts "Linked Source: #{child} successfully to target!"
        end
      elsif is_resource
        build_file_exists = resources_phase.files.any? { |bf| bf.file_ref && bf.file_ref.path == relative_path }
        unless build_file_exists
          resources_phase.add_file_reference(file_ref)
          puts "Linked Resource Asset: #{child} successfully to target resources!"
        end
      end
    end
  end
end

['Core', 'Modules', 'UIComponents'].each do |dir_name|
  next unless File.directory?(dir_name)
  group = project.main_group[dir_name]
  link_files_cleanly(project, group, target, sources_phase, resources_phase, dir_name)
end

project.save
puts "Xcode project healed, clean, and fully synchronized!"
