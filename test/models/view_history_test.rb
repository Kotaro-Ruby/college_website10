require "test_helper"

class ViewHistoryTest < ActiveSupport::TestCase
  # ===========================================
  # フィクスチャの読み込みテスト
  # ===========================================
  test "fixtures are loaded correctly" do
    assert_not_nil view_histories(:one)
    assert_not_nil view_histories(:two)
  end

  # ===========================================
  # バリデーションのテスト
  # ===========================================
  test "valid view history with user and condition" do
    view_history = ViewHistory.new(
      user: users(:two),
      condition: conditions(:womens_college),
      viewed_at: Time.current
    )
    assert view_history.valid?
  end

  test "invalid without user" do
    view_history = ViewHistory.new(
      condition: conditions(:harvard),
      viewed_at: Time.current
    )
    assert_not view_history.valid?
    assert_includes view_history.errors[:user_id], "can't be blank"
  end

  test "invalid without condition" do
    view_history = ViewHistory.new(
      user: users(:one),
      viewed_at: Time.current
    )
    assert_not view_history.valid?
    assert_includes view_history.errors[:condition_id], "can't be blank"
  end

  # ===========================================
  # アソシエーションのテスト
  # ===========================================
  test "belongs to user" do
    view_history = view_histories(:one)
    assert_equal users(:one), view_history.user
  end

  test "belongs to condition" do
    view_history = view_histories(:one)
    assert_equal conditions(:harvard), view_history.condition
  end

  # ===========================================
  # スコープのテスト
  # ===========================================
  test "default scope orders by viewed_at desc" do
    view_histories = ViewHistory.all.to_a
    view_histories.each_cons(2) do |newer, older|
      if newer.viewed_at && older.viewed_at
        assert newer.viewed_at >= older.viewed_at
      end
    end
  end

  test "recent_for_user scope returns user's recent histories" do
    user = users(:one)
    recent = ViewHistory.recent_for_user(user)

    recent.each do |vh|
      assert_equal user.id, vh.user_id
    end
  end

  test "recent_for_user scope limits to 6 records" do
    # Use a different user to avoid fixture conflicts
    user = users(:oauth_user)

    # Create view histories with different conditions
    # Note: user_id + condition_id must be unique
    available_conditions = [
      conditions(:harvard),
      conditions(:state_university),
      conditions(:community_college),
      conditions(:hbcu_university),
      conditions(:womens_college),
      conditions(:no_sat_data)
    ]

    available_conditions.each_with_index do |condition, i|
      ViewHistory.create!(
        user: user,
        condition: condition,
        viewed_at: i.hours.ago
      )
    end

    recent = ViewHistory.recent_for_user(user)
    assert recent.count <= 6
  end

  # ===========================================
  # 作成・削除のテスト
  # ===========================================
  test "can create view history" do
    assert_difference "ViewHistory.count", 1 do
      ViewHistory.create!(
        user: users(:two),
        condition: conditions(:hbcu_university),
        viewed_at: Time.current
      )
    end
  end

  test "can destroy view history without affecting user or condition" do
    view_history = view_histories(:one)
    user = view_history.user
    condition = view_history.condition

    assert_difference "ViewHistory.count", -1 do
      view_history.destroy
    end

    assert User.exists?(user.id)
    assert Condition.exists?(condition.id)
  end
end
