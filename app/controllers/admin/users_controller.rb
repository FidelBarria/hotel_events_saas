module Admin
  class UsersController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin

    def index
      @users = User.order(:name, :email)
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      if @user.save
        redirect_to admin_users_path, notice: "Usuário criado com sucesso."
      else
        @users = User.order(:name, :email)
        render :index, status: :unprocessable_content
      end
    end

    private

    def require_admin
      return if current_user.admin?

      redirect_to root_path, alert: "Apenas administradores podem acessar as configurações de usuários."
    end

    def user_params
      permitted = params.require(:user).permit(:name, :email, :password, :password_confirmation, :role)
      permitted[:role] = "client" unless User.roles.key?(permitted[:role])
      permitted
    end
  end
end
