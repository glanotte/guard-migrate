module Guard
  class Migrate
    class Migration

      attr_accessor :path

      def initialize(_path)
        @path = _path
      end

      def version
        path.scan(%r{^db/migrate/(\d+).+\.rb}).flatten.first
      end

      def valid?
        file = File.open(path, 'r')
        content = file.read.gsub(/\s+/, '')
        !content.empty? && content.match(/def(up|down|change)end/).nil?
      rescue Errno::ENOENT
        false
      ensure
        begin; file.close; rescue; end      
      end  

    end
  end
end