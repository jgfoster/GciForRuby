
require "gemstone_ruby"
require "test/unit"

class TC_GciLibrary < Test::Unit::TestCase

  def test_character
    assert_equal("a", GemStone.executeString("$a"))
  end
  
  def test_failLogin
    assert_equal(1, GemStone.GciGetSessionId());
    assert(!GemStone.GciLogin("badUser", "swordfish"))
    assert(!GemStone.GciLogin("DataCurator", "badPassword"))
    GemStone.GciSetSessionId(1)
  end
  
  def test_false
    assert_equal(false, GemStone.executeString("false"))
  end
  
  def test_hardBreak    # this also tests non-blocking
    Thread.new do
      sleep 0.01
      GemStone.GciHardBreak
    end
    object = GemStone.executeString("(Delay forSeconds: 1) wait. true")
    assert_equal(nil, object)
    gciError = GemStone.gciError()
    assert_equal(6004, gciError[:number])
  end
  
  def test_nil
    assert_equal(nil, GemStone.executeString("nil"))
  end
  
  def test_smallDouble
    assert_equal(2.5, GemStone.executeString("2.5"))
  end
  
  def test_softBreak    # this also tests non-blocking
    Thread.new do
      sleep 0.01
      GemStone.GciSoftBreak
    end
    object = GemStone.executeString("(Delay forSeconds: 1) wait. true")
    assert_equal(nil, object)
    gciError = GemStone.gciError()
    assert_equal(6003, gciError[:number])
  end
  
  def test_smallInteger
    assert_equal(5, GemStone.executeString("2 + 3"))
  end
  
  def test_string
    assert_equal("720", GemStone.executeString("6 factorial printString"))
  end
  
  def test_true
    assert_equal(true, GemStone.executeString("true"))
  end
  
  def test_version
    assert_equal(String, GemStone.GciVersion().class)
  end
end

GemStone.login()