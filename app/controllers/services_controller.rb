class ServicesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_service, only: %i[show edit update destroy]

  def index
    @category = valid_category(params[:category])
    @services = @category ? Service.where(category: @category) : Service.all
    @services = @services.order(:name)
  end

  def show
  end

  def new
    @service = Service.new(service_type: params[:category] == "equipment" ? "equipment" : "individual")
  end

  def edit
  end

  def create
    @service = Service.new(service_params)
    if @service.save
      redirect_to services_path(category: @service.category), notice: "Item criado com sucesso."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @service.update(service_params)
      redirect_to services_path(category: @service.category), notice: "Item atualizado com sucesso.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @service.destroy!
    redirect_to services_path(category: @service.category), notice: "Item removido com sucesso.", status: :see_other
  end

  private

  def set_service
    @service = Service.find(params.expect(:id))
  end

  def service_params
    params.expect(service: %i[name price service_type])
  end

  def valid_category(value)
    value if Service::CATEGORIES.include?(value)
  end
end
