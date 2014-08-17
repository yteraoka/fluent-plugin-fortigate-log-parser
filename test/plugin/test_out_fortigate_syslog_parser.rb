# coding: utf-8
require 'helper'

class FortigateSyslogParserOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
  ]

  CONFIG_REWRITE_TAG = %[
    remove_prefix before
    add_prefix after
  ]

  CONFIG_MESSAGE_KEY = %[
    message_key mykey
  ]

  CONFIG_COUNTRY_MAP = %[
    country_map_file test/test_country.map
  ]

  CONFIG_OS_VERSION4 = %[
    country_map_file test/test_country.map
    fortios_version 4
  ]

  CONFIG_KEYS = %[
    keys a,b,c
  ]

  CONFIG_REMOVE_KEYS = %[
    remove_keys a,b,c
  ]

  def create_driver(conf=CONFIG,tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::FortigateSyslogParseOutput, tag).configure(conf)
  end

  def test_configure
    assert_raise(Fluent::ConfigError) {
      d = create_driver %[
        keys a,b,c
        remove_keys x,y,z
      ]
    }
    assert_raise(Fluent::ConfigError) {
      d = create_driver('country_map_file not_exist')
    }
    assert_raise(Fluent::ConfigError) {
      d = create_driver('message_key')
    }
  end

  def test_emit
    d1 = create_driver(CONFIG)
    d1.run do
      d1.emit({'message' => 'Aug 17 00:00:00 fortigate date=2014-08-16,time=23: 59:59,devname=TEST_NAME,devid=TEST_ID,logid=0000000001'})
    end
    emits = d1.emits
    assert_equal 1, emits.length
    assert_equal '0000000001', emits[0][2]['logid']
  end

  def test_emit_rewrite_tag
    d1 = create_driver(CONFIG)
    d1.run do
      d1.emit({'message' => 'Aug 17 00:00:00 fortigate date=2014-08-16,time=23: 59:59,file=あああ,filename=いいい'})
    end
    emits = d1.emits
    assert_equal 1, emits.length
    assert_equal '%E3%81%82%E3%81%82%E3%81%82', emits[0][2]['file']
    assert_equal '%E3%81%84%E3%81%84%E3%81%84', emits[0][2]['filename']
  end

  def test_emit_rewrite_tag
    d1 = create_driver(CONFIG_REWRITE_TAG, 'before.test')
    d1.run do
      d1.emit({'message' => 'Aug 17 00:00:00 fortigate date=2014-08-16,time=23: 59:59'})
    end
    emits = d1.emits
    assert_equal 1, emits.length
    assert_equal 'after.test', emits[0][0]
  end

  def test_emit_message_key
    d1 = create_driver(CONFIG_MESSAGE_KEY)
    d1.run do
      d1.emit({'mykey' => 'Aug 17 00:00:00 fortigate date=2014-08-16,time=23: 59:59,key1=value1,key2=value2'})
    end
    emits = d1.emits
    assert_equal 1, emits.length
    assert_equal 'value1', emits[0][2]['key1']
    assert_equal 'value2', emits[0][2]['key2']
  end

  def test_emit_date_parse
    d1 = create_driver()
    d1.run do
      d1.emit({'message' => 'Aug 17 00:00:00 fortigate date=2014-08-16,time=23: 59:59'})
    end
    emits = d1.emits
    assert_equal 1, emits.length
    assert_equal 1408201199, emits[0][1]
  end

  def test_emit_country_map
    d1 = create_driver(CONFIG_COUNTRY_MAP)
    d1.run do
      d1.emit({'message' => 'Aug 17 00:00:00 fortigate date=2014-08-16,time=23: 59:59,srccountry=Japan,dstcountry=United States'})
    end
    emits = d1.emits
    assert_equal 1, emits.length
    assert_equal 'Japan', emits[0][2]['srccountry']
    assert_equal 'United States', emits[0][2]['dstcountry']
    assert_equal 'JP', emits[0][2]['srccountry_code']
    assert_equal 'US', emits[0][2]['dstcountry_code']
  end

  def test_emit_os_version4
    d1 = create_driver(CONFIG_OS_VERSION4)
    d1.run do
      d1.emit({'message' => 'Aug 17 00:00:00 fortigate date=2014-08-16,time=23: 59:59,src_country=Japan,dst_country=United States'})
    end
    emits = d1.emits
    assert_equal 1, emits.length
    assert_equal 'Japan', emits[0][2]['src_country']
    assert_equal 'United States', emits[0][2]['dst_country']
    assert_equal 'JP', emits[0][2]['src_country_code']
    assert_equal 'US', emits[0][2]['dst_country_code']
  end

  def test_emit_keys
    d1 = create_driver(CONFIG_KEYS)
    d1.run do
      d1.emit({'message' => 'Aug 17 00:00:00 fortigate date=2014-08-16,time=23: 59:59,a=A,b=B,c=C,x=X,y=Y,z=Z'})
    end
    expected = {'a' => 'A', 'b' => 'B', 'c' => 'C'}
    emits = d1.emits
    assert_equal 1, emits.length
    assert_equal expected, emits[0][2]
  end

  def test_emit_remove_keys
    d1 = create_driver(CONFIG_REMOVE_KEYS)
    d1.run do
      d1.emit({'message' => 'Aug 17 00:00:00 fortigate date=2014-08-16,time=23: 59:59,a=A,b=B,c=C,x=X,y=Y,z=Z'})
    end
    expected = {'x' => 'X', 'y' => 'Y', 'z' => 'Z'}
    emits = d1.emits
    assert_equal 1, emits.length
    assert_equal expected, emits[0][2]
  end
end
