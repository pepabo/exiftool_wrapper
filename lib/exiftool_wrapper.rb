# -*- coding: utf-8 -*-

require 'active_support/core_ext'

module ExifTool
  class Wrapper
    raise unless `exiftool -ver`

    attr_accessor :exiftool
    attr_reader   :filename, :output, :data, :raw_data

    def initialize(filename)
      open(filename)

      @filename = filename
      @exiftool = "exiftool"
      @output   = nil
      @data     = HashWithIndifferentAccess.new
      @raw_data = HashWithIndifferentAccess.new
    end

    def run
      @output = exec_command(exiftool, filename)
      parse(@output)
    end

    def parse(data=@output)
      data.each_line do |line|
        line.chomp!
        key, value = line.scan(/^([^:]+) : (.+)$/iox).flatten # String#scan は pattern 中にキャプチャ (.*) があると配列の配列を返す
        key.strip!
        value.strip!
        @data[normalize_key(key)] = value
        @raw_data[key] = value
      end
    end

    # ExifTool が返す出力のキーを正規化する。
    # Create Date        -> create_date
    # Date/Time Original -> date_time_original
    def normalize_key(key)
      key.downcase.gsub(/[ \/]/io, '_') # 空白とスラッシュ
    end

    def method_missing(method, *args)
      begin
        super                   # Hash のメソッド呼び出し
      rescue
        @data[method]           # ExifTool の出力結果
      end
    end

    private
    # http://d.hatena.ne.jp/subuntu/20100419/1271689495
    # 外部コマンドをシェルを経由せず実行し、結果を得る。
    # ファイル名にシェルの特殊文字が含まれている場合エスケープを考慮したくないため
    # シェルを経由せずに実行する (セキュリティ的な観点から安全な方法をとる)
    # Ruby 1.9 ならば第一引数の command に配列を渡せばシェルを経由せず実行されるが、
    # いま動かしてるのは Ruby 1.8.6 なので自前で用意する必要がある。
    def exec_command(program, *args)
      IO.popen("-", "r+") do |io|
        if io                   # 親プロセス側
          io.read               # 子プロセスが実行した外部コマンドの標準出力を得る
        else
          exec(program, *args)  # 子プロセス側
        end
      end
    end
  end
end
