namespace :admin do
  desc "Create initial admin account"
  task create_initial: :environment do
    if Admin.exists_admin?
      puts "管理者アカウントは既に存在します"
      exit
    end
    
    puts "初期管理者アカウントを作成します"
    print "ユーザー名: "
    username = STDIN.gets.chomp
    
    print "メールアドレス: "
    email = STDIN.gets.chomp
    
    print "パスワード: "
    password = STDIN.noecho(&:gets).chomp
    puts
    
    print "パスワード（確認）: "
    password_confirmation = STDIN.noecho(&:gets).chomp
    puts
    
    if password != password_confirmation
      puts "パスワードが一致しません"
      exit
    end
    
    admin = Admin.create_initial_admin(username, email, password)
    
    if admin
      puts "初期管理者アカウントが作成されました"
      puts "ユーザー名: #{admin.username}"
      puts "メールアドレス: #{admin.email}"
      puts "権限: #{admin.role}"
    else
      puts "管理者アカウントの作成に失敗しました"
      admin = Admin.new(username: username, email: email, password: password)
      puts admin.errors.full_messages.join("\n")
    end
  end
end