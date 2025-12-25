require "test_helper"

class FavoriteTest < ActiveSupport::TestCase
  # ===========================================
  # フィクスチャの読み込みテスト
  # ===========================================
  test "fixtures are loaded correctly" do
    assert_not_nil favorites(:user_one_harvard)
    assert_not_nil favorites(:user_one_osu)
    assert_not_nil favorites(:user_two_harvard)
  end

  # ===========================================
  # バリデーションのテスト
  # ===========================================
  test "valid favorite with user and condition" do
    user = users(:one)
    condition = conditions(:community_college)

    favorite = Favorite.new(user: user, condition: condition)
    assert favorite.valid?
  end

  test "invalid without user" do
    condition = conditions(:harvard)
    favorite = Favorite.new(condition: condition)

    assert_not favorite.valid?
    assert_includes favorite.errors[:user_id], "can't be blank"
  end

  test "invalid without condition" do
    user = users(:one)
    favorite = Favorite.new(user: user)

    assert_not favorite.valid?
    assert_includes favorite.errors[:condition_id], "can't be blank"
  end

  test "invalid duplicate favorite" do
    existing = favorites(:user_one_harvard)
    duplicate = Favorite.new(
      user: existing.user,
      condition: existing.condition
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "この大学は既にお気に入りに追加されています"
  end

  test "same condition can be favorited by different users" do
    harvard = conditions(:harvard)

    # user_one and user_two both favoriting harvard should be OK
    assert favorites(:user_one_harvard).valid?
    assert favorites(:user_two_harvard).valid?
  end

  test "same user can favorite different conditions" do
    # user_one favoriting both harvard and osu should be OK
    assert favorites(:user_one_harvard).valid?
    assert favorites(:user_one_osu).valid?
  end

  # ===========================================
  # アソシエーションのテスト
  # ===========================================
  test "belongs to user" do
    favorite = favorites(:user_one_harvard)
    assert_equal users(:one), favorite.user
  end

  test "belongs to condition" do
    favorite = favorites(:user_one_harvard)
    assert_equal conditions(:harvard), favorite.condition
  end

  # ===========================================
  # 作成・削除のテスト
  # ===========================================
  test "can create favorite" do
    user = users(:one)
    condition = conditions(:womens_college)

    assert_difference "Favorite.count", 1 do
      Favorite.create!(user: user, condition: condition)
    end
  end

  test "can destroy favorite" do
    favorite = favorites(:user_one_harvard)

    assert_difference "Favorite.count", -1 do
      favorite.destroy
    end
  end

  test "destroying favorite does not destroy user" do
    favorite = favorites(:user_one_harvard)
    user = favorite.user

    assert_no_difference "User.count" do
      favorite.destroy
    end

    assert User.exists?(user.id)
  end

  test "destroying favorite does not destroy condition" do
    favorite = favorites(:user_one_harvard)
    condition = favorite.condition

    assert_no_difference "Condition.count" do
      favorite.destroy
    end

    assert Condition.exists?(condition.id)
  end

  # ===========================================
  # スコープ/クエリのテスト
  # ===========================================
  test "can find favorites by user" do
    user = users(:one)
    user_favorites = Favorite.where(user: user)

    assert_equal 2, user_favorites.count
  end

  test "can find favorites by condition" do
    harvard = conditions(:harvard)
    harvard_favorites = Favorite.where(condition: harvard)

    assert_equal 2, harvard_favorites.count
  end

  # ===========================================
  # ユニーク制約のテスト
  # ===========================================
  test "uniqueness constraint on user_id and condition_id" do
    existing = favorites(:user_one_harvard)

    assert_raises ActiveRecord::RecordInvalid do
      Favorite.create!(
        user_id: existing.user_id,
        condition_id: existing.condition_id
      )
    end
  end
end
