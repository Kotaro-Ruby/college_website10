namespace :fix do
  desc "Fix state names to proper Japanese format"
  task state_names: :environment do
    state_mappings = {
      'CA州(CA)' => 'カリフォルニア州',
      'NY州(NY)' => 'ニューヨーク州', 
      'TX州(TX)' => 'テキサス州',
      'FL州(FL)' => 'フロリダ州',
      'IL州(IL)' => 'イリノイ州',
      'PA州(PA)' => 'ペンシルベニア州',
      'OH州(OH)' => 'オハイオ州',
      'GA州(GA)' => 'ジョージア州',
      'NC州(NC)' => 'ノースカロライナ州',
      'MI州(MI)' => 'ミシガン州'
    }
    
    updated_count = 0
    
    state_mappings.each do |old_name, new_name|
      conditions = Condition.where(state: old_name)
      count = conditions.update_all(state: new_name)
      if count > 0
        puts "#{old_name} → #{new_name}: #{count}校"
        updated_count += count
      end
    end
    
    puts "\n合計更新数: #{updated_count}校"
  end
end