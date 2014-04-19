# -*- coding: utf-8 -*-
require 'test_helper'

class ExifToolWrapperTest < Test::Unit::TestCase
  context "アサーション" do
    setup do
      # exiftool コマンドが見つからない状態をエミュレートするために PATH をいじる
      @path_env = ENV['PATH']
      ENV['PATH'] = ""

      $".reject!{ |file| file.match(/exiftool_wrapper(?:\.rb)$/) }
    end

    should "exiftool が見つからなければ実行を停止する" do
      assert_raises(RuntimeError) do
        require 'exiftool_wrapper'
      end
    end

    teardown do
      ENV['PATH'] = @path_env
    end
  end

  context "アサーション成功" do
    setup do
      require 'exiftool_wrapper'
    end

    context "初期化" do
      should "存在するファイルのパスを渡すと new できる" do
        assert_nothing_raised() do
          ExifTool::Wrapper.new("test/fixtures/x.mp4")
        end
      end

      should "存在しないファイルのパスを渡すと例外" do
        assert_raise(Errno::ENOENT) do
          ExifTool::Wrapper.new("test/fixtures/not_exist.mp4")
        end
      end
    end

    context "実行" do
      should "外部コマンドを実行する" do
        exiftool = ExifTool::Wrapper.new("test/fixtures/x.mp4")
        exiftool.expects(:exec_command)
        exiftool.stubs(:parse)
        exiftool.run
      end

      should "外部コマンド実行結果をパースする" do
        exiftool = ExifTool::Wrapper.new("test/fixtures/x.mp4")
        data = File.open('test/fixtures/exiftool_video.txt').read
        exiftool.stubs(:exec_command).returns(data)
        exiftool.expects(:parse).with(data)
        exiftool.run
      end
    end

    context "parse メソッド" do
      should "exiftool が返す出力をパースして連想配列に保存する" do
        exiftool = ExifTool::Wrapper.new("test/fixtures/x.mp4")
        data = File.open('test/fixtures/exiftool_video.txt').read
        exiftool.stubs(:exec_command).returns(data)
        exiftool.run

        assert_kind_of Hash, exiftool.data
        assert_kind_of Hash, exiftool.raw_data
        assert exiftool.data.keys.size > 0
        assert exiftool.raw_data.keys.size > 0
      end
    end

    context "normalize_key メソッド" do
      should "exiftool が返す出力のキーを正規化する" do
        ExifTool::Wrapper.any_instance.stubs(:file_exist?).returns(true)
        exiftool = ExifTool::Wrapper.new("test/fixtures/x.mp4")
        assert "create_date", exiftool.normalize_key("Create Date")
        assert "date_time_original", exiftool.normalize_key("Date/Time Original")
      end
    end

    context "実行結果の取得" do
      should "パースした内容を返す" do
        exiftool = ExifTool::Wrapper.new("test/fixtures/x.mp4")
        data = File.open('test/fixtures/exiftool_video.txt').read
        exiftool.stubs(:exec_command).returns(data)
        exiftool.run
        assert_equal 'x.mp4', exiftool.file_name
      end
    end
  end
end
