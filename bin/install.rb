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
      instructions.detect { |l| l =~ to_strip }.gsub(to_strip, '').strip
    end
  
    def process(path)
      File.open(path) do |file|
        instructions = file.lines.select { |l| l =~ /^#{INST_DELIMITER}/ }
        return if instructions.empty?
  
        file.rewind
        data = file.lines.select { |l| l !~ /^#{INST_DELIMITER}/ }
        link_file   = take_from(instructions, "target").sub(/~/, "#{ENV['HOME']}")
        target_file = "%s/%s" % [@target_dir, File.basename(file.to_path).sub(/.source$/, '')]

        File.open(target_file, "w") { |outfile| outfile.write data.join }

        if File.exists?(link_file) && !File.symlink?(link_file)
          puts "Cannot symlink '#{link_file}', there is a file in its place."
          return
        end
  
        File.symlink(target_file, link_file) unless File.symlink?(link_file)
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
