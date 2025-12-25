require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  # ===========================================
  # 州名翻訳のテスト
  # ===========================================
  test "translate_state returns japanese for known state codes" do
    assert_equal "カリフォルニア州", translate_state("CA")
    assert_equal "ニューヨーク州", translate_state("NY")
    assert_equal "テキサス州", translate_state("TX")
    assert_equal "フロリダ州", translate_state("FL")
    assert_equal "ワシントンD.C.", translate_state("DC")
  end

  test "translate_state returns fallback for unknown state codes" do
    assert_equal "XX州", translate_state("XX")
    assert_equal "ZZ州", translate_state("ZZ")
  end

  test "translate_state handles all 50 states plus territories" do
    # Sample of states to verify
    states = {
      "AL" => "アラバマ州",
      "AK" => "アラスカ州",
      "HI" => "ハワイ州",
      "MA" => "マサチューセッツ州",
      "PR" => "プエルトリコ",
      "GU" => "グアム"
    }

    states.each do |code, expected|
      assert_equal expected, translate_state(code), "Failed for #{code}"
    end
  end
end
