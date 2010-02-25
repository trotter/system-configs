require 'fileutils'

module SystemConfigs
  class Install
    INST_DELIMITER = "##:"

    def initialize(source_dir, target_dir)
      @source_dir = source_dir
      @target_dir = target_dir
    end

    def run
      Dir.glob("#@source_dir/*.source", File::FNM_DOTMATCH).each do |path|
        puts "processing #{path}"
        process(path)
      end
    end
  
    def take_from(instructions, identifier)
      to_strip = /^#{INST_DELIMITER} *#{identifier}: */
      instruction = instructions.detect { |l| l =~ to_strip }
      instruction ? instruction.gsub(to_strip, '').strip : nil
    end

    def symlink(source, target)
      if File.exists?(target) && !File.symlink?(target)
        puts "Cannot symlink '#{target}', there is a file in its place."
        return
      end

      File.symlink(source, target) unless File.symlink?(target)
    end

    def copy(source, destination, file)
      middle_file = "%s/%s" % [@target_dir, File.basename(source).sub(/.source$/, '')]
      file.rewind
      data = file.lines.select { |l| l !~ /^#{INST_DELIMITER}/ }
      File.open(middle_file, "w") { |outfile| outfile.write data.join }
      symlink(middle_file, destination)
    end

    def copy_dir(source, destination, file)
      middle_file = "%s/%s" % [@target_dir, source]
      FileUtils.rm_r(middle_file, :force => true)
      FileUtils.cp_r("#@source_dir/#{source}", middle_file)
      symlink(middle_file, destination)
    end

    def clean_path(path)
      path.sub(/~/, "#{ENV['HOME']}")
    end
  
    def process(path)
      File.open(path) do |file|
        instructions = file.lines.select { |l| l =~ /^#{INST_DELIMITER}/ }
        return if instructions.empty?
  
        target  = clean_path(take_from(instructions, "target"))
        source  = clean_path(take_from(instructions, "source") || file.to_path)
        command = take_from(instructions, "command") || "copy"
        
        puts "command=%s;target=%s; source=%s;" % [command, target, source]
        send(command, source, target, file)
      end
    end
  end
end

if __FILE__ == $0
  source_dir = File.expand_path(File.dirname(__FILE__) + "/../source")
  target_dir = File.expand_path(File.dirname(__FILE__) + "/../target")
  installer = SystemConfigs::Install.new(source_dir, target_dir)
  installer.run
end
