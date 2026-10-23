# db/seeds.rb
# Cria o usuário admin padrão se ainda não existir

admin_email = "admin@hotelevents.com"

if User.find_by(email: admin_email).nil?
  User.create!(
    name:                  "Administrador",
    email:                 admin_email,
    password:              "Admin@123",
    password_confirmation: "Admin@123",
    role:                  :admin
  )
  puts "✅ Admin criado: #{admin_email} | Senha: Admin@123"
else
  puts "ℹ️  Admin já existe: #{admin_email}"
end
