# frozen_string_literal: true

module ::DiscoursePointsMall
  class PointsManager
    def self.enabled?
      defined?(::DiscourseGamification::GamificationScoreEvent) &&
        defined?(::DiscourseGamification::GamificationLeaderboardScore) &&
        defined?(::DiscourseGamification::LeaderboardCachedView) &&
        defined?(::DiscourseGamification::GamificationLeaderboard)
    end

    def self.balance_for(user)
      return 0 if user.blank?
      return 0 unless enabled?

      if user.respond_to?(:gamification_score)
        user.gamification_score.to_i
      else
        default_leaderboard = ::DiscourseGamification::GamificationLeaderboard.select(:id).first
        return 0 unless default_leaderboard

        ::DiscourseGamification::GamificationLeaderboardScore.where(
          leaderboard_id: default_leaderboard.id,
          user_id: user.id,
        ).sum(:score).to_i
      end
    rescue StandardError
      0
    end

    def self.add_points!(user:, points:, description:)
      return false if user.blank?
      points = points.to_i
      return false if points.zero?
      return false unless enabled?

      today = Date.today
      ::DiscourseGamification::GamificationScoreEvent.create!(
        user_id: user.id,
        date: today,
        points: points,
        description: description,
      )
      ::DiscourseGamification::GamificationLeaderboardScore.calculate_all(since_date: today)
      ::DiscourseGamification::LeaderboardCachedView.regenerate_all
      true
    rescue => e
      Rails.logger.warn("DiscoursePointsMall: 积分写入失败 - #{e.class}: #{e.message}")
      false
    end
  end
end
