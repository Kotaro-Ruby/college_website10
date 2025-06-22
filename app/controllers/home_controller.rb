class HomeController < ApplicationController
  # 特定のアクションでカスタムレイアウトを使用
  layout 'country_layout', only: [:canada, :australia, :newzealand]
  
  def top
  end
  
  def about
  end
  
  def knowledge
  end
  
  def degreeseeking
  end
  
  def info
  end
  
  def recruit
  end
  
  def contact
  end
  
  def canada
  end
  
  def australia
  end
  
  def newzealand
  end
  
  def terms
  end
end