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

bad_prefixes = [
  "Assets/",
  "Coordinator/",
  "Controllers/",
  "Common/",
  "ShopViewController.swift"
]

puts "=== Aggressive Build File Purge ==="
project.objects.each do |obj|
  if obj.isa == 'PBXBuildFile' && obj.file_ref
    ref_path = obj.file_ref.path.to_s
    if bad_prefixes.any? { |p| ref_path.start_with?(p) } || ref_path == "ShopViewController.swift"
      puts "Purging bad build file linking: #{ref_path}"
      obj.remove_from_project
    end
  end
end

puts "=== Aggressive File Reference Purge ==="
project.objects.each do |obj|
  if obj.isa == 'PBXFileReference'
    ref_path = obj.path.to_s
    if bad_prefixes.any? { |p| ref_path.start_with?(p) } || ref_path == "ShopViewController.swift"
      puts "Purging bad file reference object: #{ref_path}"
      obj.remove_from_project
    end
  end
end

project.save
puts "Aggressive clean completed successfully!"
