class StatesController < ApplicationController
  before_action :set_state_data, only: [ :show ]

  def index
    @states = StateDataService.major_states_with_counts
  end

  def show
    # 4年制・非営利のみ対象
    base_scope = Condition.where(state: @state_code)
                          .where(privateorpublic: [ "私立", "州立" ])
                          .where("carnegie_basic >= 15")

    @colleges = base_scope.limit(20)
    @total_colleges = base_scope.count
    @top_colleges = base_scope
                      .where.not(students: nil)
                      .where("students > 0")
                      .order(students: :desc)
                      .limit(6)
  end

  private

  def set_state_data
    @state_code = params[:state_code].upcase
    @state_data = StateDataService.get_state(@state_code)

    if @state_data.nil?
      redirect_to states_path, alert: "指定された州が見つかりません。"
    end
  end
end
