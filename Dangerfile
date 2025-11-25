# Dangerfile for Pulsar iOS Project
# Validates pull requests for quality and consistency

# PR Title Format Validation
# Accepts: conventional commits (feat:, fix:, etc.) or milestone format (milestone-X-*)
title_pattern = /^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\(.+\))?: .+|^milestone-\d+-.+$/i

if !gitlab.mr_title.match?(title_pattern) && !github.pr_title.match?(title_pattern)
  warn("PR title should follow conventional commits format (e.g., 'feat: add feature') or milestone format (e.g., 'milestone-2-auth')")
end

# Check for changelog entry
changelog_modified = git.modified_files.include?("CHANGELOG.md")
if !changelog_modified && !github.pr_title.include?("chore") && !github.pr_title.include?("docs")
  warn("Consider adding a changelog entry for user-facing changes")
end

# Check for missing documentation
swift_files = git.modified_files.select { |file| file.end_with?(".swift") }
swift_files.each do |file|
  # Skip test files
  next if file.include?("Tests.swift") || file.include?("UITests.swift")
  
  # Check for public API documentation
  file_content = File.read(file)
  public_classes = file_content.scan(/^(public|open)\s+(class|struct|enum|protocol)\s+(\w+)/)
  
  public_classes.each do |match|
    class_name = match[2]
    # Check if class has documentation
    if !file_content.match?(/#{Regexp.escape(class_name)}.*\/\/\/|#{Regexp.escape(class_name)}.*\/\*\*/)
      warn("Public class/struct/enum `#{class_name}` in #{file} should have documentation")
    end
  end
end

# Check for TODO/FIXME comments
todo_count = 0
fixme_count = 0

git.modified_files.each do |file|
  next unless file.end_with?(".swift")
  
  content = File.read(file)
  todo_count += content.scan(/TODO:/i).count
  fixme_count += content.scan(/FIXME:/i).count
end

if todo_count > 0
  warn("Found #{todo_count} TODO comment(s) in modified files. Consider addressing them or creating issues.")
end

if fixme_count > 0
  warn("Found #{fixme_count} FIXME comment(s) in modified files. These should be addressed before merging.")
end

# File size limits
large_files = git.modified_files.select do |file|
  next false unless File.exist?(file)
  File.size(file) > 1000 * 1024 # 1MB
end

if large_files.any?
  warn("Large files detected (>1MB): #{large_files.join(', ')}. Consider splitting or optimizing.")
end

# Check for UI changes without screenshots
ui_files = git.modified_files.select { |file| file.include?("View.swift") || file.include?("Screen.swift") }
screenshot_files = git.modified_files.select { |file| file.end_with?(".png") || file.end_with?(".jpg") || file.end_with?(".jpeg") }

if ui_files.any? && screenshot_files.empty?
  message("UI changes detected. Consider adding screenshots to demonstrate the changes.")
end

# Test coverage warnings
# Note: Actual coverage checking is done in ci-coverage.yml
# This is just a reminder
if git.modified_files.any? { |file| file.end_with?(".swift") && !file.include?("Tests") }
  message("Remember to add tests for new functionality.")
end

# Check for breaking changes
breaking_keywords = ["remove", "delete", "deprecate", "breaking", "BREAKING"]
breaking_changes = git.modified_files.any? do |file|
  next false unless file.end_with?(".swift")
  content = File.read(file)
  breaking_keywords.any? { |keyword| content.include?(keyword) }
end

if breaking_changes
  warn("Potential breaking changes detected. Ensure CHANGELOG.md documents these changes.")
end

# Check for hardcoded secrets
secret_patterns = [
  /SUPABASE_ANON_KEY\s*=\s*["'][^"']+["']/,
  /API_KEY\s*=\s*["'][^"']+["']/,
  /SECRET\s*=\s*["'][^"']+["']/,
  /PASSWORD\s*=\s*["'][^"']+["']/,
]

git.modified_files.each do |file|
  next unless file.end_with?(".swift")
  
  content = File.read(file)
  secret_patterns.each do |pattern|
    if content.match?(pattern)
      fail("Potential hardcoded secret detected in #{file}. Use environment variables instead.")
    end
  end
end

# Summary message
message("PR validated by Danger. Please address any warnings before merging.")


