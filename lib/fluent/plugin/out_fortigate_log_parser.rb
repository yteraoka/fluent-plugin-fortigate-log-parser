module Fluent
  class FortigateSyslogParseOutput < Output
    Fluent::Plugin.register_output('fortigate_log_parser', self)

    require 'uri'

    config_param :remove_prefix,    :string, :default => nil
    config_param :add_prefix,       :string, :default => nil
    config_param :message_key,      :string, :default => 'message'
    config_param :keys,             :string, :default => nil
    config_param :remove_keys,      :string, :default => nil
    config_param :country_map_file, :string, :default => nil
    config_param :fortios_version,  :integer, :default => 5

    def configure(conf)
      super

      @prev_time_str = nil
      @prev_time = nil
      @country_map = nil

      if @message_key == ''
        fail ConfigError, 'message_key required a value'
      end

      if @remove_prefix
        @removed_prefix_string = @remove_prefix + '.'
        @removed_length = @removed_prefix_string.length
      end
      if @add_prefix
        @added_prefix_string = @add_prefix + '.'
      end

      if @keys
        if @remove_keys
          fail ConfigError, "fortigate_log_parser: 'keys' and 'remove_keys'" \
                             ' parameters are exclusive'
        end
        @keys = Hash[@keys.split(',').map { |x| [x, 1] }]
      end
      if @remove_keys
        @remove_keys = Hash[@remove_keys.split(',').map { |x| [x, 1] }]
      end

      if @country_map_file
        unless File.exist?(@country_map_file)
          fail ConfigError, "#{@country_map_file} does not exist"
        end
        @country_map = {}
        File.open(@country_map_file, 'r') do |f|
          f.each_line do |line|
            (country_name, country_code) = line.chomp.split(/\t/, 2)
            @country_map[country_name] = country_code
          end
        end
      end

      if @fortios_version >= 5
        @srccountry_key = 'srccountry'
        @dstcountry_key = 'dstcountry'
      else
        @srccountry_key = 'src_country'
        @dstcountry_key = 'dst_country'
      end
    end

    def emit(tag, es, chain)
      _tag = tag.clone

      if @remove_prefix &&
        ((tag.start_with?(@removed_prefix_string) &&
          tag.length > @removed_length) || tag == @remove_prefix)
        tag = tag[@removed_length..-1] || ''
      end

      if @add_prefix
        tag = tag && tag.length > 0 ? @added_prefix_string + tag : @add_prefix
      end

      es.each do |time, record|
        time, record = parse(record)
        router.emit(tag, time, record)
      end

      chain.next
    end

    def parse(record)
      message = record[@message_key]
      record.delete(@message_key)
      data = message.split(/\s+/, 5).pop
      data.gsub(/\G[^,=]+=(:?"[^"]*"|[^,]+)(:?,|$)/) do |kv|
        (k, v) = kv.strip.split(/=/, 2)
        if k == 'date' || k == 'time' ||
           (@keys && @keys.key?(k)) ||
           (@remove_keys && !@remove_keys.key?(k)) ||
           (!@keys && !@remove_keys)
          record[k] = v.gsub(/,$/, '').gsub(/^"(.*)"$/, '\1')
        end
      end

      # rsyslog workaround (remove the unnecessary white space)
      # rsyslog insert a space (0x20) after first colon (:)
      # (eg. time=12:34:56 -> time=12: 34:56)
      record['time'].gsub!(' ', '')

      time_str = record['date'] + ' ' + record['time']
      time = nil

      if @prev_time && time_str == @prev_time_str
        time = @prev_time
      else
        time = Time.strptime(time_str, '%Y-%m-%d %H:%M:%S').to_i
        @prev_time = time
        @prev_time_str = time_str
      end

      if @country_map
        if record.key?(@srccountry_key) &&
           @country_map.key?(record[@srccountry_key])
          record[@srccountry_key + '_code'] =
              @country_map[record[@srccountry_key]]
        end
        if record.key?(@dstcountry_key) &&
           @country_map.key?(record[@dstcountry_key])
          record[@dstcountry_key + '_code'] =
              @country_map[record[@dstcountry_key]]
        end
      end

      if record.key?('file')
        record['file'] = URI.escape(record['file'])
      end

      if record.key?('filename')
        record['filename'] = URI.escape(record['filename'])
      end

      record.delete('date')
      record.delete('time')

      [time, record]
    end
  end
end
